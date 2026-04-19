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
  default     = 30
}

variable "alert_email" {
  description = "Email subscribed to the alerts SNS topic. Empty disables both the email subscription and the cost budget."
  type        = string
  default     = ""
}

variable "daily_budget_usd" {
  description = "Daily cost budget in USD. ACTUAL and FORECASTED notifications fire at 100%."
  type        = number
  default     = 30
}

variable "nat_bytes_out_alarm_gb" {
  description = "Trigger the NAT BytesOutToDestination alarm if hourly egress exceeds this many GB. Set to 0 to disable."
  type        = number
  default     = 20
}

variable "nat_gateway_ids" {
  description = "NAT gateway IDs to alarm on. Pass module.networking.nat_gateway_ids."
  type        = list(string)
  default     = []
}
