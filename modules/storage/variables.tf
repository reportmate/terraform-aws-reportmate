variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "enable_versioning" {
  type        = bool
  description = "Enable versioning on S3 buckets"
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption (optional)"
  default     = null
}

variable "enable_lifecycle_rules" {
  type        = bool
  description = "Enable lifecycle rules for data bucket"
  default     = true
}

variable "data_retention_days" {
  type        = number
  description = "Days to retain data before expiration"
  default     = 365
}

variable "log_retention_days" {
  type        = number
  description = "Days to retain logs"
  default     = 90
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "CORS allowed origins for assets bucket"
  default     = ["*"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
