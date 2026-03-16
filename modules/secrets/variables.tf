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

variable "client_passphrase" {
  description = "Client device authentication passphrase"
  type        = string
  sensitive   = true
}
