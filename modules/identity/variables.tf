variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "secret_arns" {
  description = "ARNs of Secrets Manager secrets the ECS tasks need access to"
  type        = list(string)
  default     = []
}

variable "log_group_arns" {
  description = "ARNs of CloudWatch log groups"
  type        = list(string)
  default     = []
}
