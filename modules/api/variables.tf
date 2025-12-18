variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda"
}

variable "database_url" {
  type        = string
  description = "Database connection URL (for VPC mode)"
  sensitive   = true
  default     = ""
}

variable "secrets_arn" {
  type        = string
  description = "ARN of secrets in Secrets Manager"
}

variable "websocket_endpoint" {
  type        = string
  description = "WebSocket API endpoint"
  default     = ""
}

variable "database_security_group_id" {
  type        = string
  description = "Security group ID for database access"
  default     = ""
}

# Aurora Data API support (serverless mode)
variable "use_data_api" {
  type        = bool
  description = "Use Aurora Data API instead of VPC database connection"
  default     = false
}

variable "aurora_cluster_arn" {
  type        = string
  description = "Aurora cluster ARN (for Data API)"
  default     = ""
}

variable "aurora_secret_arn" {
  type        = string
  description = "Secret ARN for Aurora authentication (for Data API)"
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
