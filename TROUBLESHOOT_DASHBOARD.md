# Dashboard Not Loading - Troubleshooting Guide

## Issue Description
The dashboard at `https://reportmate.ecuad.ca` is not loading correctly or showing an outdated version, while the direct container URL works fine.

## Root Cause Analysis
The primary issue identified was **Azure Front Door caching configuration** causing stale content to be served to the custom domain. The container app itself is working correctly.

### Key Problems Identified:
1. **Aggressive Front Door caching** - Dynamic content like `/dashboard` was being cached
2. **No cache differentiation** - All routes were using the same caching rules
3. **localStorage SSR issues** - Server-side rendering errors with browser-only APIs (fixed in latest deployment)

## Front Door Caching Issue (RESOLVED)

### Problem
Azure Front Door was caching dynamic dashboard content, causing users to see stale versions even after container app updates.

### Solution Applied
Updated Terraform configuration in `infrastructure/frontdoor.tf` to implement proper caching rules:

1. **Dynamic Content** (`/dashboard`, `/api/*`) - No caching with explicit cache-control headers
2. **Static Assets** (`/_next/static/*`, `/images/*`) - Long-term caching for performance  
3. **Default Routes** - Minimal caching for other content

### Key Configuration Changes:
```terraform
# Added rule set for cache control
resource "azurerm_cdn_frontdoor_rule_set" "main"

# Separate routes for different content types:
# - frontend_dynamic: No caching for dashboard/API
# - frontend_static: Long cache for static assets  
# - frontend_default: Minimal cache for other content
```

## Possible Causes & Solutions

### 1. Container App Status
Check if the container app is running:

```bash
# Check container app status
az containerapp show --name reportmate-frontend-dev --resource-group <resource-group-name> --query "properties.runningStatus"

# Check container app logs
az containerapp logs show --name reportmate-frontend-dev --resource-group <resource-group-name> --follow
```

### 2. Domain Configuration
Verify the custom domain is properly configured:

```bash
# Check custom domain configuration
az containerapp hostname list --name reportmate-frontend-dev --resource-group <resource-group-name>
```

### 3. Build and Deployment Issues
Check if the latest deployment was successful:

```bash
# Check revision status
az containerapp revision list --name reportmate-frontend-dev --resource-group <resource-group-name> --query "[].{name:name,active:properties.active,trafficWeight:properties.trafficWeight}"
```

### 4. Environment Variables
Ensure required environment variables are set:

```bash
# Check environment variables
az containerapp show --name reportmate-frontend-dev --resource-group <resource-group-name> --query "properties.template.containers[0].env"
```

### 5. Container Registry Access
Verify the container app can pull images:

```bash
# Check if managed identity has ACR pull permissions
az role assignment list --assignee <managed-identity-principal-id> --scope <acr-resource-id>
```

## Quick Fixes

### Option 1: Restart the Container App
```bash
az containerapp restart --name reportmate-frontend-dev --resource-group <resource-group-name>
```

### Option 2: Force New Deployment
```bash
# Trigger a new deployment with azd
azd deploy
```

### Option 3: Check Container Health
```bash
# Access container app directly (without custom domain)
az containerapp show --name reportmate-frontend-dev --resource-group <resource-group-name> --query "properties.configuration.ingress.fqdn"
```

## Emergency Fallback: Use Local Development
If the production site is critical and needs immediate access:

```bash
cd /Users/rod/DevOps/ReportMate/apps/www
pnpm dev
# Access at http://localhost:3000
```

## Next Steps
1. Run the diagnostic commands above to identify the specific issue
2. Check Azure portal for any alerts or failed deployments
3. Review container app logs for error messages
4. Verify DNS settings for the custom domain
5. Ensure SSL certificate is valid and properly configured

## Configuration Notes
- ✅ Next.js config is correct for container deployment
- ✅ Dockerfile uses standalone mode with API routes
- ✅ Azure configuration uses Container Apps (not static hosting)
- ✅ Local development server works correctly

The issue is likely in the Azure deployment, not the application code.
