# Lambda outputs
output "server_function_name" {
  description = "Next.js server Lambda function name"
  value       = aws_lambda_function.nextjs_server.function_name
}

output "server_function_arn" {
  description = "Next.js server Lambda function ARN"
  value       = aws_lambda_function.nextjs_server.arn
}

output "server_invoke_arn" {
  description = "Next.js server Lambda invoke ARN"
  value       = aws_lambda_function.nextjs_server.invoke_arn
}

# Function URL (when enabled)
output "function_url" {
  description = "Lambda function URL endpoint"
  value       = var.use_function_url ? aws_lambda_function_url.nextjs_server[0].function_url : null
}

# API Gateway (when enabled)
output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = var.use_api_gateway ? aws_apigatewayv2_stage.nextjs[0].invoke_url : null
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = var.use_api_gateway ? aws_apigatewayv2_api.nextjs[0].id : null
}

# Primary endpoint (function URL or API Gateway)
output "endpoint" {
  description = "Primary endpoint URL"
  value       = var.use_function_url ? aws_lambda_function_url.nextjs_server[0].function_url : (var.use_api_gateway ? aws_apigatewayv2_stage.nextjs[0].invoke_url : null)
}

# Image Optimizer
output "image_optimizer_function_name" {
  description = "Image optimizer Lambda function name"
  value       = var.enable_image_optimization ? aws_lambda_function.image_optimizer[0].function_name : null
}

output "image_optimizer_url" {
  description = "Image optimizer function URL"
  value       = var.enable_image_optimization && var.use_function_url ? aws_lambda_function_url.image_optimizer[0].function_url : null
}

# Security Group
output "lambda_security_group_id" {
  description = "Lambda security group ID (when VPC enabled)"
  value       = var.enable_vpc ? aws_security_group.lambda[0].id : null
}

# IAM Role
output "lambda_role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.nextjs_lambda.arn
}

output "lambda_role_name" {
  description = "Lambda IAM role name"
  value       = aws_iam_role.nextjs_lambda.name
}

# Edge Lambda (when enabled)
output "edge_lambda_arn" {
  description = "Edge Lambda qualified ARN"
  value       = var.enable_edge_headers ? aws_lambda_function.edge_headers[0].qualified_arn : null
}

# CloudFront integration info
output "cloudfront_origin_config" {
  description = "Configuration for CloudFront origin"
  value = {
    domain_name = var.use_function_url ? replace(replace(aws_lambda_function_url.nextjs_server[0].function_url, "https://", ""), "/", "") : null
    origin_id   = "nextjs-lambda"
    origin_type = "custom"
  }
}
