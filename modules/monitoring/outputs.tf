output "api_log_group_name" {
  description = "API CloudWatch log group name"
  value       = aws_cloudwatch_log_group.api.name
}

output "frontend_log_group_name" {
  description = "Frontend CloudWatch log group name"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "maintenance_log_group_name" {
  description = "Maintenance CloudWatch log group name"
  value       = aws_cloudwatch_log_group.maintenance.name
}

output "demo_loop_log_group_name" {
  description = "Demo loop CloudWatch log group name"
  value       = aws_cloudwatch_log_group.demo_loop.name
}

output "alerts_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.alerts.arn
}
