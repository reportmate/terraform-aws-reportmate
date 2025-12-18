output "application_log_group_name" {
  description = "Application CloudWatch log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "Application CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.application.arn
}

output "api_log_group_name" {
  description = "API CloudWatch log group name"
  value       = aws_cloudwatch_log_group.api.name
}

output "api_log_group_arn" {
  description = "API CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.api.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : (length(aws_sns_topic.alerts) > 0 ? aws_sns_topic.alerts[0].arn : "")
}

output "ecs_cpu_alarm_arn" {
  description = "ECS CPU alarm ARN"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "ecs_memory_alarm_arn" {
  description = "ECS memory alarm ARN"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "rds_cpu_alarm_arn" {
  description = "RDS CPU alarm ARN"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
}

output "rds_storage_alarm_arn" {
  description = "RDS storage alarm ARN"
  value       = aws_cloudwatch_metric_alarm.rds_storage_low.arn
}

output "alb_5xx_alarm_arn" {
  description = "ALB 5xx errors alarm ARN"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
}
