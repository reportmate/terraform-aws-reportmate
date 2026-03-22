output "task_definition_arn" {
  description = "ARN of the maintenance task definition"
  value       = aws_ecs_task_definition.maintenance.arn
}

output "schedule_arn" {
  description = "ARN of the EventBridge schedule"
  value       = aws_scheduler_schedule.maintenance.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for maintenance images"
  value       = aws_ecr_repository.maintenance.repository_url
}
