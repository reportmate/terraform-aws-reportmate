locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name_prefix}/db-password"
  description             = "ReportMate database password"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-db-password" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "db_connection_string" {
  name                    = "${local.name_prefix}/db-connection-string"
  description             = "ReportMate database connection string"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-db-connection" }
}

resource "aws_secretsmanager_secret_version" "db_connection_string" {
  secret_id     = aws_secretsmanager_secret.db_connection_string.id
  secret_string = var.db_connection_string
}

resource "aws_secretsmanager_secret" "api_internal_secret" {
  name                    = "${local.name_prefix}/api-internal-secret"
  description             = "Container-to-container auth secret"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-api-internal" }
}

resource "aws_secretsmanager_secret_version" "api_internal_secret" {
  secret_id     = aws_secretsmanager_secret.api_internal_secret.id
  secret_string = var.api_internal_secret
}

resource "aws_secretsmanager_secret" "client_passphrase" {
  name                    = "${local.name_prefix}/client-passphrase"
  description             = "Client device authentication passphrase"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-client-passphrase" }
}

resource "aws_secretsmanager_secret_version" "client_passphrase" {
  secret_id     = aws_secretsmanager_secret.client_passphrase.id
  secret_string = var.client_passphrase
}
