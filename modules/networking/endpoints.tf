# VPC endpoints.
#
# The S3 gateway endpoint is created by default — it is free and short-
# circuits S3 traffic from private subnets so it never touches the NAT gateway
# (ECR backing-store layers come from S3 in some regions).
#
# Interface endpoints (ECR, CloudWatch Logs, Secrets Manager) are opt-in via
# enable_vpc_endpoints. Each endpoint costs ~$0.01/hr per AZ (~$7.20/mo per
# AZ per endpoint), so only enable once steady-state NAT egress justifies it.
#
# In an existing VPC that already has interface endpoints with private DNS for
# these services, leave enable_vpc_endpoints off: a second private-DNS endpoint
# for the same service in one VPC is rejected by AWS.

data "aws_region" "current" {}

# --- S3 gateway endpoint (on unless enable_s3_gateway_endpoint = false) ---

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_gateway_endpoint ? 1 : 0
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.private_route_table_ids

  tags = { Name = "${local.name_prefix}-s3-endpoint" }
}

moved {
  from = aws_vpc_endpoint.s3
  to   = aws_vpc_endpoint.s3[0]
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
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
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
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = { Name = "${local.name_prefix}-${replace(each.value, ".", "-")}-endpoint" }
}
