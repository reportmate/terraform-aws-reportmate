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
  description = "Database connection URL"
  sensitive   = true
}

variable "secrets_arn" {
  type        = string
  description = "ARN of secrets in Secrets Manager"
}

variable "websocket_endpoint" {
  type        = string
  description = "WebSocket API endpoint"
}

variable "database_security_group_id" {
  type        = string
  description = "Security group ID for database access"
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
