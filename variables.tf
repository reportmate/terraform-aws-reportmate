# --- General ---

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "reportmate"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Root domain name for the application"
  type        = string
  default     = "reportmate.app"
}

variable "enable_custom_domain" {
  description = "Enable CloudFront + ACM + Route53 for custom domain"
  type        = bool
  default     = false
}

# --- Database ---

variable "db_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "reportmate"
}

variable "db_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 32
}

# --- Containers ---

variable "api_image_tag" {
  description = "Docker image tag for the API container"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Docker image tag for the frontend container"
  type        = string
  default     = "latest"
}

variable "api_cpu" {
  description = "CPU units for API task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory in MiB for API task"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU units for frontend task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory in MiB for frontend task"
  type        = number
  default     = 512
}

# --- Auth / Secrets ---

variable "api_internal_secret" {
  description = "Secret for container-to-container auth (frontend to API)"
  type        = string
  sensitive   = true
}

variable "client_passphrase" {
  description = "Passphrase for client device authentication"
  type        = string
  sensitive   = true
}

variable "auth_callback_urls" {
  description = "OAuth2 callback URLs for the web application"
  type        = list(string)
  default     = ["http://localhost:3000/api/auth/callback/cognito"]
}

variable "auth_logout_urls" {
  description = "Logout redirect URLs"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

# --- Monitoring ---

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# --- Maintenance ---

variable "event_retention_days" {
  description = "Number of days to retain events before cleanup"
  type        = number
  default     = 30
}

# --- Demo Loop ---

variable "demo_api_url" {
  description = "Public API URL for the demo loop to submit device payloads"
  type        = string
  default     = "https://demo.reportmate.app"
}
