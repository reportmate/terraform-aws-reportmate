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
  value       = module.auth.user_pool_endpoint
}

output "cognito_client_id" {
  description = "Cognito app client ID"
  value       = module.auth.client_id
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

# --- Demo Loop ---

output "demo_loop_ecr_repository_url" {
  description = "ECR repository URL for demo-loop images"
  value       = module.demo_loop.ecr_repository_url
}

output "demo_loop_service_name" {
  description = "ECS service name for the demo loop"
  value       = module.demo_loop.service_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}
