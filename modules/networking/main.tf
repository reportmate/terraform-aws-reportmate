locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Two modes:
  #   * create_vpc = true  (default): the module owns a whole VPC, IGW, NAT and
  #     route tables, exactly as before.
  #   * create_vpc = false: existing_vpc_id names a VPC someone else owns. The
  #     module adds its own subnets and route tables to it and never modifies
  #     anything that was already there.
  create_vpc = var.existing_vpc_id == null

  azs       = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  nat_count = local.create_vpc ? (var.enable_multi_az_nat ? length(local.azs) : 1) : 0

  vpc_id         = local.create_vpc ? aws_vpc.main[0].id : data.aws_vpc.existing[0].id
  vpc_cidr_block = local.create_vpc ? aws_vpc.main[0].cidr_block : data.aws_vpc.existing[0].cidr_block

  public_subnet_ids  = local.create_vpc ? aws_subnet.public[*].id : [for az in sort(keys(var.public_subnet_cidrs)) : aws_subnet.shared_public[az].id]
  private_subnet_ids = local.create_vpc ? aws_subnet.private[*].id : [for az in sort(keys(var.private_subnet_cidrs)) : aws_subnet.shared_private[az].id]

  private_route_table_ids = local.create_vpc ? aws_route_table.private[*].id : aws_route_table.shared_private[*].id
  nat_gateway_ids         = local.create_vpc ? aws_nat_gateway.main[*].id : [var.existing_nat_gateway_id]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---

resource "aws_vpc" "main" {
  count = local.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${local.name_prefix}-vpc" }
}

moved {
  from = aws_vpc.main
  to   = aws_vpc.main[0]
}

# --- Public Subnets (ALB, NAT Gateway) ---

resource "aws_subnet" "public" {
  count                   = local.create_vpc ? length(local.azs) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-public-${local.azs[count.index]}" }
}

# --- Private Subnets (ECS tasks, RDS) ---

resource "aws_subnet" "private" {
  count             = local.create_vpc ? length(local.azs) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = local.azs[count.index]

  tags = { Name = "${local.name_prefix}-private-${local.azs[count.index]}" }
}

# --- Internet Gateway ---

resource "aws_internet_gateway" "main" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = { Name = "${local.name_prefix}-igw" }
}

moved {
  from = aws_internet_gateway.main
  to   = aws_internet_gateway.main[0]
}

# --- NAT Gateway(s) ---
#
# Single NAT by default (cheap, AZ-fragile). Set enable_multi_az_nat = true
# to provision one per AZ so an AZ outage does not take down egress for the
# whole VPC. None are created in an existing VPC.
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = { Name = "${local.name_prefix}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${local.name_prefix}-nat-${count.index}" }

  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables ---

resource "aws_route_table" "public" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

moved {
  from = aws_route_table.public
  to   = aws_route_table.public[0]
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# One private route table per AZ when multi-AZ NAT is on so each subnet
# routes through its local NAT and avoids cross-AZ NAT data transfer charges.
resource "aws_route_table" "private" {
  count  = local.create_vpc ? length(local.azs) : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_multi_az_nat ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
  }

  tags = { Name = "${local.name_prefix}-private-rt-${local.azs[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
