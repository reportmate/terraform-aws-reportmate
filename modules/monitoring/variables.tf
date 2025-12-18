variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name for metrics"
  default     = ""
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name for metrics"
  default     = ""
}

variable "db_instance_identifier" {
  type        = string
  description = "RDS instance identifier for metrics"
  default     = ""
}

variable "alb_name" {
  type        = string
  description = "ALB name for metrics"
  default     = ""
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
  default     = ""
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "CPU utilization alarm threshold"
  default     = 80
}

variable "memory_alarm_threshold" {
  type        = number
  description = "Memory utilization alarm threshold"
  default     = 80
}

variable "rds_storage_threshold_bytes" {
  type        = number
  description = "RDS free storage alarm threshold in bytes"
  default     = 5368709120  # 5GB
}

variable "error_count_threshold" {
  type        = number
  description = "5xx error count alarm threshold"
  default     = 50
}

variable "enable_xray" {
  type        = bool
  description = "Enable X-Ray tracing"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
