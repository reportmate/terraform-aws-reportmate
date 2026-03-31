output "ecr_repository_url" {
  description = "ECR repository URL for demo-loop images"
  value       = aws_ecr_repository.demo_loop.repository_url
}

output "service_name" {
  description = "Name of the demo-loop ECS service"
  value       = aws_ecs_service.demo_loop.name
}

output "task_definition_arn" {
  description = "ARN of the demo-loop task definition"
  value       = aws_ecs_task_definition.demo_loop.arn
}
