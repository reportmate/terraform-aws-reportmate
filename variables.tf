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

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs to S3. Recommended for production — without them, per-IP egress is invisible during cost incidents."
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Provision interface endpoints for ECR, CloudWatch Logs, and Secrets Manager. Adds ~$0.01/hr per endpoint per AZ; opt in once steady-state NAT egress justifies it. The S3 gateway endpoint is always created (free)."
  type        = bool
  default     = false
}

variable "enable_multi_az_nat" {
  description = "Provision one NAT gateway per AZ instead of a single shared NAT. Doubles NAT hourly cost in exchange for AZ-isolated egress."
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

variable "db_multi_az" {
  description = "Enable RDS Multi-AZ. Roughly doubles instance + storage cost; required for prod HA."
  type        = bool
  default     = false
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

variable "alert_email" {
  description = "Email subscribed to the alerts SNS topic (used by the cost budget and NAT egress alarm). Leave empty to skip the email subscription and budget notification."
  type        = string
  default     = ""
}

variable "daily_budget_usd" {
  description = "Daily cost budget in USD. ACTUAL and FORECASTED notifications fire at 100%."
  type        = number
  default     = 30
}

variable "nat_bytes_out_alarm_gb" {
  description = "Trigger the NAT BytesOutToDestination alarm if hourly egress exceeds this many GB. Set to 0 to disable the alarm."
  type        = number
  default     = 20
}

# --- Maintenance ---

variable "event_retention_days" {
  description = "Number of days to retain events before cleanup"
  type        = number
  default     = 30
}

# --- Public URL ---

variable "public_api_url" {
  description = "Public URL the browser uses to reach the API (frontend API_BASE_URL). Required so the rendered HTML points at the right hostname."
  type        = string
}

# --- Demo Loop ---

variable "enable_demo_loop" {
  description = "Provision the synthetic-data demo-loop service. Default off — only meant for the public demo deployment."
  type        = bool
  default     = false
}

variable "demo_loop_api_url" {
  description = "URL the demo-loop posts to. Defaults to the in-VPC ALB DNS so payloads do not hairpin through any external CDN."
  type        = string
  default     = ""
}
