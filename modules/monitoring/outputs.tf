# Monitoring Module Outputs - Serverless Architecture

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = var.enable_alarms ? aws_sns_topic.alarms[0].arn : null
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.arn
}

# Lambda Alarm Outputs
output "lambda_error_alarm_arns" {
  description = "ARNs of Lambda error alarms"
  value       = var.enable_alarms ? { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn } : {}
}

output "lambda_duration_alarm_arns" {
  description = "ARNs of Lambda duration alarms"
  value       = var.enable_alarms ? { for k, v in aws_cloudwatch_metric_alarm.lambda_duration : k => v.arn } : {}
}

output "lambda_concurrent_alarm_arns" {
  description = "ARNs of Lambda concurrent execution alarms"
  value       = var.enable_alarms ? { for k, v in aws_cloudwatch_metric_alarm.lambda_concurrent : k => v.arn } : {}
}

# Aurora Serverless Alarm Outputs
output "aurora_cpu_alarm_arn" {
  description = "ARN of Aurora CPU alarm"
  value       = var.enable_alarms && var.aurora_cluster_id != "" ? aws_cloudwatch_metric_alarm.aurora_cpu[0].arn : null
}

output "aurora_connections_alarm_arn" {
  description = "ARN of Aurora connections alarm"
  value       = var.enable_alarms && var.aurora_cluster_id != "" ? aws_cloudwatch_metric_alarm.aurora_connections[0].arn : null
}

# API Gateway Alarm Outputs
output "api_gateway_5xx_alarm_arn" {
  description = "ARN of API Gateway 5xx error alarm"
  value       = var.enable_alarms && var.api_gateway_id != "" ? aws_cloudwatch_metric_alarm.api_gateway_5xx[0].arn : null
}

output "api_gateway_latency_alarm_arn" {
  description = "ARN of API Gateway latency alarm"
  value       = var.enable_alarms && var.api_gateway_id != "" ? aws_cloudwatch_metric_alarm.api_gateway_latency[0].arn : null
}

# CloudWatch Insights Query Outputs
output "lambda_cold_start_query_id" {
  description = "ID of the Lambda cold start insights query"
  value       = aws_cloudwatch_query_definition.lambda_cold_starts.query_definition_id
}

output "lambda_errors_query_id" {
  description = "ID of the Lambda errors insights query"
  value       = aws_cloudwatch_query_definition.lambda_errors_query.query_definition_id
}

output "lambda_performance_query_id" {
  description = "ID of the Lambda performance insights query"
  value       = aws_cloudwatch_query_definition.lambda_performance.query_definition_id
}

# Summary Output
output "monitoring_summary" {
  description = "Summary of monitoring resources created"
  value = {
    dashboard_url    = "https://${data.aws_region.current.id}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
    sns_topic_arn    = var.enable_alarms ? aws_sns_topic.alarms[0].arn : null
    alarms_enabled   = var.enable_alarms
    lambda_functions = var.lambda_function_names
    aurora_cluster   = var.aurora_cluster_id
    api_gateway      = var.api_gateway_id
  }
}
