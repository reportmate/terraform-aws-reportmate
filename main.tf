# --- Networking ---

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  enable_multi_az_nat  = var.enable_multi_az_nat
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  enable_vpc_endpoints = var.enable_vpc_endpoints
  enable_nat_gateway   = var.enable_nat_gateway

  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint

  existing_vpc_id             = var.existing_vpc_id
  existing_nat_gateway_id     = var.existing_nat_gateway_id
  existing_private_subnet_ids = var.existing_private_subnet_ids
  existing_public_subnet_ids  = var.existing_public_subnet_ids
  private_subnet_cidrs        = var.private_subnet_cidrs
  public_subnet_cidrs         = var.public_subnet_cidrs
}

locals {
  # Where ECS tasks run. RDS always uses the private subnets.
  task_subnet_ids = var.tasks_in_public_subnets ? module.networking.public_subnet_ids : module.networking.private_subnet_ids
}

# --- Monitoring ---

module "monitoring" {
  source = "./modules/monitoring"

  project_name           = var.project_name
  environment            = var.environment
  log_retention_days     = var.log_retention_days
  alert_email            = var.alert_email
  daily_budget_usd       = var.daily_budget_usd
  nat_bytes_out_alarm_gb = var.nat_bytes_out_alarm_gb
  nat_gateway_ids        = module.networking.nat_gateway_ids
}

# --- Database ---

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage

  storage_type          = var.db_storage_type
  max_allocated_storage = var.db_max_allocated_storage
  backup_retention_days = var.db_backup_retention_days

  allowed_security_group_ids = [module.containers.ecs_tasks_security_group_id]
  multi_az                   = var.db_multi_az
}

# --- Secrets ---

module "secrets" {
  source = "./modules/secrets"

  project_name         = var.project_name
  environment          = var.environment
  db_password          = var.db_password
  db_connection_string = module.database.connection_string
  api_internal_secret  = var.api_internal_secret
  client_passphrase    = var.client_passphrase
  kiosk_tokens         = var.kiosk_tokens

  create_entra_secrets                  = !var.enable_cognito
  nextauth_secret                       = var.nextauth_secret
  azure_ad_client_secret                = var.azure_ad_client_secret
  applicationinsights_connection_string = var.applicationinsights_connection_string
}

# --- Storage ---

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# --- Auth ---
#
# Cognito is the default sign-in. Set enable_cognito = false to sign in with
# Microsoft Entra ID instead; the frontend then gets its Entra settings below
# and its NextAuth secret from the secrets module.

module "auth" {
  source = "./modules/auth"
  count  = var.enable_cognito ? 1 : 0

  project_name  = var.project_name
  environment   = var.environment
  callback_urls = var.auth_callback_urls
  logout_urls   = var.auth_logout_urls
}

moved {
  from = module.auth
  to   = module.auth[0]
}

locals {
  auth_secret_arns    = var.enable_cognito ? module.auth[0].secret_arns : []
  nextauth_secret_arn = var.enable_cognito ? module.auth[0].nextauth_secret_arn : module.secrets.nextauth_secret_arn

  extra_secret_arns = distinct(concat(values(var.api_extra_secrets), values(var.frontend_extra_secrets)))
}

# --- Identity ---

module "identity" {
  source = "./modules/identity"

  project_name = var.project_name
  environment  = var.environment
  ingress_mode = var.ingress_mode
  secret_arns  = concat(module.secrets.all_secret_arns, local.auth_secret_arns, local.extra_secret_arns)

  ecr_repository_arns = [
    module.containers.ecr_api_repository_url,
    module.containers.ecr_frontend_repository_url,
  ]

  log_group_arns = [
    "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-${var.environment}/*",
  ]
}

# Cross-input checks. They live on a data source so they hold on every
# supported Terraform version and add nothing to the plan.
data "aws_caller_identity" "current" {
  lifecycle {
    precondition {
      condition     = var.existing_vpc_id != null || var.enable_nat_gateway || var.tasks_in_public_subnets
      error_message = "enable_nat_gateway = false leaves private subnets without egress; set tasks_in_public_subnets = true."
    }

    precondition {
      condition     = var.ingress_mode == "alb" || !nonsensitive(var.cdn_origin_restriction != null)
      error_message = "cdn_origin_restriction needs ingress_mode = \"alb\": Express Mode load balancers are managed by AWS and cannot be restricted by this module."
    }

    precondition {
      condition     = var.ingress_mode == "express" || var.public_api_url != ""
      error_message = "public_api_url is required with ingress_mode = \"alb\"."
    }
  }
}

# --- Containers ---

module "containers" {
  source = "./modules/containers"

  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  ecs_execution_role_arn = module.identity.ecs_execution_role_arn
  ecs_task_role_arn      = module.identity.ecs_task_role_arn

  api_image_tag      = var.api_image_tag
  frontend_image_tag = var.frontend_image_tag
  api_cpu            = var.api_cpu
  api_memory         = var.api_memory
  frontend_cpu       = var.frontend_cpu
  frontend_memory    = var.frontend_memory
  api_min_count      = var.api_min_count
  api_max_count      = var.api_max_count
  frontend_min_count = var.frontend_min_count
  frontend_max_count = var.frontend_max_count
  cpu_architecture   = var.cpu_architecture

  db_connection_string_secret_arn = module.secrets.db_connection_string_secret_arn
  api_internal_secret_arn         = module.secrets.api_internal_secret_arn
  client_passphrase_secret_arn    = module.secrets.client_passphrase_secret_arn
  kiosk_tokens_secret_arn         = module.secrets.kiosk_tokens_secret_arn
  nextauth_secret_arn             = local.nextauth_secret_arn

  api_log_group_name      = module.monitoring.api_log_group_name
  frontend_log_group_name = module.monitoring.frontend_log_group_name

  database_security_group_id = module.database.security_group_id

  public_api_url      = var.public_api_url
  demo_mode           = var.enable_demo_loop
  acm_certificate_arn = var.acm_certificate_arn

  ingress_mode            = var.ingress_mode
  tasks_in_public_subnets = var.tasks_in_public_subnets
  infrastructure_role_arn = module.identity.ecs_infrastructure_role_arn

  cdn_origin_restriction = var.cdn_origin_restriction

  auth_provider              = var.enable_cognito ? "cognito" : "azure-ad"
  public_url                 = var.public_url
  azure_ad_client_id         = var.azure_ad_client_id
  azure_ad_tenant_id         = var.azure_ad_tenant_id
  azure_ad_client_secret_arn = module.secrets.azure_ad_client_secret_arn
  allowed_domains            = var.allowed_domains

  api_oidc_enabled   = var.api_oidc_enabled
  api_oidc_issuers   = var.api_oidc_issuers
  api_oidc_audiences = var.api_oidc_audiences
  db_pool_min        = var.db_pool_min
  db_pool_max        = var.db_pool_max

  applicationinsights_connection_string_secret_arn = module.secrets.applicationinsights_connection_string_secret_arn

  api_extra_environment      = var.api_extra_environment
  frontend_extra_environment = var.frontend_extra_environment
  api_extra_secrets          = var.api_extra_secrets
  frontend_extra_secrets     = var.frontend_extra_secrets
}

# --- Messaging ---

module "messaging" {
  source = "./modules/messaging"

  project_name      = var.project_name
  environment       = var.environment
  api_negotiate_url = "${module.containers.api_url}/v1/negotiate"
}

# --- Maintenance ---

module "maintenance" {
  source = "./modules/maintenance"

  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  ecs_cluster_arn        = module.containers.cluster_id
  ecs_execution_role_arn = module.identity.ecs_execution_role_arn
  ecs_task_role_arn      = module.identity.ecs_task_role_arn

  db_connection_string_secret_arn = module.secrets.db_connection_string_secret_arn

  private_subnet_ids = local.task_subnet_ids
  assign_public_ip   = var.tasks_in_public_subnets
  security_group_ids = [module.containers.ecs_tasks_security_group_id]

  log_group_name       = module.monitoring.maintenance_log_group_name
  event_retention_days = var.event_retention_days
}

# --- Demo Loop (opt-in) ---
#
# Generates synthetic device payloads for the public demo site. Off by default
# on the main branch — flip enable_demo_loop = true only where that behavior
# is actually desired.

module "demo_loop" {
  source = "./modules/demo-loop"
  count  = var.enable_demo_loop ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  ecs_cluster_arn        = module.containers.cluster_id
  ecs_execution_role_arn = module.identity.ecs_execution_role_arn
  ecs_task_role_arn      = module.identity.ecs_task_role_arn

  client_passphrase_secret_arn = module.secrets.client_passphrase_secret_arn

  # Default the demo-loop target to the ALB so submissions stay intra-VPC and
  # never hairpin through a public CDN. Override with a full URL to force an
  # external endpoint for testing.
  api_url = coalesce(var.demo_loop_api_url, module.containers.alb_base_url)

  private_subnet_ids = local.task_subnet_ids
  assign_public_ip   = var.tasks_in_public_subnets
  security_group_ids = [module.containers.ecs_tasks_security_group_id]

  log_group_name = module.monitoring.demo_loop_log_group_name
}
