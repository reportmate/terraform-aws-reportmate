#!/bin/bash

# Reportmate Unified Deployment Script
# Run this script to deploy infrastructure and applications to Azure

set -e  # Exit on any error

# =================================================================
# CONFIGURATION & COLORS
# =================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Environment variables with defaults
RESOURCE_GROUP="rg-reportmate-prod"
LOCATION="Canada Central"
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}
IMAGE_TAG=${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}

# Deployment control flags
DEPLOY_INFRA=${DEPLOY_INFRA:-true}
DEPLOY_CONTAINERS=${DEPLOY_CONTAINERS:-true}
SETUP_DATABASE=${SETUP_DATABASE:-true}
RUN_TESTS=${RUN_TESTS:-true}

# Detect pipeline mode (CI/CD environment)
PIPELINE_MODE=false
if [ ! -z "$GITHUB_ACTIONS" ] || [ ! -z "$AZURE_PIPELINES" ] || [ ! -z "$CI" ]; then
    PIPELINE_MODE=true
    RUN_TESTS=false  # Skip interactive tests in CI/CD
    SETUP_DATABASE=false  # Skip database setup in CI/CD
fi

# Azure authentication
TENANT_ID=${AZURE_TENANT_ID:-}
CLIENT_ID=${AZURE_CLIENT_ID:-}
CLIENT_SECRET=${AZURE_CLIENT_SECRET:-}

echo -e "${GREEN}🚀 Reportmate Unified Deployment${NC}"
echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Image Tag: $IMAGE_TAG"
echo "  Pipeline Mode: $PIPELINE_MODE"
echo "  Deploy Infrastructure: $DEPLOY_INFRA"
echo "  Deploy Containers: $DEPLOY_CONTAINERS"
echo "  Setup Database: $SETUP_DATABASE"

# =================================================================
# FUNCTIONS
# =================================================================

check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install the missing tools before proceeding.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check complete${NC}"
}

authenticate_azure() {
    echo -e "${YELLOW}🔑 Authenticating with Azure...${NC}"
    
    if [ "$PIPELINE_MODE" = false ]; then
        # Interactive login for local development
        if ! az account show &> /dev/null; then
            echo -e "${BLUE}Please login to Azure:${NC}"
            az login --tenant "$TENANT_ID"
        fi
        
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        echo "  Subscription: $SUBSCRIPTION_ID"
        echo "  Tenant: $TENANT_ID"
    else
        # Service principal login for CI/CD
        echo -e "${BLUE}Using service principal authentication...${NC}"
        az login --service-principal \
            --username "$CLIENT_ID" \
            --password "$CLIENT_SECRET" \
            --tenant "$TENANT_ID"
    fi
    
    echo -e "${GREEN}✅ Azure authentication complete${NC}"
}

deploy_infrastructure() {
    if [ "$DEPLOY_INFRA" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping infrastructure deployment${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🏗️  Deploying infrastructure with Terraform...${NC}"
    
    cd infrastructure
    
    # Initialize Terraform
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init
    
    # Validate configuration
    echo -e "${BLUE}Validating Terraform configuration...${NC}"
    terraform validate
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terraform validation failed${NC}"
        exit 1
    fi
    
    # Plan deployment
    echo -e "${BLUE}Planning Terraform deployment...${NC}"
    terraform plan \
        -var="db_password=$DB_PASSWORD" \
        -var="enable_pipeline_permissions=$PIPELINE_MODE" \
        -var="pipeline_service_principal_id=${AZURE_CLIENT_ID:-}" \
        -out=tfplan
    
    # Apply infrastructure
    echo -e "${YELLOW}🚀 Applying Terraform plan...${NC}"
    terraform apply -auto-approve tfplan
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terraform deployment failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    cd ..
}

get_infrastructure_outputs() {
    echo -e "${YELLOW}📋 Getting infrastructure outputs...${NC}"
    
    cd infrastructure
    
    # Get outputs with fallbacks
    ACR_NAME=$(terraform output -raw container_registry_login_server 2>/dev/null | cut -d'.' -f1 || echo "reportmateacr")
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server 2>/dev/null || echo "reportmateacr.azurecr.io")
    FUNCTION_APP_URL=$(terraform output -raw function_app_url 2>/dev/null || echo "")
    FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "")
    WEB_PUBSUB_ENDPOINT=$(terraform output -raw web_pubsub_endpoint 2>/dev/null || echo "")
    DB_CONNECTION=$(terraform output -raw postgres_connection 2>/dev/null || echo "")
    
    echo "  ACR: $ACR_LOGIN_SERVER"
    echo "  Function App: $FUNCTION_APP_URL"
    echo "  Frontend: $FRONTEND_URL"
    echo "  WebPubSub: $WEB_PUBSUB_ENDPOINT"
    
    cd ..
}

build_and_push_containers() {
    if [ "$DEPLOY_CONTAINERS" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping container deployment${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🐳 Building and pushing containers...${NC}"
    
    # Login to ACR (skip in pipeline if already authenticated)
    if [ "$PIPELINE_MODE" = false ]; then
        echo -e "${YELLOW}� Authenticating with Azure Container Registry...${NC}"
        az acr login --name $ACR_NAME
    fi
    
    # Build and push frontend
    echo -e "${YELLOW}�️  Building frontend container...${NC}"
    cd apps/www
    
    docker build \
        --platform linux/amd64 \
        -t reportmate-frontend:$IMAGE_TAG \
        --build-arg DOCKER_BUILD=true \
        .
    
    docker tag reportmate-frontend:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-frontend:$IMAGE_TAG
    
    echo -e "${YELLOW}📤 Pushing frontend to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate-frontend:$IMAGE_TAG
    
    cd ../..
    
    # Build and push functions
    echo -e "${YELLOW}🏗️  Building functions container...${NC}"
    cd functions
    
    docker build \
        --platform linux/amd64 \
        -t reportmate-functions:$IMAGE_TAG \
        .
    
    docker tag reportmate-functions:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    
    echo -e "${YELLOW}📤 Pushing functions to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    
    cd ..
    
    echo -e "${GREEN}✅ Containers built and pushed successfully!${NC}"
}

update_container_apps() {
    if [ "$DEPLOY_CONTAINERS" != true ]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔄 Updating container apps with new images...${NC}"
    
    cd infrastructure
    terraform apply \
        -var="frontend_image_tag=$IMAGE_TAG" \
        -var="functions_image_tag=$IMAGE_TAG" \
        -var="db_password=$DB_PASSWORD" \
        -auto-approve
    cd ..
    
    echo -e "${GREEN}✅ Container apps updated!${NC}"
}

setup_database() {
    if [ "$SETUP_DATABASE" != true ] || [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}⏭️  Skipping database setup${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🗄️  Setting up database...${NC}"
    
    if [ -f scripts/setup-database.sh ] && [ -n "$DB_CONNECTION" ]; then
        export DATABASE_URL="$DB_CONNECTION"
        ./scripts/setup-database.sh
        echo -e "${GREEN}✅ Database setup complete!${NC}"
    else
        echo -e "${YELLOW}⚠️  Database setup script not found or no connection string${NC}"
    fi
}

run_deployment_tests() {
    if [ "$RUN_TESTS" != true ] || [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}⏭️  Skipping deployment tests${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🧪 Running deployment tests...${NC}"
    
    if [ -n "$FUNCTION_APP_URL" ]; then
        echo -e "${BLUE}Testing negotiate endpoint...${NC}"
        
        # Wait for function app to warm up
        sleep 30
        
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_APP_URL/api/negotiate?device=deployment-test" || echo "000")
        
        if [ "$HTTP_STATUS" = "200" ]; then
            echo -e "${GREEN}✅ Negotiate endpoint is working!${NC}"
        else
            echo -e "${YELLOW}⚠️  Negotiate endpoint returned status: $HTTP_STATUS${NC}"
            echo -e "${YELLOW}   Functions may still be warming up${NC}"
        fi
        
        # Test ingest endpoint
        echo -e "${BLUE}Testing ingest endpoint...${NC}"
        curl -X POST "$FUNCTION_APP_URL/api/ingest" \
            -H "Content-Type: application/json" \
            -d "{
                \"device\": \"deployment-test\",
                \"kind\": \"deployment_verification\",
                \"payload\": {
                    \"message\": \"Deployment test successful\",
                    \"timestamp\": \"$(date -Iseconds)\"
                }
            }" -w "\nHTTP Status: %{http_code}\n" || echo "Test request failed"
    fi
}

display_summary() {
    echo ""
    echo -e "${GREEN}🎉 Deployment Complete!${NC}"
    echo ""
    echo -e "${BLUE}� Deployment Summary:${NC}"
    echo "  ✅ Resource Group: $RESOURCE_GROUP"
    echo "  ✅ Image Tag: $IMAGE_TAG"
    
    if [ -n "$FUNCTION_APP_URL" ]; then
        echo "  ✅ Function App: $FUNCTION_APP_URL"
    fi
    
    if [ -n "$FRONTEND_URL" ]; then
        echo "  ✅ Frontend: $FRONTEND_URL"
    fi
    
    if [ -n "$WEB_PUBSUB_ENDPOINT" ]; then
        echo "  ✅ WebPubSub: wss://$WEB_PUBSUB_ENDPOINT/client/hubs/events"
    fi
    
    if [ -n "$ACR_LOGIN_SERVER" ]; then
        echo "  ✅ Container Registry: $ACR_LOGIN_SERVER"
    fi
    
    echo ""
    echo -e "${YELLOW}� Next Steps:${NC}"
    echo "  1. Monitor deployment in Azure Portal"
    echo "  2. Set up alerts and monitoring"
    echo "  3. Configure custom domains if needed"
    echo "  4. Set up CI/CD pipeline for future deployments"
    echo ""
    
    if [ "$PIPELINE_MODE" = false ]; then
        echo -e "${BLUE}💾 Save these credentials securely:${NC}"
        echo "  Database Password: ${DB_PASSWORD:0:8}..."
        echo ""
    fi
    
    echo -e "${GREEN}🚀 Your real-time security events dashboard is now live!${NC}"
}

# =================================================================
# MAIN EXECUTION
# =================================================================

main() {
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Reportmate Unified Deployment Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Environment Variables:"
        echo "  DEPLOY_INFRA=false          Skip infrastructure deployment"
        echo "  DEPLOY_CONTAINERS=false     Skip container deployment"
        echo "  SETUP_DATABASE=false        Skip database setup"
        echo "  RUN_TESTS=false             Skip deployment tests"
        echo "  DB_PASSWORD=<password>      Custom database password"
        echo ""
        echo "Examples:"
        echo "  $0                          # Full deployment"
        echo "  DEPLOY_INFRA=false $0       # Skip infrastructure, only containers"
        echo "  DEPLOY_CONTAINERS=false $0  # Only deploy infrastructure"
        exit 0
    fi
    
    # Execute deployment steps
    check_prerequisites
    authenticate_azure
    deploy_infrastructure
    get_infrastructure_outputs
    build_and_push_containers
    update_container_apps
    setup_database
    run_deployment_tests
    display_summary
}

# Run main function with all arguments
main "$@"
