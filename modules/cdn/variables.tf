variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

# Origin Configuration
variable "lambda_function_url" {
  type        = string
  description = "Lambda Function URL for the Next.js server"
  default     = ""
}

variable "api_endpoint" {
  type        = string
  description = "API Gateway endpoint URL"
  default     = ""
}

# S3 Static Assets
variable "assets_bucket_name" {
  type        = string
  description = "S3 assets bucket name"
}

variable "assets_bucket_arn" {
  type        = string
  description = "S3 assets bucket ARN"
}

variable "assets_bucket_regional_domain" {
  type        = string
  description = "S3 assets bucket regional domain name"
}

# Optional: Image Optimization
variable "image_optimizer_url" {
  type        = string
  description = "Lambda Function URL for image optimization"
  default     = ""
}

# Custom Domain
variable "enable_custom_domain" {
  type        = bool
  description = "Enable custom domain"
  default     = false
}

variable "custom_domain_name" {
  type        = string
  description = "Custom domain name"
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN (us-east-1 for CloudFront)"
  default     = ""
}

# CloudFront Settings
variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100" # US, Canada, Europe
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
