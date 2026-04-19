variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Email subscribed to the alerts SNS topic. Set to \"\" to skip the subscription and budget email."
  type        = string
  default     = ""
}

variable "daily_budget_usd" {
  description = "Daily cost budget in USD. ACTUAL and FORECASTED notifications fire at 100%."
  type        = number
  default     = 5
}
