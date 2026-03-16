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
