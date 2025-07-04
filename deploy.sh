#!/bin/bash

# ReportMate Unified Deployment Script
# Deploy infrastructure and applications to Azure

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
RESOURCE_GROUP="ReportMate"
LOCATION="Canada Central"
ENVIRONMENT="prod"  # Default environment

# Try to get DB_PASSWORD from terraform.tfvars first, then environment, then generate random
# CRITICAL: For container-only deployments, DB_PASSWORD is not used since we don't touch infrastructure
# This ensures that container updates cannot accidentally change the database password
if [ -z "$DB_PASSWORD" ] && [ -f "infrastructure/terraform.tfvars" ]; then
    DB_PASSWORD=$(grep '^db_password' infrastructure/terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
fi
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}
IMAGE_TAG=${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}

# Deployment control flags (default to false, set by command line flags)
DEPLOY_INFRA=false
DEPLOY_CONTAINERS=false
DEPLOY_FUNCTIONS=false
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
    echo "ReportMate Unified Deployment Script"
    echo ""
    echo "Usage: $0 [FLAGS] [OPTIONS]"
    echo ""
    echo "FLAGS:"
    echo "  --full                      Run complete deployment (all flags enabled)"
    echo "  --infra                     Deploy infrastructure with Terraform"
    echo "  --containers                Build and push containers to ACR"
    echo "  --functions                 Deploy Azure Functions only"
    echo "  --database                  Setup database schema and initial data"
    echo "  --test                      Run deployment verification tests"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "OPTIONS:"
    echo "  --env <environment>         Target environment: dev, prod, or both (default: prod)"
    echo "  --resource-group <name>     Azure resource group name (default: ReportMate)"
    echo "  --location <location>       Azure region (default: Canada Central)"
    echo "  --image-tag <tag>           Docker image tag (default: timestamp)"
    echo "  --db-password <password>    Database password (default: auto-generated)"
    echo ""
    echo "ENVIRONMENT OPTIONS:"
    echo "  dev                         Deploy development container app only"
    echo "  prod                        Deploy production container app only (default)"
    echo "  both                        Deploy both development and production apps"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --full                           # Complete deployment to production"
    echo "  $0 --full --env dev                 # Complete deployment to development"
    echo "  $0 --full --env both                # Deploy to both dev and prod"
    echo "  $0 --containers --env dev           # Only rebuild and push to dev"
    echo "  $0 --functions                       # Deploy Azure Functions only"
    echo "  $0 --infra --database --env prod    # Deploy infrastructure and setup database for prod"
    echo "  $0 --containers --test --env both   # Build containers for both envs and run tests"
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
                DEPLOY_FUNCTIONS=true
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
            --functions)
                DEPLOY_FUNCTIONS=true
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
            --env)
                ENVIRONMENT="$2"
                # Validate environment value
                if [[ ! "$ENVIRONMENT" =~ ^(dev|prod|both)$ ]]; then
                    echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
                    echo "Environment must be 'dev', 'prod', or 'both'"
                    exit 1
                fi
                shift 2
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
                echo -e "${RED}Unknown argument: $1${NC}"
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
    if [ "$DEPLOY_INFRA" = false ] && [ "$DEPLOY_CONTAINERS" = false ] && [ "$DEPLOY_FUNCTIONS" = false ] && [ "$SETUP_DATABASE" = false ] && [ "$RUN_TESTS" = false ]; then
        echo -e "${RED}No deployment actions specified${NC}"
        echo "Use --help to see available options, or --full for complete deployment"
        exit 1
    fi
}

show_configuration() {
    echo -e "${GREEN}ReportMate Unified Deployment${NC}"
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Location: $LOCATION"
    echo "  Environment: $ENVIRONMENT"
    echo "  Image Tag: $IMAGE_TAG"
    echo "  Pipeline Mode: $PIPELINE_MODE"
    echo ""
    echo -e "${BLUE}Environment Targets:${NC}"
    case $ENVIRONMENT in
        "dev")
            echo "  Development: YES"
            echo "  Production: NO"
            ;;
        "prod")
            echo "  Development: NO"
            echo "  Production: YES"
            ;;
        "both")
            echo "  Development: YES"
            echo "  Production: YES"
            ;;
    esac
    echo ""
    echo -e "${BLUE}Deployment Actions:${NC}"
    echo "  Deploy Infrastructure: $([ "$DEPLOY_INFRA" = true ] && echo "YES" || echo "NO")"
    echo "  Deploy Containers: $([ "$DEPLOY_CONTAINERS" = true ] && echo "YES" || echo "NO")"
    echo "  Setup Database: $([ "$SETUP_DATABASE" = true ] && echo "YES" || echo "NO")"
    echo "  Run Tests: $([ "$RUN_TESTS" = true ] && echo "YES" || echo "NO")"
    echo ""
}

# =================================================================
# FUNCTIONS
# =================================================================

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    missing_tools=()
    
    # Only check for terraform if deploying infrastructure
    if [ "$DEPLOY_INFRA" = true ] && ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    # Only check for azure-cli if deploying infrastructure or containers
    if ([ "$DEPLOY_INFRA" = true ] || [ "$DEPLOY_CONTAINERS" = true ]) && ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    # Only check for docker if deploying containers
    if [ "$DEPLOY_CONTAINERS" = true ] && ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install the missing tools before proceeding.${NC}"
        exit 1
    fi
    
    # Check if Docker is needed for this deployment
    if [ "$DEPLOY_CONTAINERS" = true ]; then
        echo -e "${BLUE}Checking Docker status...${NC}"
        
        # Check if Docker daemon is running
        if ! docker info &> /dev/null; then
            echo -e "${YELLOW}Docker is not running. Attempting to start Docker...${NC}"
            
            # Try to start Docker based on the OS
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS - start Docker Desktop
                if command -v open &> /dev/null; then
                    echo -e "${BLUE}Starting Docker Desktop...${NC}"
                    open -a Docker
                    
                    # Wait for Docker to start (up to 60 seconds)
                    echo -e "${YELLOW}Waiting for Docker to start...${NC}"
                    for i in {1..30}; do
                        if docker info &> /dev/null; then
                            echo -e "${GREEN}Docker started successfully!${NC}"
                            break
                        fi
                        echo -n "."
                        sleep 2
                    done
                    echo ""
                    
                    # Final check
                    if ! docker info &> /dev/null; then
                        echo -e "${RED}Failed to start Docker. Please start Docker Desktop manually and try again.${NC}"
                        exit 1
                    fi
                else
                    echo -e "${RED}Cannot start Docker automatically. Please start Docker Desktop and try again.${NC}"
                    exit 1
                fi
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                # Linux - try to start Docker service
                echo -e "${BLUE}Attempting to start Docker service...${NC}"
                if command -v systemctl &> /dev/null; then
                    sudo systemctl start docker
                    sleep 5
                elif command -v service &> /dev/null; then
                    sudo service docker start
                    sleep 5
                fi
                
                # Check if Docker started
                if ! docker info &> /dev/null; then
                    echo -e "${RED}Failed to start Docker. Please start Docker manually:${NC}"
                    echo -e "${YELLOW}  sudo systemctl start docker${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}Unsupported OS. Please start Docker manually and try again.${NC}"
                exit 1
            fi
        else
            echo -e "${GREEN}Docker is running${NC}"
        fi
    fi
    
    echo -e "${GREEN}Prerequisites check complete${NC}"
}

authenticate_azure() {
    echo -e "${YELLOW}Authenticating with Azure...${NC}"
    
    if [ "$PIPELINE_MODE" = false ]; then
        # Interactive login for local development
        if ! az account show &> /dev/null; then
            echo -e "${BLUE}Please login to Azure:${NC}"
            if [ -n "$TENANT_ID" ]; then
                az login --tenant "$TENANT_ID"
            else
                az login
            fi
        fi
        
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        TENANT_ID=$(az account show --query tenantId -o tsv)
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
    
    echo -e "${GREEN}Azure authentication complete${NC}"
}

deploy_infrastructure() {
    if [ "$DEPLOY_INFRA" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping infrastructure deployment${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
    
    cd infrastructure
    
    # Initialize Terraform
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init
    
    # Validate configuration
    echo -e "${BLUE}Validating Terraform configuration...${NC}"
    terraform validate
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Terraform validation failed${NC}"
        exit 1
    fi
    
    # Set deployment flags based on environment
    case $ENVIRONMENT in
        "dev")
            DEPLOY_DEV=true
            DEPLOY_PROD=false
            ;;
        "prod")
            DEPLOY_DEV=false
            DEPLOY_PROD=true
            ;;
        "both")
            DEPLOY_DEV=true
            DEPLOY_PROD=true
            ;;
        *)
            echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
            exit 1
            ;;
    esac
    
    # Plan deployment
    echo -e "${BLUE}Planning Terraform deployment for environment: $ENVIRONMENT...${NC}"
    terraform plan \
        -var="db_password=$DB_PASSWORD" \
        -var="environment=$ENVIRONMENT" \
        -var="deploy_dev=$DEPLOY_DEV" \
        -var="deploy_prod=$DEPLOY_PROD" \
        -var="enable_pipeline_permissions=$PIPELINE_MODE" \
        -var="pipeline_service_principal_id=${AZURE_CLIENT_ID:-}" \
        -out=tfplan
    
    # Apply infrastructure
    echo -e "${YELLOW}Applying Terraform plan...${NC}"
    terraform apply -auto-approve tfplan
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Terraform deployment failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
    cd ..
}

get_infrastructure_outputs() {
    echo -e "${YELLOW}Getting infrastructure outputs...${NC}"
    
    cd infrastructure
    
    # Get outputs with fallbacks
    ACR_NAME=$(terraform output -raw container_registry_login_server 2>/dev/null | cut -d'.' -f1 || echo "reportmateacr")
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server 2>/dev/null || echo "reportmateacr.azurecr.io")
    FUNCTION_APP_URL=$(terraform output -raw function_app_url 2>/dev/null || echo "")
    FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "")
    WEB_PUBSUB_ENDPOINT=$(terraform output -raw web_pubsub_endpoint 2>/dev/null || echo "")
    DB_CONNECTION=$(terraform output -raw postgres_connection 2>/dev/null || echo "")
    
    echo "  ACR Name: $ACR_NAME"
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
        echo -e "${YELLOW}Authenticating with Azure Container Registry...${NC}"
        echo "ACR Name: $ACR_NAME"
        echo "ACR Login Server: $ACR_LOGIN_SERVER"
        
        if [ -n "$ACR_NAME" ] && [ "$ACR_NAME" != "reportmateacr" ]; then
            echo "Logging in to ACR: $ACR_NAME"
            az acr login --name "$ACR_NAME"
        else
            echo "Using fallback ACR: reportmateacr"
            az acr login --name reportmateacr
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}ACR login failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}ACR authentication successful${NC}"
    fi
    
    # Build and push frontend
    echo -e "${YELLOW}Building frontend container...${NC}"
    cd apps/www
    
    # Replace API URL placeholder with actual function app URL
    if [ -n "$FUNCTION_APP_URL" ]; then
        echo -e "${BLUE}Setting API Base URL to: $FUNCTION_APP_URL${NC}"
        
        # Create temporary .env.production with actual URLs
        sed "s|__API_BASE_URL__|$FUNCTION_APP_URL|g" .env.production > .env.production.tmp
        mv .env.production.tmp .env.production
    else
        echo -e "${YELLOW}⚠️  Function App URL not available, using placeholder${NC}"
    fi
    
    docker build \
        --platform linux/amd64 \
        -t reportmate:$IMAGE_TAG \
        --build-arg DOCKER_BUILD=true \
        .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Frontend Docker build failed${NC}"
        exit 1
    fi
    
    docker tag reportmate:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate:$IMAGE_TAG
    docker tag reportmate:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate:latest
    
    echo -e "${YELLOW}📤 Pushing frontend to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate:$IMAGE_TAG
    docker push $ACR_LOGIN_SERVER/reportmate:latest
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Frontend Docker push failed${NC}"
        exit 1
    fi
    
    cd ../..
    
    # Build and push functions
    echo -e "${YELLOW}Building functions container...${NC}"
    cd functions
    
    docker build \
        --platform linux/amd64 \
        -t reportmate-functions:$IMAGE_TAG \
        .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Functions Docker build failed${NC}"
        exit 1
    fi
    
    docker tag reportmate-functions:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    docker tag reportmate-functions:$IMAGE_TAG $ACR_LOGIN_SERVER/reportmate-functions:latest
    
    echo -e "${YELLOW}📤 Pushing functions to ACR...${NC}"
    docker push $ACR_LOGIN_SERVER/reportmate-functions:$IMAGE_TAG
    docker push $ACR_LOGIN_SERVER/reportmate-functions:latest
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Functions Docker push failed${NC}"
        exit 1
    fi
    
    cd ..
    
    echo -e "${GREEN}Containers built and pushed successfully!${NC}"
}

update_container_apps() {
    if [ "$DEPLOY_CONTAINERS" != true ]; then
        return 0
    fi
    
    # Skip Terraform update if only deploying containers since images use :latest tag
    # Container apps will automatically pull the new :latest images
    echo -e "${YELLOW}🔄 Container apps will automatically update with new :latest images${NC}"
    echo -e "${BLUE}ℹ️  Skipping Terraform update as containers are configured to use :latest tag${NC}"
    
    # Optional: Add a short delay to ensure images are available in ACR
    echo -e "${BLUE}Waiting 10 seconds for ACR to finalize image push...${NC}"
    sleep 10
    
    echo -e "${GREEN}Container deployment complete! Apps will update automatically.${NC}"
    
    # Force update container apps to ensure they pull the latest images immediately
    echo -e "${YELLOW}🔄 Forcing container app updates to pull latest images...${NC}"
    
    # Update based on environment setting
    if [ "$ENVIRONMENT" = "dev" ] || [ "$ENVIRONMENT" = "both" ]; then
        echo -e "${BLUE}Updating development environment container apps...${NC}"
        
        # Update frontend dev
        az containerapp update \
            --name reportmate-frontend-dev \
            --resource-group $RESOURCE_GROUP \
            --image $ACR_LOGIN_SERVER/reportmate:latest \
            --output table 2>/dev/null && echo -e "${GREEN}✅ Dev frontend updated${NC}" || echo -e "${YELLOW}⚠️  Dev frontend update failed or app doesn't exist${NC}"
        
        # Update functions dev
        az containerapp update \
            --name reportmate-functions-dev \
            --resource-group $RESOURCE_GROUP \
            --image $ACR_LOGIN_SERVER/reportmate-functions:latest \
            --output table 2>/dev/null && echo -e "${GREEN}✅ Dev functions updated${NC}" || echo -e "${YELLOW}⚠️  Dev functions update failed or app doesn't exist${NC}"
    fi
    
    if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "both" ]; then
        echo -e "${BLUE}Updating production environment container apps...${NC}"
        
        # Update frontend prod
        az containerapp update \
            --name reportmate-frontend-prod \
            --resource-group $RESOURCE_GROUP \
            --image $ACR_LOGIN_SERVER/reportmate:latest \
            --output table 2>/dev/null && echo -e "${GREEN}✅ Prod frontend updated${NC}" || echo -e "${YELLOW}⚠️  Prod frontend update failed or app doesn't exist${NC}"
        
        # Update functions prod
        az containerapp update \
            --name reportmate-functions-prod \
            --resource-group $RESOURCE_GROUP \
            --image $ACR_LOGIN_SERVER/reportmate-functions:latest \
            --output table 2>/dev/null && echo -e "${GREEN}✅ Prod functions updated${NC}" || echo -e "${YELLOW}⚠️  Prod functions update failed or app doesn't exist${NC}"
    fi
    
    echo -e "${GREEN}Container app updates completed!${NC}"
}

deploy_functions() {
    if [ "$DEPLOY_FUNCTIONS" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping Azure Functions deployment${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🚀 Deploying Azure Functions...${NC}"
    
    # Get function app name from Terraform outputs
    cd infrastructure
    FUNCTION_APP_NAME=$(terraform output -raw function_app_name 2>/dev/null || echo "reportmate-api")
    cd ..
    
    echo -e "${BLUE}Function App Name: $FUNCTION_APP_NAME${NC}"
    
    # Deploy functions using Azure CLI
    echo -e "${YELLOW}📦 Deploying functions source code...${NC}"
    cd functions
    
    # Deploy to Azure Functions directly using zip deployment
    echo -e "${YELLOW}🚀 Deploying to Azure Functions...${NC}"
    
    # Use Azure Functions Core Tools or az CLI for direct deployment
    if command -v func >/dev/null 2>&1; then
        echo -e "${BLUE}Using Azure Functions Core Tools...${NC}"
        func azure functionapp publish $FUNCTION_APP_NAME --python
    else
        echo -e "${BLUE}Creating deployment using tar (cross-platform)...${NC}"
        # Create tar archive which works on both Windows and Unix
        tar -czf deployment.tar.gz --exclude='.git*' --exclude='__pycache__' --exclude='*.pyc' --exclude='*.log' --exclude='deployment.*' .
        
        # Convert tar to zip using Python (available on most systems)
        python3 -c "
import tarfile
import zipfile
import os
import tempfile

# Extract tar to temp directory
with tempfile.TemporaryDirectory() as temp_dir:
    with tarfile.open('deployment.tar.gz', 'r:gz') as tar:
        tar.extractall(temp_dir)
    
    # Create zip from extracted files
    with zipfile.ZipFile('deployment.zip', 'w', zipfile.ZIP_DEFLATED) as zip_file:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arc_name = os.path.relpath(file_path, temp_dir)
                zip_file.write(file_path, arc_name)

os.remove('deployment.tar.gz')
print('deployment.zip created successfully')
"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to create deployment package${NC}"
            exit 1
        fi
        
        # Deploy using Azure CLI
        az functionapp deployment source config-zip \
            --resource-group $RESOURCE_GROUP \
            --name $FUNCTION_APP_NAME \
            --src deployment.zip
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Azure Functions deployment failed${NC}"
        exit 1
    fi
    
    # Clean up deployment package if it exists
    if [ -f "deployment.zip" ]; then
        rm deployment.zip
    fi
    
    cd ..
    
    echo -e "${GREEN}✅ Azure Functions deployed successfully!${NC}"
    
    # Restart function app to ensure changes take effect
    echo -e "${YELLOW}🔄 Restarting function app...${NC}"
    az functionapp restart \
        --resource-group $RESOURCE_GROUP \
        --name $FUNCTION_APP_NAME
    
    echo -e "${GREEN}Azure Functions deployment complete!${NC}"
}

setup_database() {
    if [ "$SETUP_DATABASE" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping database setup${NC}"
        return 0
    fi
    
    if [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}Skipping database setup in pipeline mode${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🗄️  Setting up database...${NC}"
    
    if [ -f scripts/setup-database.sh ] && [ -n "$DB_CONNECTION" ]; then
        export DATABASE_URL="$DB_CONNECTION"
        ./scripts/setup-database.sh
        echo -e "${GREEN}Database setup complete!${NC}"
    else
        echo -e "${YELLOW}Database setup script not found or no connection string${NC}"
    fi
}

run_deployment_tests() {
    if [ "$RUN_TESTS" != true ]; then
        echo -e "${YELLOW}⏭️  Skipping deployment tests${NC}"
        return 0
    fi
    
    if [ "$PIPELINE_MODE" = true ]; then
        echo -e "${YELLOW}Skipping interactive tests in pipeline mode${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Running deployment tests...${NC}"
    
    if [ -n "$FUNCTION_APP_URL" ]; then
        echo -e "${BLUE}Testing negotiate endpoint...${NC}"
        
        # Wait for function app to warm up
        sleep 30
        
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_APP_URL/api/negotiate?device=deployment-test" || echo "000")
        
        if [ "$HTTP_STATUS" = "200" ]; then
            echo -e "${GREEN}Negotiate endpoint is working!${NC}"
        else
            echo -e "${YELLOW}Negotiate endpoint returned status: $HTTP_STATUS${NC}"
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
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo ""
    echo -e "${BLUE}� Deployment Summary:${NC}"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Image Tag: $IMAGE_TAG"
    
    if [ -n "$FUNCTION_APP_URL" ]; then
        echo "  Function App: $FUNCTION_APP_URL"
    fi
    
    if [ -n "$FRONTEND_URL" ]; then
        echo "  Frontend: $FRONTEND_URL"
    fi
    
    if [ -n "$WEB_PUBSUB_ENDPOINT" ]; then
        echo "  WebPubSub: wss://$WEB_PUBSUB_ENDPOINT/client/hubs/events"
    fi
    
    if [ -n "$ACR_LOGIN_SERVER" ]; then
        echo "  Container Registry: $ACR_LOGIN_SERVER"
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
    
    echo -e "${GREEN}Your real-time security events dashboard is now live!${NC}"
}

# =================================================================
# MAIN EXECUTION
# =================================================================

main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show configuration
    show_configuration
    
    # Execute deployment steps
    check_prerequisites
    authenticate_azure
    deploy_infrastructure
    get_infrastructure_outputs
    build_and_push_containers
    update_container_apps
    deploy_functions
    setup_database
    run_deployment_tests
    display_summary
}

# Run main function with all arguments
main "$@"
