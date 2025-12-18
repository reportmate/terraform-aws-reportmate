output "websocket_api_id" {
  description = "WebSocket API ID"
  value       = aws_apigatewayv2_api.websocket.id
}

output "websocket_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = aws_apigatewayv2_stage.websocket.invoke_url
}

output "websocket_connection_url" {
  description = "WebSocket connection URL"
  value       = replace(aws_apigatewayv2_stage.websocket.invoke_url, "wss://", "https://")
}

output "sqs_queue_arn" {
  description = "SQS messages queue ARN"
  value       = aws_sqs_queue.messages.arn
}

output "sqs_queue_url" {
  description = "SQS messages queue URL"
  value       = aws_sqs_queue.messages.url
}

output "sns_topic_arn" {
  description = "SNS events topic ARN"
  value       = aws_sns_topic.events.arn
}

output "connections_table_name" {
  description = "DynamoDB connections table name"
  value       = aws_dynamodb_table.connections.name
}

output "connections_table_arn" {
  description = "DynamoDB connections table ARN"
  value       = aws_dynamodb_table.connections.arn
}

output "manage_connections_policy_arn" {
  description = "IAM policy ARN for managing connections"
  value       = aws_iam_policy.manage_connections.arn
}
