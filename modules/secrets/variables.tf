variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "db_url" {
  type        = string
  description = "Database connection URL"
  sensitive   = true
  default     = ""
}

variable "db_username" {
  type        = string
  description = "Database username"
  default     = "reportmate"
}

variable "db_host" {
  type        = string
  description = "Database host"
  default     = ""
}

variable "db_port" {
  type        = number
  description = "Database port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "reportmate"
}

variable "nextauth_secret" {
  type        = string
  description = "NextAuth.js secret"
  sensitive   = true
  default     = ""
}

variable "client_passphrase" {
  type        = string
  description = "Client authentication passphrase"
  sensitive   = true
  default     = ""
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito app client ID"
  default     = ""
}

variable "cognito_client_secret" {
  type        = string
  description = "Cognito app client secret"
  sensitive   = true
  default     = ""
}

variable "recovery_window_days" {
  type        = number
  description = "Recovery window for deleted secrets"
  default     = 7
}

variable "enable_rotation" {
  type        = bool
  description = "Enable secret rotation"
  default     = false
}

variable "create_kms_key" {
  type        = bool
  description = "Create a custom KMS key for encryption"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
