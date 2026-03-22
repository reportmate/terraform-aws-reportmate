locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Cognito User Pool -- OIDC/OAuth2 authentication
# Mirrors Azure Entra ID app registration
resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-users"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # MFA (optional, off by default for parity with Azure)
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Schema attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  tags = { Name = "${local.name_prefix}-user-pool" }
}

# User Pool Domain (hosted UI)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = local.name_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

# App Client for the web application (NextAuth integration)
resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.name_prefix}-web"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = true

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Token validity
  access_token_validity  = 1  # hours
  id_token_validity      = 1  # hours
  refresh_token_validity = 30 # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}

# Cognito groups -- mirrors Entra ID app roles
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Full administrative access"
}

resource "aws_cognito_user_group" "user" {
  name         = "user"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Standard read-only access"
}

# Store secrets in Secrets Manager
resource "aws_secretsmanager_secret" "cognito_client_id" {
  name                    = "${local.name_prefix}/cognito-client-id"
  description             = "Cognito app client ID"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-cognito-client-id" }
}

resource "aws_secretsmanager_secret_version" "cognito_client_id" {
  secret_id     = aws_secretsmanager_secret.cognito_client_id.id
  secret_string = aws_cognito_user_pool_client.web.id
}

resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name                    = "${local.name_prefix}/cognito-client-secret"
  description             = "Cognito app client secret"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-cognito-client-secret" }
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.web.client_secret
}

resource "aws_secretsmanager_secret" "nextauth_secret" {
  name                    = "${local.name_prefix}/nextauth-secret"
  description             = "NextAuth.js session encryption secret"
  recovery_window_in_days = 7

  tags = { Name = "${local.name_prefix}-nextauth-secret" }
}

resource "aws_secretsmanager_secret_version" "nextauth_secret" {
  secret_id     = aws_secretsmanager_secret.nextauth_secret.id
  secret_string = random_password.nextauth_secret.result
}

resource "random_password" "nextauth_secret" {
  length  = 64
  special = true
}
