locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# SQS queue for osquery data ingestion (mirrors Azure Storage Queue)
resource "aws_sqs_queue" "ingest" {
  name                       = "${local.name_prefix}-osquery-ingest"
  message_retention_seconds  = 345600 # 4 days
  visibility_timeout_seconds = 300    # 5 minutes
  receive_wait_time_seconds  = 20     # Long polling

  tags = { Name = "${local.name_prefix}-osquery-ingest" }
}

# Dead-letter queue for failed messages
resource "aws_sqs_queue" "ingest_dlq" {
  name                      = "${local.name_prefix}-osquery-ingest-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = { Name = "${local.name_prefix}-osquery-ingest-dlq" }
}

resource "aws_sqs_queue_redrive_policy" "ingest" {
  queue_url = aws_sqs_queue.ingest.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ingest_dlq.arn
    maxReceiveCount     = 3
  })
}

# S3 bucket for general storage (reports, exports, backups)
resource "aws_s3_bucket" "main" {
  bucket = "${local.name_prefix}-storage"

  tags = { Name = "${local.name_prefix}-storage" }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
