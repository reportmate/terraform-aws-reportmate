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

resource "aws_secretsmanager_secret" "kiosk_tokens" {
  name                    = "${local.name_prefix}/kiosk-tokens"
  description             = "Kiosk viewer tokens for read-only display sessions"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-kiosk-tokens" }
}

resource "aws_secretsmanager_secret_version" "kiosk_tokens" {
  secret_id     = aws_secretsmanager_secret.kiosk_tokens.id
  secret_string = var.kiosk_tokens
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

# --- Entra ID sign-in (only when Cognito is off) ---
#
# With Cognito the auth module owns the NextAuth secret. Without it the
# frontend signs in against Microsoft Entra ID, so the NextAuth session secret
# and the Entra app client secret live here instead. The NextAuth secret uses
# its own name so switching an existing Cognito deployment to Entra does not
# collide with the Cognito one still inside its deletion recovery window.

resource "random_password" "nextauth_secret" {
  count   = var.create_entra_secrets && !local.nextauth_secret_supplied ? 1 : 0
  length  = 64
  special = true
}

locals {
  nextauth_secret_supplied = nonsensitive(var.nextauth_secret != "")
  app_insights_supplied    = nonsensitive(var.applicationinsights_connection_string != "")
}

resource "aws_secretsmanager_secret" "nextauth_secret" {
  count                   = var.create_entra_secrets ? 1 : 0
  name                    = "${local.name_prefix}/entra-nextauth-secret"
  description             = "NextAuth.js session encryption secret"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-nextauth-secret" }
}

resource "aws_secretsmanager_secret_version" "nextauth_secret" {
  count         = var.create_entra_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.nextauth_secret[0].id
  secret_string = local.nextauth_secret_supplied ? var.nextauth_secret : random_password.nextauth_secret[0].result
}

resource "aws_secretsmanager_secret" "azure_ad_client_secret" {
  count                   = var.create_entra_secrets ? 1 : 0
  name                    = "${local.name_prefix}/azure-ad-client-secret"
  description             = "Microsoft Entra ID app registration client secret"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-azure-ad-client-secret" }
}

resource "aws_secretsmanager_secret_version" "azure_ad_client_secret" {
  count         = var.create_entra_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.azure_ad_client_secret[0].id
  secret_string = var.azure_ad_client_secret
}

# --- Optional API telemetry ---

resource "aws_secretsmanager_secret" "applicationinsights_connection_string" {
  count                   = local.app_insights_supplied ? 1 : 0
  name                    = "${local.name_prefix}/applicationinsights-connection-string"
  description             = "Application Insights connection string for API telemetry"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-appinsights-connection" }
}

resource "aws_secretsmanager_secret_version" "applicationinsights_connection_string" {
  count         = local.app_insights_supplied ? 1 : 0
  secret_id     = aws_secretsmanager_secret.applicationinsights_connection_string[0].id
  secret_string = var.applicationinsights_connection_string
}
