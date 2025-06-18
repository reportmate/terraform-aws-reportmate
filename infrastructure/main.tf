# Core infra
resource "azurerm_resource_group" "rg" {
  name     = "Seemianki"
  location = "Canada Central"
  tags = {
    GitOps = "Terraformed"
  }
}

# Storage account + queue
resource "azurerm_storage_account" "seemianki" {
  name                     = "seemiankistorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "ingest" {
  name                 = "osquery-ingest"
  storage_account_name = azurerm_storage_account.seemianki.name
}

# Web PubSub (SignalR)
resource "azurerm_web_pubsub" "wps" {
  name                = "seemianki-signalr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_S1"
  capacity            = 1
  public_network_access_enabled = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "seemianki-database"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  administrator_login    = var.db_username
  administrator_password = var.db_password

  version                = "16"
  storage_mb             = 32768
  zone                   = "1"  # Use zone 1 for Canada Central
  sku_name               = "B_Standard_B1ms"
  public_network_access_enabled = true

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name              = "allow_azure"
  server_id         = azurerm_postgresql_flexible_server.pg.id
  start_ip_address  = "0.0.0.0"
  end_ip_address    = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "seemianki"
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "seemianki-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Linux Function App
resource "azurerm_service_plan" "plan" {
  name                = "seemianki-functions"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "func" {
  name                       = "seemianki-api"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.seemianki.name
  storage_account_access_key = azurerm_storage_account.seemianki.primary_access_key

  site_config {
    application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME               = "python"
    WEBSITE_RUN_FROM_PACKAGE               = "1"
    AZURE_STORAGE_CONNECTION_STRING        = azurerm_storage_account.seemianki.primary_connection_string
    QUEUE_NAME                             = azurerm_storage_queue.ingest.name
    DATABASE_URL                           = "postgresql://${var.db_username}:${var.db_password}@${azurerm_postgresql_flexible_server.pg.fqdn}:5432/${azurerm_postgresql_flexible_server_database.db.name}?sslmode=require"
    EVENTS_CONNECTION                      = azurerm_web_pubsub.wps.primary_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY         = azurerm_application_insights.ai.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING  = azurerm_application_insights.ai.connection_string
    APPINSIGHTS_CONNECTION_STRING          = azurerm_application_insights.ai.connection_string
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"],
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"],
      app_settings["APPINSIGHTS_CONNECTION_STRING"]
    ]
  }
}

# Outputs
output "function_app_url" {
  value = "https://${azurerm_linux_function_app.func.default_hostname}"
}

output "postgres_connection" {
  value       = "postgresql://${var.db_username}:${var.db_password}@${azurerm_postgresql_flexible_server.pg.fqdn}:5432/${azurerm_postgresql_flexible_server_database.db.name}"
  sensitive   = true
}

output "web_pubsub_endpoint" {
  value = azurerm_web_pubsub.wps.hostname
}

# Optionally allow your local IP for dev access:
# variable "my_ip" {
#   description = "Public IP for local dev box"
#   type        = string
#   default     = "203.0.113.27"   # replace with your IP
# }
#
# resource "azurerm_postgresql_flexible_server_firewall_rule" "me" {
#   name              = "allow_me"
#   server_id         = azurerm_postgresql_flexible_server.pg.id
#   start_ip_address  = var.my_ip
#   end_ip_address    = var.my_ip
# }
