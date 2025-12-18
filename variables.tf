# =================================================================
# ReportMate AWS Infrastructure Variables (Serverless Edition)
# =================================================================

# =================================================================
# REQUIRED VARIABLES
# =================================================================

variable "project_name" {
  type        = string
  description = "Name of the project (used for resource naming)"
  default     = "reportmate"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "db_password" {
  type        = string
  description = "PostgreSQL administrator password"
  sensitive   = true
}

# =================================================================
# NETWORKING CONFIGURATION
# =================================================================

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to use"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT Gateway for all AZs (cost optimization for non-prod)"
  default     = true
}

# =================================================================
# DATABASE CONFIGURATION (Aurora Serverless v2)
# =================================================================

variable "db_name" {
  type        = string
  description = "Name of the PostgreSQL database"
  default     = "reportmate"
}

variable "db_username" {
  type        = string
  description = "PostgreSQL administrator username"
  default     = "reportmate"
}

variable "db_min_capacity" {
  type        = number
  description = "Minimum Aurora Serverless v2 capacity (in ACUs, 0.5-128)"
  default     = 0.5
}

variable "db_max_capacity" {
  type        = number
  description = "Maximum Aurora Serverless v2 capacity (in ACUs, 0.5-128)"
  default     = 16
}

variable "db_instance_count" {
  type        = number
  description = "Number of Aurora instances (1 for dev, 2+ for HA in prod)"
  default     = 1
}

variable "enable_db_data_api" {
  type        = bool
  description = "Enable Aurora Data API for Lambda access without VPC"
  default     = true
}

variable "enable_db_iam_auth" {
  type        = bool
  description = "Enable IAM database authentication for Lambdas"
  default     = true
}

variable "enable_rds_proxy" {
  type        = bool
  description = "Enable RDS Proxy for Lambda connection pooling (recommended for prod)"
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on Aurora cluster"
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when deleting cluster (false for prod)"
  default     = false
}

# =================================================================
# STORAGE CONFIGURATION
# =================================================================

variable "enable_s3_versioning" {
  type        = bool
  description = "Enable versioning on S3 buckets"
  default     = true
}

# =================================================================
# LAMBDA NEXT.JS CONFIGURATION
# =================================================================

variable "nextjs_lambda_bucket" {
  type        = string
  description = "S3 bucket containing the Next.js Lambda deployment package"
  default     = ""
}

variable "nextjs_lambda_key" {
  type        = string
  description = "S3 key for the Next.js Lambda deployment package"
  default     = "deployments/nextjs/server.zip"
}

variable "nextjs_lambda_hash" {
  type        = string
  description = "SHA256 hash of the Lambda package for change detection"
  default     = ""
}

variable "nextjs_lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds (max 900 for API Gateway, 60 recommended)"
  default     = 30
}

variable "nextjs_lambda_memory" {
  type        = number
  description = "Lambda memory in MB (128-10240, higher = more CPU)"
  default     = 1024
}

variable "nextjs_enable_vpc" {
  type        = bool
  description = "Enable VPC access for Next.js Lambda (required for direct DB access, not needed with Data API)"
  default     = false
}

variable "nextjs_extra_env_vars" {
  type        = map(string)
  description = "Additional environment variables for the Next.js Lambda"
  default     = {}
}

variable "enable_image_optimization" {
  type        = bool
  description = "Enable Lambda-based image optimization"
  default     = true
}

# =================================================================
# MONITORING CONFIGURATION
# =================================================================

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention period in days"
  default     = 30
}

variable "enable_cloudwatch_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms for monitoring"
  default     = true
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
  default     = ""
}

variable "enable_xray" {
  type        = bool
  description = "Enable AWS X-Ray tracing for Lambdas"
  default     = true
}

# =================================================================
# AUTHENTICATION CONFIGURATION
# =================================================================

variable "enable_auth" {
  type        = bool
  description = "Enable AWS Cognito for authentication"
  default     = true
}

variable "allowed_auth_domains" {
  type        = list(string)
  description = "List of allowed email domains for authentication"
  default     = []
}

variable "nextauth_secret" {
  type        = string
  description = "NextAuth session encryption secret"
  sensitive   = true
  default     = ""
}

variable "client_passphrase" {
  type        = string
  description = "Client passphrase for device authentication"
  default     = ""
  sensitive   = true
}

# =================================================================
# CUSTOM DOMAIN CONFIGURATION
# =================================================================

variable "enable_custom_domain" {
  type        = bool
  description = "Enable custom domain configuration"
  default     = false
}

variable "custom_domain_name" {
  type        = string
  description = "Custom domain name (e.g., reportmate.example.com)"
  default     = ""
}

variable "app_base_url" {
  type        = string
  description = "Base URL for the application (used for auth callbacks before CloudFront is created)"
  default     = "https://localhost:3000"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of ACM certificate for custom domain (must be in us-east-1 for CloudFront)"
  default     = ""
}

variable "route53_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for DNS records"
  default     = ""
}

# =================================================================
# TAGS
# =================================================================

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to resources"
  default = {
    Project      = "ReportMate"
    ManagedBy    = "Terraform"
    Architecture = "Serverless"
  }
}
