# Bootstrap module: creates S3 bucket + DynamoDB table for Terraform state locking.
# Run this ONCE before initializing the main module.
#
#   cd bootstrap && terraform init && terraform apply
#   cd .. && terraform init -backend-config=backend.hcl

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "reportmate"
      ManagedBy = "terraform"
    }
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "reportmate"
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "state" {
  bucket = "${var.project_name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "lock" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Outputs for backend.hcl
output "state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.lock.name
}

output "region" {
  description = "AWS region"
  value       = var.region
}
