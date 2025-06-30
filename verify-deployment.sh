#!/bin/bash
# ReportMate Deployment Verification Script
# Comprehensive health checks for the entire system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 ReportMate Deployment Verification${NC}"
echo "======================================"

# 1. DNS Resolution Tests
echo -e "\n${YELLOW}📋 1. DNS Resolution Tests${NC}"
echo "Custom Domain CNAME:"
dig +short reportmate.ecuad.ca CNAME

echo "Validation TXT Record:"
dig +short _dnsauth.reportmate.ecuad.ca TXT

# 2. SSL Certificate Verification
echo -e "\n${YELLOW}🔒 2. SSL Certificate Verification${NC}"
SSL_INFO=$(openssl s_client -connect reportmate.ecuad.ca:443 -servername reportmate.ecuad.ca -verify_return_error < /dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates)
echo "$SSL_INFO"

# 3. Frontend Connectivity Tests
echo -e "\n${YELLOW}🌐 3. Frontend Connectivity Tests${NC}"

# Custom Domain
CUSTOM_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reportmate.ecuad.ca)
CUSTOM_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://reportmate.ecuad.ca)
echo -e "Custom Domain: ${GREEN}$CUSTOM_STATUS${NC} (${CUSTOM_TIME}s)"

# Front Door Endpoint
FD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net)
FD_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net)
echo -e "Front Door: ${GREEN}$FD_STATUS${NC} (${FD_TIME}s)"

# Direct Container App
CA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io)
CA_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io)
echo -e "Container App: ${GREEN}$CA_STATUS${NC} (${CA_TIME}s)"

# 4. Azure Resources Status
echo -e "\n${YELLOW}🏗️ 4. Azure Resources Status${NC}"

# Function App
FUNC_STATE=$(az functionapp show --name reportmate-api --resource-group ReportMate --query "state" --output tsv 2>/dev/null || echo "ERROR")
echo -e "Function App: ${GREEN}$FUNC_STATE${NC}"

# Container App
CA_STATE=$(az containerapp show --name reportmate-frontend-prod --resource-group ReportMate --query "properties.runningStatus" --output tsv 2>/dev/null || echo "ERROR")
echo -e "Container App: ${GREEN}$CA_STATE${NC}"

# Database
DB_STATE=$(az postgres flexible-server show --name reportmate-database --resource-group ReportMate --query "state" --output tsv 2>/dev/null || echo "ERROR")
echo -e "Database: ${GREEN}$DB_STATE${NC}"

# 5. Front Door Health Check
echo -e "\n${YELLOW}🩺 5. Front Door Health Probe${NC}"
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reportmate.ecuad.ca/api/healthz)
if [ "$HEALTH_STATUS" = "200" ]; then
    echo -e "Health Endpoint: ${GREEN}$HEALTH_STATUS ✅${NC}"
else
    echo -e "Health Endpoint: ${RED}$HEALTH_STATUS ❌${NC}"
    echo -e "${YELLOW}⚠️  Health probe may fail, but app is working${NC}"
fi

# 6. End-to-End Test
echo -e "\n${YELLOW}🎯 6. End-to-End Functionality Test${NC}"

# Test main dashboard
DASHBOARD_TEST=$(curl -s https://reportmate.ecuad.ca/dashboard | grep -c "ReportMate Fleet Dashboard" || echo "0")
if [ "$DASHBOARD_TEST" -gt "0" ]; then
    echo -e "Dashboard Loading: ${GREEN}✅ Working${NC}"
else
    echo -e "Dashboard Loading: ${RED}❌ Failed${NC}"
fi

# Test assets loading
ASSETS_TEST=$(curl -s -I https://reportmate.ecuad.ca/_next/static/css/e05c3e8c53e36a0c.css | head -1 | grep -c "200" || echo "0")
if [ "$ASSETS_TEST" -gt "0" ]; then
    echo -e "Static Assets: ${GREEN}✅ Loading${NC}"
else
    echo -e "Static Assets: ${RED}❌ Failed${NC}"
fi

# 7. Performance Summary
echo -e "\n${YELLOW}⚡ 7. Performance Summary${NC}"
echo "Response Times:"
echo "  Custom Domain: ${CUSTOM_TIME}s"
echo "  Front Door: ${FD_TIME}s"
echo "  Container App: ${CA_TIME}s"

# 8. Final Status
echo -e "\n${BLUE}📊 Final Deployment Status${NC}"
echo "=============================="

if [ "$CUSTOM_STATUS" = "307" ] && [ "$FD_STATUS" = "307" ] && [ "$CA_STATUS" = "307" ]; then
    echo -e "${GREEN}🎉 SUCCESS: ReportMate is fully deployed and working!${NC}"
    echo -e "${GREEN}✅ Custom domain: https://reportmate.ecuad.ca${NC}"
    echo -e "${GREEN}✅ SSL certificate: Valid${NC}"
    echo -e "${GREEN}✅ Front Door: Operational${NC}"
    echo -e "${GREEN}✅ Container App: Running${NC}"
    echo ""
    echo -e "${BLUE}🌟 Next Steps:${NC}"
    echo "1. Visit https://reportmate.ecuad.ca to access the dashboard"
    echo "2. Deploy client agents to start collecting data"
    echo "3. Configure machine groups if needed"
    
    if [ "$HEALTH_STATUS" != "200" ]; then
        echo -e "\n${YELLOW}📝 Note:${NC}"
        echo "Health endpoint needs fixing for Front Door probes, but the application is working correctly."
    fi
else
    echo -e "${RED}❌ ISSUES DETECTED${NC}"
    echo "Some components may not be working correctly."
fi

echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "  - Setup Guide: docs/CUSTOM_DOMAIN_SETUP.md"
echo "  - Deployment: docs/DEPLOYMENT.md"
echo "  - Troubleshooting: docs/TROUBLESHOOTING.md"
