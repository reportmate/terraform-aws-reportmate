#!/bin/bash

# ReportMate Custom Domain Setup Script
# This script configures a custom domain for the ReportMate frontend Container App

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="ReportMate"
CONTAINER_APP_NAME="reportmate-frontend-prod"
CUSTOM_DOMAIN="reportmate.ecuad.ca"

echo -e "${YELLOW}🌐 ReportMate Custom Domain Setup${NC}"
echo "=================================="

# Check if we're logged into Azure
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}❌ Please login to Azure first: az login${NC}"
    exit 1
fi

# Get current container app FQDN
echo -e "${YELLOW}📋 Getting current Container App FQDN...${NC}"
CURRENT_FQDN=$(az containerapp show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv 2>/dev/null)

if [ -z "$CURRENT_FQDN" ]; then
    echo -e "${RED}❌ Container App not found or not deployed${NC}"
    echo "Make sure you've deployed the infrastructure first:"
    echo "  cd infrastructure && terraform apply"
    exit 1
fi

echo -e "${GREEN}✅ Current FQDN: $CURRENT_FQDN${NC}"

# Check current DNS configuration
echo -e "${YELLOW}🔍 Checking current DNS configuration...${NC}"
CURRENT_DNS=$(dig +short $CUSTOM_DOMAIN CNAME | sed 's/\.$//')

if [ "$CURRENT_DNS" != "$CURRENT_FQDN" ]; then
    echo -e "${YELLOW}⚠️  DNS mismatch detected:${NC}"
    echo "  Current CNAME: $CURRENT_DNS"
    echo "  Should point to: $CURRENT_FQDN"
    echo ""
    echo -e "${YELLOW}📝 Please update your DNS CNAME record:${NC}"
    echo "  Name: reportmate"
    echo "  Type: CNAME"
    echo "  Value: $CURRENT_FQDN"
    echo ""
    read -p "Press Enter after updating DNS to continue..."
fi

# Verify DNS propagation
echo -e "${YELLOW}⏳ Verifying DNS propagation...${NC}"
for i in {1..30}; do
    CURRENT_DNS=$(dig +short $CUSTOM_DOMAIN CNAME | sed 's/\.$//')
    if [ "$CURRENT_DNS" = "$CURRENT_FQDN" ]; then
        echo -e "${GREEN}✅ DNS propagation verified${NC}"
        break
    fi
    echo "  Attempt $i/30: Waiting for DNS propagation..."
    sleep 10
done

if [ "$CURRENT_DNS" != "$CURRENT_FQDN" ]; then
    echo -e "${RED}❌ DNS not propagated yet. Please wait and try again.${NC}"
    exit 1
fi

# Check if custom domain is already configured
echo -e "${YELLOW}🔍 Checking current custom domain configuration...${NC}"
EXISTING_DOMAIN=$(az containerapp hostname list \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "[?name=='$CUSTOM_DOMAIN'].name" \
    --output tsv 2>/dev/null)

if [ "$EXISTING_DOMAIN" = "$CUSTOM_DOMAIN" ]; then
    echo -e "${GREEN}✅ Custom domain already configured${NC}"
    exit 0
fi

# Add custom domain
echo -e "${YELLOW}🌐 Adding custom domain to Container App...${NC}"
az containerapp hostname add \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --hostname $CUSTOM_DOMAIN

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Custom domain configured successfully!${NC}"
    echo ""
    echo -e "${GREEN}🎉 Your application is now available at:${NC}"
    echo "  https://$CUSTOM_DOMAIN"
    echo ""
    echo -e "${YELLOW}📝 Note: SSL certificate provisioning may take a few minutes.${NC}"
else
    echo -e "${RED}❌ Failed to configure custom domain${NC}"
    exit 1
fi

# Verify the configuration
echo -e "${YELLOW}🔍 Verifying configuration...${NC}"
sleep 10
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://$CUSTOM_DOMAIN

echo -e "${GREEN}✅ Setup complete!${NC}"
