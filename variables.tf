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

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) for private-subnet egress. Set false to skip NAT cost; tasks_in_public_subnets must then be true (or ingress_mode = \"express\" with maintenance in public subnets)."
  type        = bool
  default     = true
}

variable "tasks_in_public_subnets" {
  description = "Run ECS tasks (API, frontend, maintenance, demo loop) in the public subnets with a public IP, so they reach ECR, Secrets Manager and logs without NAT. RDS stays in the private subnets."
  type        = bool
  default     = false
}

variable "enable_multi_az_nat" {
  description = "Provision one NAT gateway per AZ instead of a single shared NAT. Doubles NAT hourly cost in exchange for AZ-isolated egress."
  type        = bool
  default     = false
}






variable "enable_s3_gateway_endpoint" {
  description = "Create the free S3 gateway endpoint on the deployment's private route tables. Turn off where the VPC owner manages S3 endpoints centrally."
  type        = bool
  default     = true
}

# --- Existing VPC (opt-in) ---
#
# Leave existing_vpc_id null to create a dedicated VPC (vpc_cidr,
# enable_multi_az_nat, enable_nat_gateway). Set it to deploy into a VPC another
# Terraform root owns: the module then creates no VPC, internet gateway or NAT.
# For each tier, pass existing subnet IDs, or CIDRs for the module to create its
# own subnets and route tables. Nothing that already exists is changed.

variable "existing_vpc_id" {
  description = "ID of an existing VPC to deploy into (for example vpc-0123456789abcdef0). Null creates a new VPC."
  type        = string
  default     = null
}

variable "existing_nat_gateway_id" {
  description = "Existing NAT gateway (nat-...) that the module-created private route table sends 0.0.0.0/0 to. Required when private_subnet_cidrs is used."
  type        = string
  default     = null
}

variable "existing_private_subnet_ids" {
  description = "Existing-VPC mode: existing private subnets to use (at least two, in different AZs), instead of private_subnet_cidrs. Their route tables stay with the VPC owner."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.existing_private_subnet_ids) == 0 || length(var.existing_private_subnet_ids) >= 2
    error_message = "existing_private_subnet_ids needs at least two subnets (RDS and the ALB need two AZs)."
  }
}

variable "existing_public_subnet_ids" {
  description = "Existing-VPC mode: existing public subnets to use (at least two, in different AZs), instead of public_subnet_cidrs. Their route tables stay with the VPC owner."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.existing_public_subnet_ids) == 0 || length(var.existing_public_subnet_ids) >= 2
    error_message = "existing_public_subnet_ids needs at least two subnets (the ALB needs two AZs)."
  }
}

variable "private_subnet_cidrs" {
  description = "Existing-VPC mode: availability zone => CIDR for the new private subnets (ECS tasks, RDS). At least two AZs; must not overlap existing subnets."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.private_subnet_cidrs) == 0 || length(var.private_subnet_cidrs) >= 2
    error_message = "private_subnet_cidrs must map at least two availability zones (RDS and the ALB need two)."
  }

  validation {
    condition     = alltrue([for cidr in values(var.private_subnet_cidrs) : can(cidrhost(cidr, 0))])
    error_message = "Every private_subnet_cidrs value must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidrs" {
  description = "Existing-VPC mode: availability zone => CIDR for the new public subnets (ALB). At least two AZs, the same ones as private_subnet_cidrs."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.public_subnet_cidrs) == 0 || length(var.public_subnet_cidrs) >= 2
    error_message = "public_subnet_cidrs must map at least two availability zones (the ALB needs two)."
  }

  validation {
    condition     = alltrue([for cidr in values(var.public_subnet_cidrs) : can(cidrhost(cidr, 0))])
    error_message = "Every public_subnet_cidrs value must be a valid IPv4 CIDR."
  }
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

variable "db_storage_type" {
  description = "RDS storage type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "db_max_allocated_storage" {
  description = "Upper limit in GB for RDS storage autoscaling. Null leaves autoscaling off."
  type        = number
  default     = null
}

variable "db_backup_retention_days" {
  description = "Days of automated RDS backups to keep (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_days >= 0 && var.db_backup_retention_days <= 35
    error_message = "db_backup_retention_days must be between 0 and 35."
  }
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

variable "api_min_count" {
  description = "Minimum (and initial desired) number of API tasks"
  type        = number
  default     = 1
}

variable "api_max_count" {
  description = "Maximum number of API tasks for CPU autoscaling"
  type        = number
  default     = 5
}

variable "frontend_min_count" {
  description = "Minimum (and initial desired) number of frontend tasks"
  type        = number
  default     = 1
}

variable "frontend_max_count" {
  description = "Maximum number of frontend tasks for CPU autoscaling"
  type        = number
  default     = 5
}

variable "cpu_architecture" {
  description = "Fargate CPU architecture for the API and frontend tasks. ARM64 needs arm64 images in ECR."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "api_extra_environment" {
  description = "Extra API environment variables (name => value). A name here replaces the module's own value for it."
  type        = map(string)
  default     = {}
}

variable "frontend_extra_environment" {
  description = "Extra frontend environment variables (name => value). A name here replaces the module's own value for it."
  type        = map(string)
  default     = {}
}

variable "api_extra_secrets" {
  description = "Extra API secrets (environment variable name => Secrets Manager secret ARN). The ECS execution role is granted read on each."
  type        = map(string)
  default     = {}
}

variable "frontend_extra_secrets" {
  description = "Extra frontend secrets (environment variable name => Secrets Manager secret ARN). The ECS execution role is granted read on each."
  type        = map(string)
  default     = {}
}

# --- Auth / Secrets ---

variable "api_internal_secret" {
  description = "Secret for container-to-container auth (frontend to API)"
  type        = string
  sensitive   = true
}

variable "kiosk_tokens" {
  description = "Comma-separated kiosk viewer tokens (label:token) that /kiosk exchanges for a read-only session. Empty disables kiosk sessions."
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_passphrase" {
  description = "Passphrase for client device authentication"
  type        = string
  sensitive   = true
}

variable "enable_cognito" {
  description = "Create a Cognito user pool for dashboard sign-in. Set false to sign in with Microsoft Entra ID (azure_ad_* inputs) instead."
  type        = bool
  default     = true
}

variable "public_url" {
  description = "Public URL users open the dashboard at (for example https://reportmate.example.com). Sets NEXTAUTH_URL, NEXTAUTH_URL_INTERNAL, NEXT_PUBLIC_SITE_URL, NEXT_PUBLIC_URL and HOST on the frontend. Empty keeps NEXTAUTH_URL = public_api_url."
  type        = string
  default     = ""
}

variable "azure_ad_client_id" {
  description = "Entra ID app registration client ID. Used when enable_cognito = false."
  type        = string
  default     = ""
}

variable "azure_ad_tenant_id" {
  description = "Entra ID tenant ID. Used when enable_cognito = false."
  type        = string
  default     = ""
}

variable "azure_ad_client_secret" {
  description = "Entra ID app registration client secret, stored in Secrets Manager. Used when enable_cognito = false."
  type        = string
  sensitive   = true
  default     = ""
}

variable "nextauth_secret" {
  description = "NextAuth session secret, stored in Secrets Manager, when enable_cognito = false. Empty generates a random one."
  type        = string
  sensitive   = true
  default     = ""
}

variable "allowed_domains" {
  description = "Email domains allowed to sign in (ALLOWED_DOMAINS on both containers), for example [\"example.com\"]. Empty sets nothing."
  type        = list(string)
  default     = []
}

variable "api_oidc_enabled" {
  description = "Let the API accept OIDC bearer tokens (ENABLE_OIDC_AUTH) from api_oidc_issuers for api_oidc_audiences."
  type        = bool
  default     = false
}

variable "api_oidc_issuers" {
  description = "Trusted OIDC issuers for API bearer tokens (OIDC_ISSUERS), for example [\"https://login.microsoftonline.com/<tenant-id>/v2.0\"]."
  type        = list(string)
  default     = []
}

variable "api_oidc_audiences" {
  description = "Accepted audiences for API bearer tokens (OIDC_AUDIENCE), for example [\"api://<client-id>\"]."
  type        = list(string)
  default     = []
}

variable "db_pool_min" {
  description = "API database pool minimum (DB_POOL_MIN). Null leaves the application default."
  type        = number
  default     = null
}

variable "db_pool_max" {
  description = "API database pool maximum (DB_POOL_MAX). Null leaves the application default."
  type        = number
  default     = null
}

variable "applicationinsights_connection_string" {
  description = "Application Insights connection string for API telemetry, stored in Secrets Manager. Empty skips it."
  type        = string
  sensitive   = true
  default     = ""
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
  description = "Public URL the browser uses to reach the API (frontend API_BASE_URL). Empty is allowed only in express ingress mode, where it falls back to the API's AWS-managed URL."
  type        = string
  default     = ""
}

# --- Ingress ---

variable "ingress_mode" {
  description = <<-EOT
    How the API and frontend are exposed.
    "alb" (default): the module's own ALB, ECS services and target groups.
    "express": ECS Express Mode services, each with an AWS-managed HTTPS URL
    on *.ecs.<region>.on.aws and no certificate or DNS of your own. Express
    tasks always run in the public subnets with public IPs.
  EOT
  type        = string
  default     = "alb"

  validation {
    condition     = contains(["alb", "express"], var.ingress_mode)
    error_message = "ingress_mode must be \"alb\" or \"express\"."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener. Empty = HTTP-only (dev only). Not used in express ingress mode."
  type        = string
  default     = ""
}




# --- Edge restriction (opt-in) ---

variable "cdn_origin_restriction" {
  description = <<-EOT
    Restrict the ALB to an external CDN. When set, the ALB security group allows
    only HTTPS from prefix_list_id (a managed prefix list of the CDN's backend
    ranges), and the HTTPS listener returns 403 unless the request carries
    header_name: header_value, which the CDN adds on its way to the origin.
    Null (default) leaves the ALB open on 80 and 443. Supported only with
    ingress_mode = "alb": an Express Mode load balancer and its security
    group are managed by AWS and have no listener rules to add a header check.
  EOT
  type = object({
    prefix_list_id = string
    header_name    = string
    header_value   = string
  })
  default   = null
  sensitive = true
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

variable "storage_bucket_name" {
  description = "Name for the storage bucket. S3 names are global, so a second deployment with the same project and environment needs its own. Null uses <project>-<environment>-storage."
  type        = string
  default     = null
}
