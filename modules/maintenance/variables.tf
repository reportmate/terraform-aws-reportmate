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
  description = "ARN of the ECS cluster to run maintenance tasks"
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

variable "db_connection_string_secret_arn" {
  description = "ARN of the database connection string secret"
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

variable "event_retention_days" {
  description = "Number of days to retain events before cleanup"
  type        = number
  default     = 30
}
