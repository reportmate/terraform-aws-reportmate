# Existing-VPC mode.
#
# When existing_vpc_id is set the module deploys into a VPC it does not own.
# Everything here is additive: new subnets from the CIDRs the operator
# reserved, plus one private and one public route table that only those new
# subnets are associated with. Existing subnets, route tables, gateways and
# the VPC itself are read, never changed.

data "aws_vpc" "existing" {
  count = local.create_vpc ? 0 : 1
  id    = var.existing_vpc_id

  lifecycle {
    precondition {
      condition     = length(var.private_subnet_cidrs) >= 2 && length(var.public_subnet_cidrs) >= 2
      error_message = "existing_vpc_id requires private_subnet_cidrs and public_subnet_cidrs, each mapping at least two availability zones to a CIDR."
    }

    precondition {
      condition     = toset(keys(var.private_subnet_cidrs)) == toset(keys(var.public_subnet_cidrs))
      error_message = "private_subnet_cidrs and public_subnet_cidrs must cover the same availability zones."
    }

    precondition {
      condition     = var.existing_nat_gateway_id != null && var.existing_nat_gateway_id != ""
      error_message = "existing_vpc_id requires existing_nat_gateway_id for private-subnet egress."
    }
  }
}

data "aws_internet_gateway" "existing" {
  count = local.create_vpc ? 0 : 1

  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

resource "aws_subnet" "shared_public" {
  for_each = local.create_vpc ? {} : var.public_subnet_cidrs

  vpc_id                  = data.aws_vpc.existing[0].id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-public-${each.key}" }
}

resource "aws_subnet" "shared_private" {
  for_each = local.create_vpc ? {} : var.private_subnet_cidrs

  vpc_id            = data.aws_vpc.existing[0].id
  cidr_block        = each.value
  availability_zone = each.key

  tags = { Name = "${local.name_prefix}-private-${each.key}" }
}

resource "aws_route_table" "shared_public" {
  count  = local.create_vpc ? 0 : 1
  vpc_id = data.aws_vpc.existing[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing[0].id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "shared_public" {
  for_each       = aws_subnet.shared_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.shared_public[0].id
}

resource "aws_route_table" "shared_private" {
  count  = local.create_vpc ? 0 : 1
  vpc_id = data.aws_vpc.existing[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.existing_nat_gateway_id
  }

  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "shared_private" {
  for_each       = aws_subnet.shared_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.shared_private[0].id
}
