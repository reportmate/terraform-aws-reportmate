output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for API images"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR repository URL for frontend images"
  value       = aws_ecr_repository.frontend.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = try(aws_lb.main[0].dns_name, null)
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias)"
  value       = try(aws_lb.main[0].zone_id, null)
}

output "api_url" {
  description = "API base URL (ALB, or the Express URL in express mode), ending in /api"
  value       = local.alb_mode ? "http://${aws_lb.main[0].dns_name}/api" : "${local.api_express_url}/api"
}

output "alb_base_url" {
  description = "Base URL of the API for in-VPC callers (demo-loop, maintenance)"
  value       = local.alb_mode ? "http://${aws_lb.main[0].dns_name}" : local.api_express_url
}

output "frontend_url" {
  description = "Frontend URL (ALB, or the Express URL in express mode)"
  value       = local.alb_mode ? "http://${aws_lb.main[0].dns_name}" : local.frontend_express_url
}

output "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs_tasks.id
}

output "api_service_name" {
  description = "API ECS service name"
  value       = local.alb_mode ? aws_ecs_service.api[0].name : aws_ecs_express_gateway_service.api[0].service_name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = local.alb_mode ? aws_ecs_service.frontend[0].name : aws_ecs_express_gateway_service.frontend[0].service_name
}

output "api_service_url" {
  description = "HTTPS URL of the API service (Express URL in express mode; ALB DNS in alb mode)"
  value       = local.alb_mode ? "https://${aws_lb.main[0].dns_name}" : local.api_express_url
}

output "frontend_service_url" {
  description = "HTTPS URL of the frontend service (Express URL in express mode; ALB DNS in alb mode)"
  value       = local.alb_mode ? "https://${aws_lb.main[0].dns_name}" : local.frontend_express_url
}
