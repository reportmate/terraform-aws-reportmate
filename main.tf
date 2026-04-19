# --- Networking ---

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# --- Monitoring ---

module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
  alert_email        = var.alert_email
  daily_budget_usd   = var.daily_budget_usd
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

  allowed_security_group_ids = [module.containers.ecs_tasks_security_group_id]
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
}

# --- Storage ---

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# --- Auth ---

module "auth" {
  source = "./modules/auth"

  project_name  = var.project_name
  environment   = var.environment
  callback_urls = var.auth_callback_urls
  logout_urls   = var.auth_logout_urls
}

# --- Identity ---

module "identity" {
  source = "./modules/identity"

  project_name = var.project_name
  environment  = var.environment
  secret_arns  = concat(module.secrets.all_secret_arns, module.auth.secret_arns)

  ecr_repository_arns = [
    module.containers.ecr_api_repository_url,
    module.containers.ecr_frontend_repository_url,
  ]

  log_group_arns = [
    "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-${var.environment}/*",
  ]
}

data "aws_caller_identity" "current" {}

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

  db_connection_string_secret_arn = module.secrets.db_connection_string_secret_arn
  api_internal_secret_arn         = module.secrets.api_internal_secret_arn
  client_passphrase_secret_arn    = module.secrets.client_passphrase_secret_arn

  api_log_group_name      = module.monitoring.api_log_group_name
  frontend_log_group_name = module.monitoring.frontend_log_group_name

  database_security_group_id = module.database.security_group_id

  public_api_url      = var.public_api_url
  acm_certificate_arn = var.acm_certificate_arn
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

  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.containers.ecs_tasks_security_group_id]

  log_group_name       = module.monitoring.maintenance_log_group_name
  event_retention_days = var.event_retention_days
}

# --- Demo Loop ---

module "demo_loop" {
  source = "./modules/demo-loop"

  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  ecs_cluster_arn        = module.containers.cluster_id
  ecs_execution_role_arn = module.identity.ecs_execution_role_arn
  ecs_task_role_arn      = module.identity.ecs_task_role_arn

  client_passphrase_secret_arn = module.secrets.client_passphrase_secret_arn

  # Demo-loop targets the ALB directly (intra-region, intra-VPC). Avoids the
  # cost of hair-pinning through any CDN/edge in front of demo.reportmate.app.
  api_url = module.containers.alb_base_url

  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.containers.ecs_tasks_security_group_id]

  log_group_name = module.monitoring.demo_loop_log_group_name
}
