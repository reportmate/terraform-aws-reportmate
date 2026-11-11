variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "db_password" {
  description = "Database password to store"
  type        = string
  sensitive   = true
}

variable "db_connection_string" {
  description = "Full database connection string"
  type        = string
  sensitive   = true
}

variable "api_internal_secret" {
  description = "Container-to-container auth secret"
  type        = string
  sensitive   = true
}

variable "kiosk_tokens" {
  description = "Comma-separated kiosk viewer tokens for read-only display sessions"
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_passphrase" {
  description = "Client device authentication passphrase"
  type        = string
  sensitive   = true
}

variable "create_entra_secrets" {
  description = "Create the NextAuth and Entra ID client secrets (set when Cognito is disabled)."
  type        = bool
  default     = false
}

variable "nextauth_secret" {
  description = "NextAuth session secret. Empty generates a random one."
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_ad_client_secret" {
  description = "Microsoft Entra ID app registration client secret."
  type        = string
  sensitive   = true
  default     = ""
}

variable "applicationinsights_connection_string" {
  description = "Application Insights connection string for the API. Empty skips the secret."
  type        = string
  sensitive   = true
  default     = ""
}
