# Existing-VPC mode.
#
# When existing_vpc_id is set the module deploys into a VPC it does not own,
# typically one a separate Terraform root runs for several applications. The
# module creates no VPC, internet gateway or NAT gateway there. For each tier
# it either uses subnets the VPC owner already made (existing_*_subnet_ids) or
# creates its own from the CIDRs reserved for it (*_subnet_cidrs), with one
# route table per created tier that only those subnets are associated with.
# Existing subnets, route tables and gateways are read, never changed.

data "aws_vpc" "existing" {
  count = local.create_vpc ? 0 : 1
  id    = var.existing_vpc_id

  lifecycle {
    precondition {
      condition     = (length(var.existing_private_subnet_ids) >= 2) != (length(var.private_subnet_cidrs) >= 2)
      error_message = "existing_vpc_id needs private subnets from exactly one of existing_private_subnet_ids (at least two) or private_subnet_cidrs (at least two AZs)."
    }

    precondition {
      condition     = (length(var.existing_public_subnet_ids) >= 2) != (length(var.public_subnet_cidrs) >= 2)
      error_message = "existing_vpc_id needs public subnets from exactly one of existing_public_subnet_ids (at least two) or public_subnet_cidrs (at least two AZs)."
    }

    precondition {
      condition     = length(var.existing_private_subnet_ids) > 0 || (var.existing_nat_gateway_id != null && var.existing_nat_gateway_id != "")
      error_message = "Creating private subnets in an existing VPC requires existing_nat_gateway_id for their egress route."
    }
  }
}

data "aws_internet_gateway" "existing" {
  count = length(local.shared_public_cidrs) > 0 ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

resource "aws_subnet" "shared_public" {
  for_each = local.shared_public_cidrs

  vpc_id                  = data.aws_vpc.existing[0].id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-public-${each.key}" }
}

resource "aws_subnet" "shared_private" {
  for_each = local.shared_private_cidrs

  vpc_id            = data.aws_vpc.existing[0].id
  cidr_block        = each.value
  availability_zone = each.key

  tags = { Name = "${local.name_prefix}-private-${each.key}" }
}

resource "aws_route_table" "shared_public" {
  count  = length(local.shared_public_cidrs) > 0 ? 1 : 0
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
  count  = length(local.shared_private_cidrs) > 0 ? 1 : 0
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
