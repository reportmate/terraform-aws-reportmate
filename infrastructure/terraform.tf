terraform {
  required_version = ">= 1.12.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.33.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "Terraform"
    storage_account_name = "ecuadgitopsterraform"
    container_name       = "terraform-state"
    key                  = "seemianki.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "59d35012-b593-4b2f-bd50-28e666ed12f7"
}

# Azure Flexible Server wants user@server for non-AAD logins
locals {
  pg_username = "${var.db_username}@${azurerm_postgresql_flexible_server.pg.name}"
}

provider "postgresql" {
  host            = azurerm_postgresql_flexible_server.pg.fqdn
  port            = 5432
  database        = azurerm_postgresql_flexible_server_database.db.name
  username        = local.pg_username
  password        = var.db_password
  sslmode         = "require"
}
