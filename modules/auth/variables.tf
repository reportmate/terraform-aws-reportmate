variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "password_min_length" {
  type        = number
  description = "Minimum password length"
  default     = 8
}

variable "require_symbols" {
  type        = bool
  description = "Require symbols in password"
  default     = true
}

variable "mfa_configuration" {
  type        = string
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  default     = "OPTIONAL"
}

variable "admin_create_user_only" {
  type        = bool
  description = "Only admins can create users"
  default     = false
}

variable "custom_domain" {
  type        = string
  description = "Custom domain for Cognito hosted UI (optional)"
  default     = ""
}

variable "callback_urls" {
  type        = list(string)
  description = "OAuth callback URLs"
}

variable "logout_urls" {
  type        = list(string)
  description = "OAuth logout URLs"
}

variable "access_token_validity_hours" {
  type        = number
  description = "Access token validity in hours"
  default     = 1
}

variable "id_token_validity_hours" {
  type        = number
  description = "ID token validity in hours"
  default     = 1
}

variable "refresh_token_validity_days" {
  type        = number
  description = "Refresh token validity in days"
  default     = 30
}

variable "create_identity_pool" {
  type        = bool
  description = "Create Cognito Identity Pool"
  default     = false
}

variable "ses_email_identity" {
  type        = string
  description = "SES email identity ARN for sending emails"
  default     = ""
}

variable "from_email_address" {
  type        = string
  description = "From email address for Cognito emails"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
