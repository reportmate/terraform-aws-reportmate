# =================================================================
# NETWORKING OUTPUTS
# =================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

# =================================================================
# DATABASE OUTPUTS
# =================================================================

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.database.db_endpoint
}

output "database_port" {
  description = "RDS PostgreSQL port"
  value       = module.database.db_port
}

output "database_name" {
  description = "Database name"
  value       = var.db_name
}

# =================================================================
# CONTAINER OUTPUTS
# =================================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.containers.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.containers.ecs_service_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.containers.alb_dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.create_ecr_repository ? module.ecr[0].repository_url : var.existing_ecr_repository_url
}

# =================================================================
# API OUTPUTS
# =================================================================

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "websocket_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = module.messaging.websocket_endpoint
}

# =================================================================
# CDN OUTPUTS
# =================================================================

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cdn.cloudfront_distribution_id
}

# =================================================================
# AUTHENTICATION OUTPUTS
# =================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.enable_cognito ? module.auth[0].user_pool_id : null
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = var.enable_cognito ? module.auth[0].cognito_client_id : null
}

output "cognito_domain" {
  description = "Cognito domain"
  value       = var.enable_cognito ? module.auth[0].cognito_domain : null
}

# =================================================================
# STORAGE OUTPUTS
# =================================================================

output "assets_bucket_name" {
  description = "S3 bucket name for static assets"
  value       = module.storage.assets_bucket_name
}

output "data_bucket_name" {
  description = "S3 bucket name for data storage"
  value       = module.storage.data_bucket_name
}

# =================================================================
# SECRETS OUTPUTS
# =================================================================

output "secrets_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.secrets.secrets_arn
}

# =================================================================
# MONITORING OUTPUTS
# =================================================================

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}

# =================================================================
# URL OUTPUTS
# =================================================================

output "frontend_url" {
  description = "URL of the frontend application"
  value       = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${module.cdn.cloudfront_domain}"
}

output "api_url" {
  description = "URL of the API"
  value       = module.api.api_endpoint
}
