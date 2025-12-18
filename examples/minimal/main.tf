# Example: Minimal ReportMate Deployment
# This example deploys the minimum required infrastructure for testing

provider "aws" {
  region = "us-east-1"
}

module "reportmate_minimal" {
  source = "../../"

  project_name = "reportmate"
  environment  = "dev"

  # Networking - Single AZ for cost savings
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a"]
  single_nat_gateway = true

  # Database - Small instance
  db_password       = var.db_password
  db_instance_class = "db.t3.micro"
  db_storage_size   = 20

  # Containers - Minimal
  container_config = {
    cpu           = 256
    memory        = 512
    desired_count = 1
    min_capacity  = 1
    max_capacity  = 2
    port          = 3000
    image         = ""
  }

  # Disable optional features
  enable_auth          = false
  enable_custom_domain = false
  enable_ecr           = false

  tags = {
    Project     = "ReportMate"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

output "frontend_url" {
  value = module.reportmate_minimal.frontend_url
}

output "api_endpoint" {
  value = module.reportmate_minimal.api_endpoint
}
