# Example: Complete ReportMate Production Deployment

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "reportmate" {
  source = "../../"

  project_name = "reportmate"
  environment  = "prod"

  # Networking
  vpc_cidr = "10.0.0.0/16"
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  # Database
  db_password       = var.db_password
  db_instance_class = "db.t3.large"
  db_storage_size   = 50
  db_max_storage    = 200

  # Containers (Next.js Dashboard)
  container_config = {
    cpu           = 1024
    memory        = 2048
    desired_count = 3
    min_capacity  = 2
    max_capacity  = 20
    port          = 3000
    image         = var.container_image
  }

  # Authentication
  enable_auth   = true
  callback_urls = ["https://${var.domain_name}/api/auth/callback/cognito"]
  logout_urls   = ["https://${var.domain_name}"]

  # Custom Domain
  enable_custom_domain = true
  domain_name         = var.domain_name
  acm_certificate_arn = var.acm_certificate_arn

  # ECR
  enable_ecr = true

  # Monitoring
  enable_monitoring = true
  log_retention_days = 90

  # Tags
  tags = {
    Project     = "ReportMate"
    Environment = "prod"
    ManagedBy   = "Terraform"
    CostCenter  = "IT"
  }

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

# Variables
variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Custom domain name"
  default     = "reportmate.example.com"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in us-east-1"
}

variable "container_image" {
  type        = string
  description = "Container image URI"
  default     = ""
}

# Outputs
output "frontend_url" {
  description = "Application URL"
  value       = module.reportmate.frontend_url
}

output "api_endpoint" {
  description = "API endpoint"
  value       = module.reportmate.api_endpoint
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.reportmate.database_endpoint
  sensitive   = true
}

output "cognito_config" {
  description = "Cognito configuration for Next.js"
  value = {
    user_pool_id = module.reportmate.cognito_user_pool_id
    client_id    = module.reportmate.cognito_client_id
    issuer_url   = module.reportmate.cognito_issuer_url
  }
}

output "ecr_repository_url" {
  description = "ECR repository URL for container images"
  value       = module.reportmate.ecr_repository_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.reportmate.cloudfront_distribution_id
}
