variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# Networking
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

# IAM
variable "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

# Container config
variable "api_image_tag" {
  description = "API container image tag"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Frontend container image tag"
  type        = string
  default     = "latest"
}

variable "api_cpu" {
  description = "API task CPU units"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "API task memory in MiB"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "Frontend task CPU units"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Frontend task memory in MiB"
  type        = number
  default     = 512
}

# Secrets (ARNs for container environment)
variable "db_connection_string_secret_arn" {
  description = "ARN of the database connection string secret"
  type        = string
}

variable "api_internal_secret_arn" {
  description = "ARN of the API internal secret"
  type        = string
}

variable "kiosk_tokens_secret_arn" {
  description = "ARN of the kiosk viewer tokens secret"
  type        = string
}

variable "nextauth_secret_arn" {
  description = "ARN of the NextAuth session secret (injected into the frontend container)"
  type        = string
}

variable "client_passphrase_secret_arn" {
  description = "ARN of the client passphrase secret"
  type        = string
}

# Logging
variable "api_log_group_name" {
  description = "CloudWatch log group name for API"
  type        = string
}

variable "frontend_log_group_name" {
  description = "CloudWatch log group name for frontend"
  type        = string
}

# Database (for security group reference)
variable "database_security_group_id" {
  description = "Database security group ID to allow ECS access"
  type        = string
}

variable "public_api_url" {
  description = "Public URL the browser uses to reach the API. Wired into the frontend as API_BASE_URL. Empty in express mode uses the API's Express URL."
  type        = string
  default     = ""
}

variable "demo_mode" {
  description = "Set NEXT_PUBLIC_DEMO_MODE on the frontend. Only true for the public demo site."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the 443 listener. Empty = HTTP on 443 (fresh-deploy only; set this for any real environment)."
  type        = string
  default     = ""
}

# --- Scaling and platform ---

variable "api_min_count" {
  description = "Minimum (and initial desired) API task count"
  type        = number
  default     = 1
}

variable "api_max_count" {
  description = "Maximum API task count for CPU autoscaling"
  type        = number
  default     = 5
}

variable "frontend_min_count" {
  description = "Minimum (and initial desired) frontend task count"
  type        = number
  default     = 1
}

variable "frontend_max_count" {
  description = "Maximum frontend task count for CPU autoscaling"
  type        = number
  default     = 5
}

variable "cpu_architecture" {
  description = "Fargate CPU architecture for the API and frontend tasks: X86_64 or ARM64"
  type        = string
  default     = "X86_64"
}

# --- Sign-in ---

variable "auth_provider" {
  description = "Dashboard sign-in provider: cognito or azure-ad"
  type        = string
  default     = "cognito"
}

variable "public_url" {
  description = "Public URL users open the dashboard at. Empty keeps NEXTAUTH_URL = public_api_url and sets no site-URL variables."
  type        = string
  default     = ""
}

variable "azure_ad_client_id" {
  description = "Entra ID app registration client ID (auth_provider = azure-ad)"
  type        = string
  default     = ""
}

variable "azure_ad_tenant_id" {
  description = "Entra ID tenant ID (auth_provider = azure-ad)"
  type        = string
  default     = ""
}

variable "azure_ad_client_secret_arn" {
  description = "Secrets Manager ARN of the Entra ID client secret (auth_provider = azure-ad)"
  type        = string
  default     = null
}

variable "allowed_domains" {
  description = "Email domains allowed to sign in; passed to both containers as ALLOWED_DOMAINS. Empty sets nothing."
  type        = list(string)
  default     = []
}

# --- API bearer-token auth and tuning ---

variable "api_oidc_enabled" {
  description = "Set ENABLE_OIDC_AUTH on the API so it accepts OIDC bearer tokens"
  type        = bool
  default     = false
}

variable "api_oidc_issuers" {
  description = "Trusted OIDC issuers (OIDC_ISSUERS)"
  type        = list(string)
  default     = []
}

variable "api_oidc_audiences" {
  description = "Accepted OIDC audiences (OIDC_AUDIENCE)"
  type        = list(string)
  default     = []
}

variable "db_pool_min" {
  description = "API DB_POOL_MIN. Null leaves the application default."
  type        = number
  default     = null
}

variable "db_pool_max" {
  description = "API DB_POOL_MAX. Null leaves the application default."
  type        = number
  default     = null
}

variable "applicationinsights_connection_string_secret_arn" {
  description = "Secrets Manager ARN injected into the API as APPLICATIONINSIGHTS_CONNECTION_STRING. Null skips it."
  type        = string
  default     = null
}

# --- Extra container settings ---

variable "api_extra_environment" {
  description = "Extra API environment variables (name => value). A name here replaces the module's own value."
  type        = map(string)
  default     = {}
}

variable "frontend_extra_environment" {
  description = "Extra frontend environment variables (name => value). A name here replaces the module's own value."
  type        = map(string)
  default     = {}
}

variable "api_extra_secrets" {
  description = "Extra API secrets (environment variable name => Secrets Manager ARN)"
  type        = map(string)
  default     = {}
}

variable "frontend_extra_secrets" {
  description = "Extra frontend secrets (environment variable name => Secrets Manager ARN)"
  type        = map(string)
  default     = {}
}

# --- Edge ---

variable "cdn_origin_restriction" {
  description = "Restrict the ALB to an external CDN: HTTPS only from prefix_list_id, and requests forwarded only when header_name carries header_value. Null leaves the ALB open."
  type = object({
    prefix_list_id = string
    header_name    = string
    header_value   = string
  })
  default   = null
  sensitive = true
}

# --- Ingress mode ---

variable "ingress_mode" {
  description = "alb (module-owned ALB and ECS services) or express (ECS Express Mode services)"
  type        = string
  default     = "alb"
}

variable "infrastructure_role_arn" {
  description = "ECS infrastructure role ARN, required for ingress_mode = express"
  type        = string
  default     = null
}

variable "tasks_in_public_subnets" {
  description = "Run alb-mode ECS tasks in the public subnets with a public IP (no NAT needed). Express tasks always use the public subnets."
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  description = "VPC CIDR, allowed to reach the container ports in express mode (the AWS-managed load balancer lives in the VPC)"
  type        = string
  default     = ""
}
