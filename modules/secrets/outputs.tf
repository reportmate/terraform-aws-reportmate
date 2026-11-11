output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_connection_string_secret_arn" {
  description = "ARN of the database connection string secret"
  value       = aws_secretsmanager_secret.db_connection_string.arn
}

output "api_internal_secret_arn" {
  description = "ARN of the API internal secret"
  value       = aws_secretsmanager_secret.api_internal_secret.arn
}

output "kiosk_tokens_secret_arn" {
  description = "ARN of the kiosk viewer tokens secret"
  value       = aws_secretsmanager_secret.kiosk_tokens.arn
}

output "client_passphrase_secret_arn" {
  description = "ARN of the client passphrase secret"
  value       = aws_secretsmanager_secret.client_passphrase.arn
}

output "nextauth_secret_arn" {
  description = "ARN of the NextAuth session secret (null unless create_entra_secrets)"
  value       = try(aws_secretsmanager_secret.nextauth_secret[0].arn, null)
}

output "azure_ad_client_secret_arn" {
  description = "ARN of the Entra ID client secret (null unless create_entra_secrets)"
  value       = try(aws_secretsmanager_secret.azure_ad_client_secret[0].arn, null)
}

output "applicationinsights_connection_string_secret_arn" {
  description = "ARN of the Application Insights connection string secret (null when not supplied)"
  value       = try(aws_secretsmanager_secret.applicationinsights_connection_string[0].arn, null)
}

output "all_secret_arns" {
  description = "List of all secret ARNs for IAM policy"
  value = concat(
    [
      aws_secretsmanager_secret.db_password.arn,
      aws_secretsmanager_secret.db_connection_string.arn,
      aws_secretsmanager_secret.api_internal_secret.arn,
      aws_secretsmanager_secret.kiosk_tokens.arn,
      aws_secretsmanager_secret.client_passphrase.arn,
    ],
    aws_secretsmanager_secret.nextauth_secret[*].arn,
    aws_secretsmanager_secret.azure_ad_client_secret[*].arn,
    aws_secretsmanager_secret.applicationinsights_connection_string[*].arn,
  )
}
