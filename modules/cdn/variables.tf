variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "assets_bucket_domain_name" {
  type        = string
  description = "S3 assets bucket regional domain name"
}

variable "cloudfront_oai_path" {
  type        = string
  description = "CloudFront Origin Access Identity path"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name"
}

variable "api_domain_name" {
  type        = string
  description = "API Gateway domain name"
}

variable "custom_domain" {
  type        = string
  description = "Custom domain name"
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN (us-east-1 for CloudFront)"
  default     = ""
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100"  # US, Canada, Europe
}

variable "geo_restriction_type" {
  type        = string
  description = "Geo restriction type (none, whitelist, blacklist)"
  default     = "none"
}

variable "geo_restriction_locations" {
  type        = list(string)
  description = "Geo restriction locations"
  default     = []
}

variable "logs_bucket_domain_name" {
  type        = string
  description = "S3 bucket domain name for CloudFront logs"
  default     = ""
}

variable "waf_web_acl_arn" {
  type        = string
  description = "WAF Web ACL ARN"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
