# VPC endpoints.
#
# The S3 gateway endpoint is created unconditionally — it is free and short-
# circuits S3 traffic from private subnets so it never touches the NAT gateway
# (ECR backing-store layers come from S3 in some regions).
#
# Interface endpoints (ECR, CloudWatch Logs, Secrets Manager) are opt-in via
# enable_vpc_endpoints. Each endpoint costs ~$0.01/hr per AZ (~$7.20/mo per
# AZ per endpoint), so only enable once steady-state NAT egress justifies it.

data "aws_region" "current" {}

# --- S3 gateway endpoint (always on) ---

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = { Name = "${local.name_prefix}-s3-endpoint" }
}

# --- Interface endpoints (opt-in) ---

locals {
  interface_endpoints = var.enable_vpc_endpoints ? toset([
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
  ]) : toset([])
}

resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name_prefix = "${local.name_prefix}-vpce-"
  description = "Allow inbound HTTPS from in-VPC clients to interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-vpce-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = { Name = "${local.name_prefix}-${replace(each.value, ".", "-")}-endpoint" }
}
