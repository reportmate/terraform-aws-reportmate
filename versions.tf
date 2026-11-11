terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.71 is the first release whose aws_ecs_express_gateway_service
      # takes cpu_architecture (ingress_mode = "express").
      version = ">= 6.71, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    # Configure via backend config file or CLI:
    #   terraform init -backend-config=backend.hcl
    # Required keys: bucket, key, region, dynamodb_table
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "reportmate"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
