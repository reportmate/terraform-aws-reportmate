output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_domain_name" {
  description = "API Gateway domain name"
  value       = "${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.api.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.api.function_name
}

output "websocket_handler_invoke_arn" {
  description = "WebSocket handler Lambda invoke ARN"
  value       = aws_lambda_function.websocket.invoke_arn
}

output "websocket_handler_name" {
  description = "WebSocket handler Lambda name"
  value       = aws_lambda_function.websocket.function_name
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

data "aws_region" "current" {}
