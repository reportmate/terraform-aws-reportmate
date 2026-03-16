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
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias)"
  value       = aws_lb.main.zone_id
}

output "api_url" {
  description = "API URL via ALB"
  value       = "http://${aws_lb.main.dns_name}/api"
}

output "frontend_url" {
  description = "Frontend URL via ALB"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs_tasks.id
}

output "api_service_name" {
  description = "API ECS service name"
  value       = aws_ecs_service.api.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}
