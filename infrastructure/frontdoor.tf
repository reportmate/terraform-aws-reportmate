# Azure Front Door for stable custom domain
# This provides a stable endpoint that routes traffic to the Container App
# Eliminates the need to update CNAME records when Container Apps are redeployed

resource "azurerm_cdn_frontdoor_profile" "main" {
  count               = var.enable_custom_domain && var.custom_domain_name != "" ? 1 : 0
  name                = "reportmate-frontdoor"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = {
    Environment = var.environment
    LastDeployment = formatdate("YYYY-MM-DD-hhmm", timestamp())
  }
}

# Frontend origin group for Container Apps
resource "azurerm_cdn_frontdoor_origin_group" "frontend" {
  name                     = "frontend-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  health_probe {
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
    interval_in_seconds = 60
  }

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

# Frontend origin pointing to Container App
resource "azurerm_cdn_frontdoor_origin" "frontend" {
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.frontend.id
  name                            = "frontend-origin"
  host_name                       = azurerm_container_app.frontend_prod[0].latest_revision_fqdn
  origin_host_header              = azurerm_container_app.frontend_prod[0].latest_revision_fqdn
  https_port                      = 443
  certificate_name_check_enabled  = true
}

# Custom domain endpoint
resource "azurerm_cdn_frontdoor_endpoint" "frontend" {
  name                     = "reportmate-frontend"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  
  tags = {
    Environment = var.environment
    DeploymentTrigger = formatdate("YYYY-MM-DD-hhmm", timestamp())
  }
}

# Custom domain
resource "azurerm_cdn_frontdoor_custom_domain" "frontend" {
  name                     = "reportmate-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  host_name                = var.custom_domain_name

  tls {
    certificate_type = "ManagedCertificate"
  }
}

# Default route for all traffic
resource "azurerm_cdn_frontdoor_route" "frontend_default" {
  name                             = "frontend-default-route"
  cdn_frontdoor_endpoint_id        = azurerm_cdn_frontdoor_endpoint.frontend.id
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.frontend.id
  cdn_frontdoor_origin_ids         = [azurerm_cdn_frontdoor_origin.frontend.id]
  cdn_frontdoor_custom_domain_ids  = [azurerm_cdn_frontdoor_custom_domain.frontend.id]
  patterns_to_match                = ["/*"]
  supported_protocols              = ["Http", "Https"]
  forwarding_protocol              = "HttpsOnly"
  https_redirect_enabled           = true
  link_to_default_domain           = true
  enabled                          = true
}


