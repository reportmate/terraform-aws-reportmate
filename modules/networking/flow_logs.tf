# VPC Flow Logs to S3.
#
# Cheap visibility into per-IP/port egress. Without this, cost incidents
# driven by network egress (NAT BytesOut spikes, runaway services posting
# to public hostnames) are very hard to attribute.

data "aws_caller_identity" "current" {
  count = var.enable_vpc_flow_logs ? 1 : 0
}

resource "aws_s3_bucket" "flow_logs" {
  count         = var.enable_vpc_flow_logs ? 1 : 0
  bucket        = "${local.name_prefix}-vpc-flow-logs-${data.aws_caller_identity.current[0].account_id}"
  force_destroy = true

  tags = { Name = "${local.name_prefix}-vpc-flow-logs" }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count                   = var.enable_vpc_flow_logs ? 1 : 0
  bucket                  = aws_s3_bucket.flow_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "expire-30d"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# A VPC the module creates gets one VPC-wide flow log. In an existing VPC the
# module logs only its own subnets, so it never captures (or pays for) other
# tenants' traffic in the shared VPC.
resource "aws_flow_log" "vpc" {
  count                = var.enable_vpc_flow_logs && local.create_vpc ? 1 : 0
  vpc_id               = aws_vpc.main[0].id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs[0].arn

  tags = { Name = "${local.name_prefix}-vpc-flow-log" }
}

resource "aws_flow_log" "subnet" {
  for_each = var.enable_vpc_flow_logs && !local.create_vpc ? merge(
    { for az, subnet in aws_subnet.shared_private : "private-${az}" => subnet.id },
    { for az, subnet in aws_subnet.shared_public : "public-${az}" => subnet.id },
  ) : {}

  subnet_id            = each.value
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs[0].arn

  tags = { Name = "${local.name_prefix}-${each.key}-flow-log" }
}
