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
  description = "Private subnets owned by this deployment"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnets owned by this deployment"
  value       = module.networking.public_subnet_ids
}

# --- Edge ---

output "alb_dns_name" {
  description = "ALB DNS name: CNAME origin_domain_name to it, or use it as the CDN origin host"
  value       = module.containers.alb_dns_name
}

output "listener_certificate_arn" {
  description = "ACM certificate on the HTTPS listener (null when the listener is plain HTTP)"
  value       = local.acm_certificate_arn == "" ? null : local.acm_certificate_arn
}

output "origin_certificate_arn" {
  description = "Origin certificate requested when create_origin_certificate = true"
  value       = try(aws_acm_certificate.origin[0].arn, null)
}

output "origin_certificate_validation_records" {
  description = "DNS records to create in your DNS provider so ACM can validate the origin certificate (name, type, value)"
  value = var.create_origin_certificate ? [
    for dvo in aws_acm_certificate.origin[0].domain_validation_options : {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  ] : []
}

output "region" {
  description = "AWS region"
  value       = var.region
}
