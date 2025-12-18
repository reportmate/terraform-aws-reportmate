# Secrets Module - AWS Secrets Manager (equivalent to Azure Key Vault)

# Main application secrets
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project_name}-${var.environment}-secrets"
  description = "Application secrets for ${var.project_name}"

  recovery_window_in_days = var.recovery_window_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    db_password       = var.db_password
    db_url            = var.db_url
    nextauth_secret   = var.nextauth_secret
    client_passphrase = var.client_passphrase
    cognito_client_id = var.cognito_client_id
    cognito_secret    = var.cognito_client_secret
  })
}

# Database credentials secret (separate for rotation support)
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-${var.environment}-db-credentials"
  description = "Database credentials for ${var.project_name}"

  recovery_window_in_days = var.recovery_window_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
  })
}

# Rotation Lambda role (for future rotation support)
resource "aws_iam_role" "rotation" {
  count       = var.enable_rotation ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-rotation-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rotation" {
  count = var.enable_rotation ? 1 : 0
  name  = "rotation-policy"
  role  = aws_iam_role.rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for reading secrets (to be attached to ECS/Lambda roles)
resource "aws_iam_policy" "read_secrets" {
  name        = "${var.project_name}-${var.environment}-read-secrets"
  description = "Policy to read application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.app_secrets.arn,
          aws_secretsmanager_secret.db_credentials.arn
        ]
      }
    ]
  })

  tags = var.tags
}

# KMS key for secret encryption (optional)
resource "aws_kms_key" "secrets" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for ${var.project_name} secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "secrets" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

data "aws_caller_identity" "current" {}
