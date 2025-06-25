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
RESOURCE_GROUP="Reportmate"
LOCATION="Canada Central"

# Try to get DB_PASSWORD from terraform.tfvars first, then environment, then generate random
if [ -z "$DB_PASSWORD" ] && [ -f "infrastructure/terraform.tfvars" ]; then
    DB_PASSWORD=$(grep '^db_password' infrastructure/terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
fi
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}
IMAGE_TAG=${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}

# Deployment control flags (default to false, set by command line flags)
DEPLOY_INFRA=false
DEPLOY_CONTAINERS=false
SETUP_DATABASE=false
RUN_TESTS=false
SHOW_HELP=false

# Detect pipeline mode (CI/CD environment)
PIPELINE_MODE=false
if [ ! -z "$GITHUB_ACTIONS" ] || [ ! -z "$AZURE_PIPELINES" ] || [ ! -z "$CI" ]; then
    PIPELINE_MODE=true
fi

# Azure authentication
TENANT_ID=${AZURE_TENANT_ID:-}
CLIENT_ID=${AZURE_CLIENT_ID:-}
CLIENT_SECRET=${AZURE_CLIENT_SECRET:-}

# =================================================================
# COMMAND LINE ARGUMENT PARSING
# =================================================================

show_usage() {
    echo "Reportmate Unified Deployment Script"
    echo ""
    echo "Usage: $0 [FLAGS] [OPTIONS]"
    echo ""
    echo "FLAGS:"
    echo "  --full                      Run complete deployment (all flags enabled)"
    echo "  --infra                     Deploy infrastructure with Terraform"
    echo "  --containers                Build and push containers to ACR"
    echo "  --database                  Setup database schema and initial data"
    echo "  --test                      Run deployment verification tests"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "OPTIONS:"
    echo "  --resource-group <name>     Azure resource group name (default: rg-reportmate-prod)"
    echo "  --location <location>       Azure region (default: Canada Central)"
    echo "  --image-tag <tag>           Docker image tag (default: timestamp)"
    echo "  --db-password <password>    Database password (default: auto-generated)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --full                           # Complete deployment"
    echo "  $0 --containers                     # Only rebuild and push containers"
    echo "  $0 --infra --database               # Deploy infrastructure and setup database"
    echo "  $0 --containers --test              # Build containers and run tests"
    echo "  $0 --infra --image-tag v1.2.3       # Deploy infra with specific image tag"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  AZURE_TENANT_ID             Azure tenant ID for authentication"
    echo "  AZURE_CLIENT_ID             Azure client ID for service principal"
    echo "  AZURE_CLIENT_SECRET         Azure client secret for service principal"
    echo "  DB_PASSWORD                 Database password (overrides --db-password)"
    echo ""
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                DEPLOY_INFRA=true
                DEPLOY_CONTAINERS=true
                SETUP_DATABASE=true
                RUN_TESTS=true
                shift
                ;;
            --infra)
                DEPLOY_INFRA=true
                shift
                ;;
            --containers)
                DEPLOY_CONTAINERS=true
                shift
                ;;
            --database)
                SETUP_DATABASE=true
                shift
                ;;
            --test)
                RUN_TESTS=true
                shift
                ;;
            --resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            --location)
                LOCATION="$2"
                shift 2
                ;;
            --image-tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --db-password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            *)
                echo -e "${RED}❌ Unknown argument: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Show help if requested
    if [ "$SHOW_HELP" = true ]; then
        show_usage
        exit 0
    fi
    
    # Check if at least one action flag is set
    if [ "$DEPLOY_INFRA" = false ] && [ "$DEPLOY_CONTAINERS" = false ] && [ "$SETUP_DATABASE" = false ] && [ "$RUN_TESTS" = false ]; then
        echo -e "${RED}❌ No deployment actions specified${NC}"
        echo "Use --help to see available options, or --full for complete deployment"
        exit 1
    fi
}

show_configuration() {
    echo -e "${GREEN}🚀 Reportmate Unified Deployment${NC}"
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Location: $LOCATION"
    echo "  Image Tag: $IMAGE_TAG"
    echo "  Pipeline Mode: $PIPELINE_MODE"
    echo ""
    echo -e "${BLUE}Deployment Actions:${NC}"
    echo "  Deploy Infrastructure: $([ "$DEPLOY_INFRA" = true ] && echo "✅ YES" || echo "❌ NO")"
    echo "  Deploy Containers: $([ "$DEPLOY_CONTAINERS" = true ] && echo "✅ YES" || echo "❌ NO")"
    echo "  Setup Database: $([ "$SETUP_DATABASE" = true ] && echo "✅ YES" || echo "❌ NO")"
    echo "  Run Tests: $([ "$RUN_TESTS" = true ] && echo "✅ YES" || echo "❌ NO")"
    echo ""
}

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
        echo -e "${YELLOW}🔐 Authenticating with Azure Container Registry...${NC}"
        az acr login --name $ACR_NAME
    fi
    
    # Build and push frontend
    echo -e "${YELLOW}🏗️  Building frontend container...${NC}"
    cd apps/www
    
    docker build \
        --platform linux/amd64 \
        -t reportmate-frontend:$IMAGE_TAG \
        --build-arg DOCKER_BUILD=true \
        .
    
    docker tag reportmate-frontend:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-frontend:$IMAGE_TAG
    docker tag reportmate-frontend:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-frontend:latest
    
    echo -e "${YELLOW}📤 Pushing frontend to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate-frontend:$IMAGE_TAG
    docker push $ACR_LOGIN_SERVER/reportmate-frontend:latest
    
    cd ../..
    
    # Build and push functions
    echo -e "${YELLOW}🏗️  Building functions container...${NC}"
    cd functions
    
    docker build \
        --platform linux/amd64 \
        -t reportmate-functions:$IMAGE_TAG \
        .
    
    docker tag reportmate-functions:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    docker tag reportmate-functions:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-functions:latest
    
    echo -e "${YELLOW}📤 Pushing functions to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    docker push $ACR_LOGIN_SERVER/reportmate-functions:latest
    
    cd ..
    
    echo -e "${GREEN}✅ Containers built and pushed successfully!${NC}"
}

update_container_apps() {
    if [ "$DEPLOY_CONTAINERS" != true ]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔄 Updating container apps with new images...${NC}"
    
    cd infrastructure
    
    # Update container apps using Terraform with new image tags
    echo -e "${BLUE}Updating infrastructure with new image tags...${NC}"
    terraform apply -auto-approve \
        -var="db_password=$DB_PASSWORD" \
        -var="enable_pipeline_permissions=$PIPELINE_MODE" \
        -var="pipeline_service_principal_id=${AZURE_CLIENT_ID:-}" \
        -var="frontend_image_tag=$IMAGE_TAG" \
        -var="functions_image_tag=$IMAGE_TAG"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Container app update failed${NC}"
        exit 1
    fi
    
    cd ..
    
    echo -e "${GREEN}✅ Container apps updated!${NC}"
}

setup_database() {
    if [ "$SETUP_DATABASE" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping database setup${NC}"
        return 0
    fi
    
    if [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}⚠️  Skipping database setup in pipeline mode${NC}"
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
    if [ "$RUN_TESTS" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping deployment tests${NC}"
        return 0
    fi
    
    if [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}⚠️  Skipping interactive tests in pipeline mode${NC}"
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
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show configuration
    show_configuration
    
    # Confirm deployment in interactive mode
    if [ "$PIPELINE_MODE" = false ]; then
        echo -e "${YELLOW}Do you want to proceed with the deployment? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Deployment cancelled.${NC}"
            exit 0
        fi
        echo ""
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
