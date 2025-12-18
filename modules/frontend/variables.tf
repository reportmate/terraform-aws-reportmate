variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Lambda Package
variable "lambda_package_path" {
  description = "Local path to Lambda deployment package"
  type        = string
  default     = ""
}

variable "lambda_s3_bucket" {
  description = "S3 bucket containing Lambda package"
  type        = string
  default     = ""
}

variable "lambda_s3_key" {
  description = "S3 key for Lambda package"
  type        = string
  default     = ""
}

variable "lambda_source_hash" {
  description = "Source code hash for Lambda updates"
  type        = string
  default     = ""
}

# Lambda Configuration
variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 1024
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency (0 to disable)"
  type        = number
  default     = 0
}

# Invocation method
variable "use_function_url" {
  description = "Use Lambda Function URLs (simpler, cheaper)"
  type        = bool
  default     = true
}

variable "use_api_gateway" {
  description = "Use API Gateway HTTP API"
  type        = bool
  default     = false
}

variable "api_throttle_burst" {
  description = "API Gateway burst throttle limit"
  type        = number
  default     = 5000
}

variable "api_throttle_rate" {
  description = "API Gateway rate throttle limit"
  type        = number
  default     = 10000
}

# VPC Configuration
variable "enable_vpc" {
  description = "Enable VPC access for database connectivity"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  type        = list(string)
  default     = []
}

# Application Configuration
variable "app_url" {
  description = "Application URL (NEXTAUTH_URL)"
  type        = string
}

variable "api_base_url" {
  description = "API base URL"
  type        = string
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret"
  type        = string
  sensitive   = true
}

variable "api_passphrase" {
  description = "ReportMate API passphrase"
  type        = string
  default     = ""
  sensitive   = true
}

variable "environment_variables" {
  description = "Additional environment variables"
  type        = map(string)
  default     = {}
}

# Image Optimization
variable "enable_image_optimization" {
  description = "Enable Next.js image optimization Lambda"
  type        = bool
  default     = true
}

variable "image_optimizer_package_path" {
  description = "Path to image optimizer Lambda package"
  type        = string
  default     = ""
}

variable "image_optimizer_s3_key" {
  description = "S3 key for image optimizer package"
  type        = string
  default     = ""
}

variable "image_optimizer_source_hash" {
  description = "Source hash for image optimizer"
  type        = string
  default     = ""
}

variable "assets_bucket_name" {
  description = "S3 bucket name for static assets"
  type        = string
  default     = ""
}

variable "assets_bucket_arn" {
  description = "S3 bucket ARN for static assets"
  type        = string
  default     = ""
}

# Secrets
variable "secrets_arns" {
  description = "ARNs of secrets to access"
  type        = list(string)
  default     = ["*"]
}

variable "sqs_queue_arns" {
  description = "ARNs of SQS queues to access"
  type        = list(string)
  default     = ["*"]
}

# Observability
variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Edge functions
variable "enable_edge_headers" {
  description = "Enable Lambda@Edge for cache headers"
  type        = bool
  default     = false
}

variable "edge_lambda_package_path" {
  description = "Path to edge Lambda package"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
