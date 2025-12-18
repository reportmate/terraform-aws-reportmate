variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "domain_name" {
  type        = string
  description = "Base domain name"
}

variable "subdomain" {
  type        = string
  description = "Subdomain (leave empty for apex domain)"
  default     = ""
}

variable "create_hosted_zone" {
  type        = bool
  description = "Create a new hosted zone"
  default     = false
}

variable "cloudfront_distribution_domain_name" {
  type        = string
  description = "CloudFront distribution domain name"
  default     = ""
}

variable "cloudfront_distribution_hosted_zone_id" {
  type        = string
  description = "CloudFront distribution hosted zone ID"
  default     = ""
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable IPv6 records"
  default     = true
}

variable "create_www_redirect" {
  type        = bool
  description = "Create www redirect record"
  default     = true
}

variable "api_subdomain" {
  type        = string
  description = "API subdomain"
  default     = ""
}

variable "api_alb_dns_name" {
  type        = string
  description = "API ALB DNS name"
  default     = ""
}

variable "api_alb_zone_id" {
  type        = string
  description = "API ALB hosted zone ID"
  default     = ""
}

variable "certificate_validation_records" {
  type = map(object({
    name   = string
    type   = string
    record = string
  }))
  description = "ACM certificate validation records"
  default     = {}
}

variable "enable_health_check" {
  type        = bool
  description = "Enable Route 53 health check"
  default     = true
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/api/healthz"
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for health check alarms"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
