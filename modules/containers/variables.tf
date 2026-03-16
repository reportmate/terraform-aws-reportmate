variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# Networking
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

# IAM
variable "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

# Container config
variable "api_image_tag" {
  description = "API container image tag"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Frontend container image tag"
  type        = string
  default     = "latest"
}

variable "api_cpu" {
  description = "API task CPU units"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "API task memory in MiB"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "Frontend task CPU units"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Frontend task memory in MiB"
  type        = number
  default     = 512
}

# Secrets (ARNs for container environment)
variable "db_connection_string_secret_arn" {
  description = "ARN of the database connection string secret"
  type        = string
}

variable "api_internal_secret_arn" {
  description = "ARN of the API internal secret"
  type        = string
}

variable "client_passphrase_secret_arn" {
  description = "ARN of the client passphrase secret"
  type        = string
}

# Logging
variable "api_log_group_name" {
  description = "CloudWatch log group name for API"
  type        = string
}

variable "frontend_log_group_name" {
  description = "CloudWatch log group name for frontend"
  type        = string
}

# Database (for security group reference)
variable "database_security_group_id" {
  description = "Database security group ID to allow ECS access"
  type        = string
}
