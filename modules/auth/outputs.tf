output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "dashboard_client_id" {
  description = "Dashboard app client ID"
  value       = aws_cognito_user_pool_client.dashboard.id
}

output "dashboard_client_secret" {
  description = "Dashboard app client secret"
  value       = aws_cognito_user_pool_client.dashboard.client_secret
  sensitive   = true
}

output "api_client_id" {
  description = "API app client ID"
  value       = aws_cognito_user_pool_client.api.id
}

output "api_client_secret" {
  description = "API app client secret"
  value       = aws_cognito_user_pool_client.api.client_secret
  sensitive   = true
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.main[0].id : null
}

output "issuer_url" {
  description = "OIDC issuer URL"
  value       = "https://${aws_cognito_user_pool.main.endpoint}"
}

output "hosted_ui_url" {
  description = "Hosted UI URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

data "aws_region" "current" {}
