output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool OIDC endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Cognito User Pool hosted UI domain"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "client_secret" {
  description = "Cognito App Client Secret"
  value       = aws_cognito_user_pool_client.web.client_secret
  sensitive   = true
}

output "nextauth_secret" {
  description = "Generated NextAuth session secret"
  value       = random_password.nextauth_secret.result
  sensitive   = true
}

output "secret_arns" {
  description = "All auth-related secret ARNs for IAM policy"
  value = [
    aws_secretsmanager_secret.cognito_client_id.arn,
    aws_secretsmanager_secret.cognito_client_secret.arn,
    aws_secretsmanager_secret.nextauth_secret.arn,
  ]
}

data "aws_region" "current" {}
