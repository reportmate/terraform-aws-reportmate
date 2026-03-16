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

output "client_passphrase_secret_arn" {
  description = "ARN of the client passphrase secret"
  value       = aws_secretsmanager_secret.client_passphrase.arn
}

output "all_secret_arns" {
  description = "List of all secret ARNs for IAM policy"
  value = [
    aws_secretsmanager_secret.db_password.arn,
    aws_secretsmanager_secret.db_connection_string.arn,
    aws_secretsmanager_secret.api_internal_secret.arn,
    aws_secretsmanager_secret.client_passphrase.arn,
  ]
}
