variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "websocket_handler_invoke_arn" {
  type        = string
  description = "WebSocket handler Lambda invoke ARN"
}

variable "websocket_handler_name" {
  type        = string
  description = "WebSocket handler Lambda function name"
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
