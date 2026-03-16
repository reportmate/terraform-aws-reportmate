terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
