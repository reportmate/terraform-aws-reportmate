output "api_url" {
  description = "API load balancer URL"
  value       = module.containers.api_url
}

output "frontend_url" {
  description = "Frontend load balancer URL"
  value       = module.containers.frontend_url
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for API images"
  value       = module.containers.ecr_api_repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR repository URL for frontend images"
  value       = module.containers.ecr_frontend_repository_url
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.endpoint
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

# --- Storage ---

output "ingest_queue_url" {
  description = "SQS ingest queue URL"
  value       = module.storage.ingest_queue_url
}

output "storage_bucket_name" {
  description = "S3 storage bucket name"
  value       = module.storage.bucket_name
}

# --- Auth ---

output "cognito_user_pool_endpoint" {
  description = "Cognito OIDC endpoint"
  value       = try(module.auth[0].user_pool_endpoint, null)
}

output "cognito_client_id" {
  description = "Cognito app client ID"
  value       = try(module.auth[0].client_id, null)
}

# --- Messaging ---

output "websocket_url" {
  description = "WebSocket connection URL"
  value       = module.messaging.websocket_url
}

# --- Maintenance ---

output "ecr_maintenance_repository_url" {
  description = "ECR repository URL for maintenance images"
  value       = module.maintenance.ecr_repository_url
}

# --- Demo Loop (only populated when enable_demo_loop = true) ---

output "demo_loop_ecr_repository_url" {
  description = "ECR repository URL for demo-loop images"
  value       = try(module.demo_loop[0].ecr_repository_url, null)
}

output "demo_loop_service_name" {
  description = "ECS service name for the demo loop"
  value       = try(module.demo_loop[0].service_name, null)
}

# --- Networking ---

output "vpc_id" {
  description = "VPC the deployment runs in (created or existing)"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets the deployment uses"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnets the deployment uses"
  value       = module.networking.public_subnet_ids
}

# --- Edge ---

output "alb_dns_name" {
  description = "Module ALB DNS name, the origin host for an external CDN (null in express mode)"
  value       = module.containers.alb_dns_name
}

output "api_service_url" {
  description = "HTTPS URL of the API: the AWS-managed Express Mode URL, or the ALB URL in alb mode"
  value       = module.containers.api_service_url
}

output "frontend_service_url" {
  description = "HTTPS URL of the frontend: the AWS-managed Express Mode URL, or the ALB URL in alb mode"
  value       = module.containers.frontend_service_url
}

output "region" {
  description = "AWS region"
  value       = var.region
}
