# Front Door Container Stability Configuration

## Overview
This document outlines how Azure Front Door ensures stable routing to Container Apps even when containers are updated or redeployed.

## Key Components

### 1. Front Door Profile
- **Resource**: `azurerm_cdn_frontdoor_profile.main`
- **SKU**: Standard_AzureFrontDoor
- **Purpose**: Provides the core Front Door service with global load balancing and CDN capabilities

### 2. Origin Configuration
The Front Door origin is dynamically configured to point to the Container App FQDN:

```hcl
resource "azurerm_cdn_frontdoor_origin" "frontend" {
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.frontend.id
  name                            = "frontend-origin"
  host_name                       = azurerm_container_app.frontend_prod[0].ingress[0].fqdn
  origin_host_header              = azurerm_container_app.frontend_prod[0].ingress[0].fqdn
  https_port                      = 443
  certificate_name_check_enabled  = true
}
```

**Key Point**: The `host_name` and `origin_host_header` are automatically set to the Container App's FQDN via Terraform reference. This means:
- When Container Apps are redeployed, their FQDN stays the same
- Terraform automatically tracks any FQDN changes and updates Front Door accordingly
- No manual DNS updates or routing changes are needed

### 3. Health Probe Configuration
```hcl
health_probe {
  path                = "/"
  protocol            = "Https"
  request_type        = "HEAD"
  interval_in_seconds = 60
}
```

This ensures Front Door can detect when the container is healthy and ready to receive traffic.

### 4. Custom Domain Routing
- **Domain**: reportmate.ecuad.ca
- **CNAME**: Points to `reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net`
- **Certificate**: Managed automatically by Azure Front Door

## Stability Features

### 1. Automatic FQDN Resolution
- Container App FQDN: `reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io`
- This FQDN remains stable across container updates and redeploys
- Front Door automatically routes to this stable endpoint

### 2. Load Balancing Configuration
```hcl
load_balancing {
  sample_size                 = 4
  successful_samples_required = 3
}
```

Ensures traffic only goes to healthy instances during updates.

### 3. Lifecycle Management
```hcl
lifecycle {
  ignore_changes = [
    container_app_environment_id  # Ignore changes due to Azure API cache
  ]
}
```

Prevents unnecessary resource recreation due to Azure API caching issues.

## Update Process

### When Containers Are Updated:
1. **Container App Redeploy**: New container image is deployed to the same Container App resource
2. **FQDN Stability**: The Container App FQDN remains the same
3. **Front Door Routing**: No changes needed - Front Door continues routing to the stable FQDN
4. **Health Checks**: Front Door validates the new container is healthy before routing traffic
5. **Zero Downtime**: Traffic seamlessly flows to the updated container

### When Infrastructure Changes Are Made:
1. **Terraform Plan**: Shows any changes needed to Front Door configuration
2. **Terraform Apply**: Updates Front Door configuration if Container App FQDN changes
3. **Automatic DNS**: Custom domain routing remains stable through Front Door endpoint

## Testing Stability

### Verified Endpoints:
- **Website**: https://reportmate.ecuad.ca ✅
- **Device API**: https://reportmate.ecuad.ca/api/device ✅
- **Events API**: https://reportmate.ecuad.ca/api/events ✅
- **Registration Enforcement**: Unregistered devices blocked ✅

### Connection Flow:
```
reportmate.ecuad.ca (Custom Domain)
    ↓ (CNAME)
Front Door Endpoint (reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net)
    ↓ (Origin Routing)
Container App FQDN (reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io)
    ↓ (Container Ingress)
Next.js Application (Port 3000)
```

## Monitoring and Troubleshooting

### Key Terraform Outputs:
- `container_app_fqdn`: Shows current Container App FQDN
- `frontdoor_endpoint`: Shows Front Door endpoint URL
- `frontend_url`: Shows final custom domain URL

### Health Check Commands:
```powershell
# Test custom domain
curl https://reportmate.ecuad.ca/api/device

# Test Front Door directly
curl https://reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net/api/device

# Test Container App directly
curl https://reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io/api/device
```

## Security Features

### HTTPS Enforcement:
- `forwarding_protocol = "HttpsOnly"`
- `https_redirect_enabled = true`
- Managed certificate for custom domain

### Certificate Management:
- Azure-managed certificate for reportmate.ecuad.ca
- Automatic renewal and validation

## Summary

The Front Door configuration ensures:
1. **Stable Custom Domain**: reportmate.ecuad.ca always works
2. **Automatic Routing**: No manual updates needed when containers are redeployed
3. **Health Monitoring**: Traffic only goes to healthy containers
4. **Zero Downtime**: Seamless updates without service interruption
5. **HTTPS Security**: All traffic encrypted with managed certificates

The key to stability is using Terraform references (`azurerm_container_app.frontend_prod[0].ingress[0].fqdn`) rather than hardcoded values, ensuring Front Door automatically tracks Container App changes.
