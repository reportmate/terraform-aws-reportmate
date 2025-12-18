output "app_secrets_arn" {
  description = "Application secrets ARN"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "app_secrets_name" {
  description = "Application secrets name"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "db_credentials_arn" {
  description = "Database credentials secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_name" {
  description = "Database credentials secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "read_secrets_policy_arn" {
  description = "IAM policy ARN for reading secrets"
  value       = aws_iam_policy.read_secrets.arn
}

output "kms_key_arn" {
  description = "KMS key ARN for secret encryption"
  value       = var.create_kms_key ? aws_kms_key.secrets[0].arn : null
}

output "kms_key_id" {
  description = "KMS key ID for secret encryption"
  value       = var.create_kms_key ? aws_kms_key.secrets[0].key_id : null
}
