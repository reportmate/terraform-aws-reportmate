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

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                          = "reportmate-frontend"
  container_app_environment_id  = azurerm_container_app_environment.env.id
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
      # TODO: Replace with actual image after building and pushing to ACR
      # image  = "reportmateacr.azurecr.io/reportmate-frontend:${var.frontend_image_tag}"
      image  = "mcr.microsoft.com/hello-world:latest"
      cpu    = 0.25
      memory = "0.5Gi"

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

    min_replicas = 1
    max_replicas = 3
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
}

# Custom domain will be configured directly in the container app ingress configuration
# Azure will automatically provision a managed certificate when the custom domain is added

# Outputs for Container Registry
output "container_registry_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.main.principal_id
}

output "frontend_url" {
  value = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
}
