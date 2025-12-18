# =================================================================
# ReportMate AWS Infrastructure Outputs (Serverless Edition)
# =================================================================

# =================================================================
# NETWORKING OUTPUTS
# =================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

# =================================================================
# DATABASE OUTPUTS (Aurora Serverless v2)
# =================================================================

output "database_cluster_endpoint" {
  description = "Aurora Serverless v2 cluster endpoint (writer)"
  value       = module.database.cluster_endpoint
}

output "database_reader_endpoint" {
  description = "Aurora Serverless v2 reader endpoint"
  value       = module.database.cluster_reader_endpoint
}

output "database_proxy_endpoint" {
  description = "RDS Proxy endpoint (when enabled)"
  value       = module.database.proxy_endpoint
}

output "database_port" {
  description = "Aurora PostgreSQL port"
  value       = module.database.cluster_port
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "database_cluster_arn" {
  description = "Aurora cluster ARN (for Data API)"
  value       = module.database.cluster_arn
}

output "database_connection_string" {
  description = "Full connection string for Aurora (use proxy endpoint if available)"
  value       = "postgresql://${var.db_username}@${module.database.proxy_endpoint != null ? module.database.proxy_endpoint : module.database.cluster_endpoint}:${module.database.cluster_port}/${module.database.database_name}?sslmode=require"
  sensitive   = true
}

# =================================================================
# LAMBDA OUTPUTS (Next.js)
# =================================================================

output "nextjs_lambda_function_name" {
  description = "Name of the Next.js server Lambda function"
  value       = module.serverless_nextjs.server_function_name
}

output "nextjs_function_url" {
  description = "Lambda Function URL for Next.js server"
  value       = module.serverless_nextjs.function_url
}

output "image_optimizer_url" {
  description = "Lambda Function URL for image optimization"
  value       = module.serverless_nextjs.image_optimizer_url
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions (when VPC enabled)"
  value       = module.serverless_nextjs.lambda_security_group_id
}

# =================================================================
# API OUTPUTS
# =================================================================

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api.api_gateway_id
}

output "websocket_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = module.messaging.websocket_endpoint
}

output "websocket_url" {
  description = "WebSocket connection URL for clients"
  value       = module.messaging.websocket_url
}

# =================================================================
# CDN OUTPUTS
# =================================================================

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = module.cdn.cloudfront_distribution_arn
}

# =================================================================
# AUTHENTICATION OUTPUTS
# =================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.enable_auth ? module.auth[0].user_pool_id : null
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = var.enable_auth ? module.auth[0].dashboard_client_id : null
}

output "cognito_domain" {
  description = "Cognito domain"
  value       = var.enable_auth ? module.auth[0].cognito_domain : null
}

output "cognito_issuer_url" {
  description = "Cognito OIDC issuer URL"
  value       = var.enable_auth ? module.auth[0].issuer_url : null
}

# =================================================================
# STORAGE OUTPUTS
# =================================================================

output "assets_bucket_name" {
  description = "S3 bucket name for static assets"
  value       = module.storage.assets_bucket_name
}

output "assets_bucket_arn" {
  description = "S3 bucket ARN for static assets"
  value       = module.storage.assets_bucket_arn
}

output "data_bucket_name" {
  description = "S3 bucket name for data storage"
  value       = module.storage.data_bucket_name
}

# =================================================================
# MESSAGING OUTPUTS
# =================================================================

output "sqs_queue_url" {
  description = "SQS queue URL for async processing"
  value       = module.messaging.queue_url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = module.messaging.queue_arn
}

# =================================================================
# SECRETS OUTPUTS
# =================================================================

output "app_secret_arn" {
  description = "ARN of the application secrets"
  value       = module.secrets.app_secret_arn
}

output "db_credentials_arn" {
  description = "ARN of the database credentials secret"
  value       = module.secrets.db_credentials_arn
}

# =================================================================
# MONITORING OUTPUTS
# =================================================================

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.monitoring.dashboard_name
}

# =================================================================
# URL OUTPUTS
# =================================================================

output "frontend_url" {
  description = "URL of the frontend application"
  value       = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${module.cdn.cloudfront_domain}"
}

output "api_url" {
  description = "Public API URL"
  value       = module.api.api_endpoint
}

# =================================================================
# DEPLOYMENT INFO
# =================================================================

output "deployment_info" {
  description = "Summary of deployed serverless infrastructure"
  value = {
    architecture = "100% Serverless"
    compute      = "AWS Lambda"
    database     = "Aurora Serverless v2 (PostgreSQL)"
    cdn          = "CloudFront"
    api          = "API Gateway HTTP API"
    auth         = var.enable_auth ? "Cognito" : "Disabled"
    realtime     = "API Gateway WebSocket"
    region       = data.aws_region.current.id
    account_id   = data.aws_caller_identity.current.account_id
  }
}
