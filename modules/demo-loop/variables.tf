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

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "client_passphrase_secret_arn" {
  description = "ARN of the client passphrase secret in Secrets Manager"
  type        = string
}

variable "api_url" {
  description = "Public API URL for submitting demo payloads (e.g. https://demo.reportmate.app)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for task networking"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for task networking"
  type        = list(string)
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "batch_size" {
  description = "Number of devices per batch refresh"
  type        = number
  default     = 15
}

variable "batch_interval" {
  description = "Seconds between batch refreshes"
  type        = number
  default     = 120
}

variable "full_interval" {
  description = "Seconds between full fleet refreshes"
  type        = number
  default     = 1800
}

variable "device_count" {
  description = "Total number of demo devices"
  type        = number
  default     = 300
}
