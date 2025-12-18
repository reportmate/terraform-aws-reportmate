variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "image_tag_mutability" {
  type        = string
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Scan images on push"
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption (optional)"
  default     = null
}

variable "keep_image_count" {
  type        = number
  description = "Number of tagged images to keep"
  default     = 30
}

variable "untagged_expiry_days" {
  type        = number
  description = "Days to keep untagged images"
  default     = 14
}

variable "allowed_account_ids" {
  type        = list(string)
  description = "AWS account IDs allowed to pull images"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
