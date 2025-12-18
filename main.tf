# ReportMate - Main Module (AWS)
# This module provisions a complete ReportMate infrastructure on AWS

# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking Module (VPC, Subnets, Security Groups)
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  tags = var.tags
}

# Database Module (RDS PostgreSQL)
module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  database_subnet_ids = module.networking.database_subnet_ids

  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_storage_gb     = var.db_storage_gb

  allowed_security_groups = [module.containers.ecs_security_group_id]

  tags = var.tags
}

# Storage Module (S3)
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment

  enable_versioning = var.enable_s3_versioning

  tags = var.tags
}

# Secrets Module (AWS Secrets Manager)
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment

  # Database secrets
  db_host     = module.database.db_endpoint
  db_port     = module.database.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Authentication secrets
  nextauth_secret       = var.nextauth_secret
  client_passphrases    = var.client_passphrases
  cognito_client_id     = var.enable_cognito ? module.auth[0].cognito_client_id : ""
  cognito_client_secret = var.enable_cognito ? module.auth[0].cognito_client_secret : ""

  tags = var.tags
}

# Messaging Module (API Gateway WebSocket + SQS)
module "messaging" {
  source = "./modules/messaging"

  project_name = var.project_name
  environment  = var.environment

  # Lambda integration for WebSocket handlers
  lambda_invoke_arn = module.api.websocket_handler_invoke_arn
  lambda_name       = module.api.websocket_handler_name

  tags = var.tags
}

# Monitoring Module (CloudWatch)
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  log_retention_days = var.log_retention_days
  enable_alarms      = var.enable_cloudwatch_alarms

  # Resources to monitor
  ecs_cluster_name    = module.containers.ecs_cluster_name
  rds_instance_id     = module.database.db_instance_id
  api_gateway_id      = module.api.api_gateway_id

  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  tags = var.tags
}

# Authentication Module (Cognito - Optional)
module "auth" {
  count  = var.enable_cognito ? 1 : 0
  source = "./modules/auth"

  project_name = var.project_name
  environment  = var.environment

  callback_urls = var.enable_custom_domain && var.custom_domain_name != "" ? [
    "https://${var.custom_domain_name}/api/auth/callback/cognito"
  ] : [
    "https://${module.cdn.cloudfront_domain}/api/auth/callback/cognito"
  ]

  logout_urls = var.enable_custom_domain && var.custom_domain_name != "" ? [
    "https://${var.custom_domain_name}"
  ] : [
    "https://${module.cdn.cloudfront_domain}"
  ]

  allowed_domains = var.allowed_auth_domains

  tags = var.tags
}

# API Module (Lambda + API Gateway)
module "api" {
  source = "./modules/api"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Database connection
  database_url = "postgresql://${var.db_username}:${urlencode(var.db_password)}@${module.database.db_endpoint}:${module.database.db_port}/${var.db_name}?sslmode=require"

  # Secrets
  secrets_arn = module.secrets.secrets_arn

  # WebSocket endpoint
  websocket_endpoint = module.messaging.websocket_endpoint

  # Security
  database_security_group_id = module.database.security_group_id

  tags = var.tags
}

# Containers Module (ECS Fargate for Next.js Frontend)
module "containers" {
  source = "./modules/containers"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  # Container configuration
  frontend_image     = var.frontend_image
  frontend_image_tag = var.frontend_image_tag
  container_cpu      = var.container_cpu
  container_memory   = var.container_memory
  desired_count      = var.desired_count

  # Environment variables
  database_url               = "postgresql://${var.db_username}:${urlencode(var.db_password)}@${module.database.db_endpoint}:${module.database.db_port}/${var.db_name}?sslmode=require"
  api_base_url               = module.api.api_endpoint
  websocket_endpoint         = module.messaging.websocket_endpoint
  nextauth_secret_arn        = module.secrets.nextauth_secret_arn
  client_passphrases_arn     = module.secrets.client_passphrases_arn

  # Authentication
  cognito_client_id     = var.enable_cognito ? module.auth[0].cognito_client_id : ""
  cognito_client_secret = var.enable_cognito ? module.auth[0].cognito_client_secret : ""
  cognito_issuer        = var.enable_cognito ? module.auth[0].cognito_issuer : ""

  # Custom domain
  custom_domain_name = var.custom_domain_name

  # ECR Repository
  create_ecr_repository = var.create_ecr_repository
  ecr_repository_url    = var.create_ecr_repository ? module.ecr[0].repository_url : var.existing_ecr_repository_url

  tags = var.tags
}

# ECR Module (Container Registry - Optional)
module "ecr" {
  count  = var.create_ecr_repository ? 1 : 0
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  image_retention_count = var.ecr_image_retention_count

  tags = var.tags
}

# CDN Module (CloudFront + S3 for static assets)
module "cdn" {
  source = "./modules/cdn"

  project_name = var.project_name
  environment  = var.environment

  # Origin configuration
  alb_domain_name = module.containers.alb_dns_name
  api_domain_name = module.api.api_domain_name

  # Custom domain
  enable_custom_domain = var.enable_custom_domain
  custom_domain_name   = var.custom_domain_name
  acm_certificate_arn  = var.acm_certificate_arn

  # Static assets bucket
  assets_bucket_name = module.storage.assets_bucket_name
  assets_bucket_arn  = module.storage.assets_bucket_arn

  tags = var.tags
}

# Route 53 DNS (Optional - for custom domain)
module "dns" {
  count  = var.enable_custom_domain && var.route53_zone_id != "" ? 1 : 0
  source = "./modules/dns"

  zone_id            = var.route53_zone_id
  custom_domain_name = var.custom_domain_name

  cloudfront_domain_name    = module.cdn.cloudfront_domain
  cloudfront_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id

  tags = var.tags
}
