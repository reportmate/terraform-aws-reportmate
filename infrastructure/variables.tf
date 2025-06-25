### PostgreSQL
variable "db_username" {
  type    = string
  default = "reportmate"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

### Container Images
variable "frontend_image_tag" {
  type        = string
  description = "Docker image tag for the frontend container"
  default     = "latest"
}

variable "functions_image_tag" {
  type        = string
  description = "Docker image tag for the functions container (currently not used - functions use zip deployment)"
  default     = "latest"
}

### Pipeline Permissions
variable "enable_pipeline_permissions" {
  type        = bool
  description = "Enable RBAC permissions for Azure DevOps pipeline service principal"
  default     = false
}

variable "pipeline_service_principal_id" {
  type        = string
  description = "Object ID of the Azure DevOps pipeline service principal"
  default     = ""
}

### remote-state backend (override in CLI or tfvars)
variable "backend_rg_name" {
  type    = string
  default = "tfstate-rg"
}

variable "backend_sa_name" {
  type    = string
  default = "tfstatestorage"
}

variable "backend_container_name" {
  type    = string
  default = "tfstate"
}

### Custom Domain Configuration
variable "custom_domain_name" {
  type        = string
  description = "Custom domain name for the frontend (e.g., reportmate.ecuad.ca)"
  default     = ""
}

variable "enable_custom_domain" {
  type        = bool
  description = "Enable custom domain configuration"
  default     = false
}
