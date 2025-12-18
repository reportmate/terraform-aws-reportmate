# ReportMate AWS Infrastructure (100% Serverless)
# This module provisions a complete serverless ReportMate infrastructure
#
# Services used:
# - Aurora Serverless v2 (PostgreSQL)
# - Lambda (Next.js SSR + API handlers)
# - API Gateway (HTTP & WebSocket)
# - CloudFront (CDN)
# - S3 (Static assets)
# - Cognito (Authentication)
# - Secrets Manager
# - CloudWatch (Monitoring)

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # App URL for auth callbacks - use custom domain if enabled, else placeholder
  # (actual CloudFront domain is set after deployment)
  app_url_for_auth = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : var.app_base_url

  # Full app URL - for outputs and reference
  app_url = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${module.cdn.cloudfront_domain}"
}

# ============================================================================
# NETWORKING (Minimal for Serverless)
# ============================================================================
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  # Serverless optimization: fewer NAT gateways
  single_nat_gateway = var.single_nat_gateway

  # VPC Endpoints for Lambda to access AWS services without internet
  enable_vpc_endpoints = true

  tags = var.tags
}

# ============================================================================
# DATABASE (Aurora Serverless v2)
# ============================================================================
module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  vpc_cidr            = var.vpc_cidr
  database_subnet_ids = module.networking.database_subnet_ids

  # Aurora Serverless v2 scaling
  serverless_min_capacity = var.db_min_capacity # 0.5 ACU minimum
  serverless_max_capacity = var.db_max_capacity # Scale as needed
  instance_count          = var.db_instance_count

  # Credentials
  db_username   = var.db_username
  db_password   = var.db_password
  db_secret_arn = module.secrets.db_credentials_arn

  # Serverless features
  enable_data_api  = var.enable_db_data_api # Query from Lambda without VPC
  enable_iam_auth  = var.enable_db_iam_auth # Passwordless Lambda access
  enable_rds_proxy = var.enable_rds_proxy   # Connection pooling for Lambda

  # Allow Lambda security groups
  allowed_security_groups = compact([
    module.serverless_nextjs.lambda_security_group_id,
    module.api.lambda_security_group_id
  ])

  # Protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = var.tags
}

# ============================================================================
# SECRETS (Secrets Manager)
# ============================================================================
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment

  # Database credentials
  db_host     = module.database.cluster_endpoint
  db_port     = module.database.cluster_port
  db_name     = module.database.database_name
  db_username = var.db_username
  db_password = var.db_password

  # Application secrets
  nextauth_secret   = var.nextauth_secret
  client_passphrase = var.client_passphrase

  # Cognito (when enabled)
  cognito_client_id     = var.enable_auth ? module.auth[0].dashboard_client_id : ""
  cognito_client_secret = var.enable_auth ? module.auth[0].dashboard_client_secret : ""

  tags = var.tags
}

# ============================================================================
# STORAGE (S3 - Static Assets)
# ============================================================================
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment

  enable_versioning  = var.enable_s3_versioning
  log_retention_days = var.log_retention_days

  tags = var.tags
}

# ============================================================================
# SERVERLESS NEXT.JS (Lambda + Function URLs)
# ============================================================================
module "serverless_nextjs" {
  source = "./modules/serverless-nextjs"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment

  # Lambda package (deploy separately or via CI/CD)
  lambda_s3_bucket   = var.nextjs_lambda_bucket
  lambda_s3_key      = var.nextjs_lambda_key
  lambda_source_hash = var.nextjs_lambda_hash

  # Lambda configuration
  lambda_timeout = var.nextjs_lambda_timeout
  lambda_memory  = var.nextjs_lambda_memory

  # Use Lambda Function URLs (simpler than API Gateway)
  use_function_url = true
  use_api_gateway  = false

  # VPC access for database (optional - can use Data API instead)
  enable_vpc         = var.nextjs_enable_vpc
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Application configuration
  app_url         = local.app_url_for_auth # Use non-circular reference
  api_base_url    = module.api.api_endpoint
  database_url    = var.nextjs_enable_vpc ? "postgresql://${var.db_username}:${urlencode(var.db_password)}@${module.database.proxy_endpoint != null ? module.database.proxy_endpoint : module.database.cluster_endpoint}:${module.database.cluster_port}/${module.database.database_name}?sslmode=require" : ""
  nextauth_secret = var.nextauth_secret
  api_passphrase  = var.client_passphrase

  # Additional environment variables
  environment_variables = merge({
    AZURE_AD_CLIENT_ID = var.enable_auth ? module.auth[0].dashboard_client_id : ""
    AZURE_AD_TENANT_ID = var.enable_auth ? module.auth[0].user_pool_id : ""
    COGNITO_CLIENT_ID  = var.enable_auth ? module.auth[0].dashboard_client_id : ""
    COGNITO_ISSUER     = var.enable_auth ? module.auth[0].issuer_url : ""
    WEBSOCKET_URL      = module.messaging.websocket_url
  }, var.nextjs_extra_env_vars)

  # Image optimization
  enable_image_optimization = var.enable_image_optimization
  assets_bucket_name        = module.storage.assets_bucket_name
  assets_bucket_arn         = module.storage.assets_bucket_arn

  # Secrets access
  secrets_arns   = [module.secrets.app_secret_arn, module.secrets.db_credentials_arn]
  sqs_queue_arns = [module.messaging.queue_arn]

  # Observability
  enable_xray        = var.enable_xray
  log_retention_days = var.log_retention_days

  tags = var.tags
}

# ============================================================================
# API (Lambda + API Gateway REST)
# ============================================================================
module "api" {
  source = "./modules/api"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Database connection
  database_url = "postgresql://${var.db_username}:${urlencode(var.db_password)}@${module.database.proxy_endpoint != null ? module.database.proxy_endpoint : module.database.cluster_endpoint}:${module.database.cluster_port}/${module.database.database_name}?sslmode=require"

  # Alternative: Use Aurora Data API (no VPC required)
  use_data_api       = var.enable_db_data_api
  aurora_cluster_arn = module.database.cluster_arn
  aurora_secret_arn  = module.secrets.db_credentials_arn

  # Secrets
  secrets_arn = module.secrets.app_secret_arn

  # Security
  database_security_group_id = module.database.security_group_id

  tags = var.tags
}

# ============================================================================
# MESSAGING (API Gateway WebSocket + SQS)
# ============================================================================
module "messaging" {
  source = "./modules/messaging"

  project_name = var.project_name
  environment  = var.environment

  # Lambda integration
  websocket_handler_invoke_arn = module.api.websocket_handler_invoke_arn
  websocket_handler_name       = module.api.websocket_handler_name

  tags = var.tags
}

# ============================================================================
# AUTHENTICATION (Cognito)
# ============================================================================
module "auth" {
  count  = var.enable_auth ? 1 : 0
  source = "./modules/auth"

  project_name = var.project_name
  environment  = var.environment

  callback_urls = [
    "${local.app_url_for_auth}/api/auth/callback/cognito"
  ]

  logout_urls = [
    local.app_url_for_auth
  ]

  tags = var.tags
}

# ============================================================================
# CDN (CloudFront)
# ============================================================================
module "cdn" {
  source = "./modules/cdn"

  project_name = var.project_name
  environment  = var.environment

  # Serverless origins
  lambda_function_url = module.serverless_nextjs.function_url
  api_endpoint        = module.api.api_endpoint

  # Static assets
  assets_bucket_name            = module.storage.assets_bucket_name
  assets_bucket_arn             = module.storage.assets_bucket_arn
  assets_bucket_regional_domain = module.storage.assets_bucket_regional_domain

  # Custom domain
  enable_custom_domain = var.enable_custom_domain
  custom_domain_name   = var.custom_domain_name
  acm_certificate_arn  = var.acm_certificate_arn

  # Image optimization (when enabled)
  image_optimizer_url = module.serverless_nextjs.image_optimizer_url

  tags = var.tags
}

# ============================================================================
# DNS (Route 53)
# ============================================================================
module "dns" {
  count  = var.enable_custom_domain && var.route53_zone_id != "" ? 1 : 0
  source = "./modules/dns"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.custom_domain_name

  create_hosted_zone = false # Using existing zone

  cloudfront_distribution_domain_name    = module.cdn.cloudfront_domain
  cloudfront_distribution_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id

  tags = var.tags
}

# ============================================================================
# MONITORING (CloudWatch)
# ============================================================================
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  log_retention_days = var.log_retention_days
  enable_alarms      = var.enable_cloudwatch_alarms

  # Serverless resources to monitor
  lambda_function_names = [
    module.serverless_nextjs.server_function_name,
    module.api.api_handler_name,
    module.api.websocket_handler_name
  ]

  aurora_cluster_id = module.database.cluster_id
  api_gateway_id    = module.api.api_gateway_id

  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  tags = var.tags
}
