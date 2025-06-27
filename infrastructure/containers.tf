# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "reportmateacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false  # Use managed identity instead of admin credentials
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "reportmate-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                = "reportmate-env"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  depends_on = [
    azurerm_log_analytics_workspace.logs
  ]
}

# Development Frontend Container App
resource "azurerm_container_app" "frontend_dev" {
  count                        = var.deploy_dev || var.environment == "dev" || var.environment == "both" ? 1 : 0
  name                         = "reportmate-frontend-dev"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # Assign managed identity to Container App
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/reportmate-frontend:${var.frontend_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NODE_ENV"
        value = "development"
      }

      env {
        name  = "NEXT_PUBLIC_WPS_URL"
        value = "wss://${azurerm_web_pubsub.wps.hostname}/client/hubs/events"
      }

      env {
        name  = "NEXT_PUBLIC_ENABLE_SIGNALR"
        value = "true"
      }

      env {
        name  = "NEXT_PUBLIC_API_BASE_URL"
        value = "https://${azurerm_linux_function_app.func.default_hostname}"
      }

      # Development-specific environment variables
      env {
        name  = "NEXT_PUBLIC_DEBUG"
        value = "true"
      }
    }

    min_replicas = 0  # Allow scaling to zero for dev
    max_replicas = 2  # Lower max replicas for dev
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Use managed identity for ACR authentication
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.main.id
  }

  # Always use latest image - don't track image changes in Terraform
  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].revision_suffix
    ]
  }

  tags = {
    Environment = "development"
  }
}

# Production Frontend Container App
resource "azurerm_container_app" "frontend_prod" {
  count                        = var.deploy_prod || var.environment == "prod" || var.environment == "both" ? 1 : 0
  name                         = "reportmate-frontend-prod"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # Assign managed identity to Container App
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/reportmate-frontend:${var.frontend_image_tag}"
      cpu    = 0.5   # More CPU for production
      memory = "1Gi" # More memory for production

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "NEXT_PUBLIC_WPS_URL"
        value = "wss://${azurerm_web_pubsub.wps.hostname}/client/hubs/events"
      }

      env {
        name  = "NEXT_PUBLIC_ENABLE_SIGNALR"
        value = "true"
      }

      env {
        name  = "NEXT_PUBLIC_API_BASE_URL"
        value = "https://${azurerm_linux_function_app.func.default_hostname}"
      }
    }

    min_replicas = 1  # Always keep at least one instance for prod
    max_replicas = 5  # Higher max replicas for prod
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Use managed identity for ACR authentication
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.main.id
  }

  # Always use latest image - don't track image changes in Terraform
  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].revision_suffix
    ]
  }

  tags = {
    Environment = "production"
  }
}

# Custom domain will be configured directly in the container app ingress configuration
# Azure will automatically provision a managed certificate when the custom domain is added
