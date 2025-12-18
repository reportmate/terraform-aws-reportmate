# Monitoring Module - Variables (Serverless)

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

# Serverless resources
variable "lambda_function_names" {
  type        = list(string)
  description = "Lambda function names to monitor"
  default     = []
}

variable "aurora_cluster_id" {
  type        = string
  description = "Aurora Serverless cluster identifier"
  default     = ""
}

variable "api_gateway_id" {
  type        = string
  description = "API Gateway ID to monitor"
  default     = ""
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "CloudFront distribution ID to monitor"
  default     = ""
}

# Alarms
variable "enable_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms"
  default     = true
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
  default     = ""
}

variable "lambda_error_threshold" {
  type        = number
  description = "Lambda error count alarm threshold"
  default     = 5
}

variable "lambda_duration_threshold_ms" {
  type        = number
  description = "Lambda duration alarm threshold in milliseconds"
  default     = 10000 # 10 seconds
}

variable "lambda_concurrent_threshold" {
  type        = number
  description = "Lambda concurrent executions alarm threshold"
  default     = 100
}

variable "aurora_cpu_threshold" {
  type        = number
  description = "Aurora CPU utilization alarm threshold"
  default     = 80
}

variable "aurora_connections_threshold" {
  type        = number
  description = "Aurora database connections alarm threshold"
  default     = 100
}

variable "api_gateway_5xx_threshold" {
  type        = number
  description = "API Gateway 5xx error alarm threshold"
  default     = 10
}

variable "api_gateway_latency_threshold_ms" {
  type        = number
  description = "API Gateway latency alarm threshold in milliseconds"
  default     = 5000
}

# X-Ray
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
