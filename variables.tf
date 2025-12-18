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

# =================================================================
# DATABASE CONFIGURATION
# =================================================================

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

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

variable "db_storage_gb" {
  type        = number
  description = "PostgreSQL storage size in GB"
  default     = 20
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
# CONTAINER CONFIGURATION
# =================================================================

variable "frontend_image" {
  type        = string
  description = "Docker image for the frontend container"
  default     = "ghcr.io/reportmate/reportmate-app-web"
}

variable "frontend_image_tag" {
  type        = string
  description = "Tag for the frontend container image"
  default     = "latest"
}

variable "container_cpu" {
  type        = number
  description = "CPU units for the container (1024 = 1 vCPU)"
  default     = 512
}

variable "container_memory" {
  type        = number
  description = "Memory for the container in MB"
  default     = 1024
}

variable "desired_count" {
  type        = number
  description = "Desired number of container instances"
  default     = 2
}

variable "create_ecr_repository" {
  type        = bool
  description = "Create an ECR repository for container images"
  default     = false
}

variable "existing_ecr_repository_url" {
  type        = string
  description = "URL of existing ECR repository (if not creating new)"
  default     = ""
}

variable "ecr_image_retention_count" {
  type        = number
  description = "Number of images to retain in ECR"
  default     = 10
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

# =================================================================
# AUTHENTICATION CONFIGURATION
# =================================================================

variable "enable_cognito" {
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

variable "client_passphrases" {
  type        = string
  description = "Comma-separated list of client passphrases for device authentication"
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
    Project   = "ReportMate"
    ManagedBy = "Terraform"
  }
}
