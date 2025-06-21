#!/bin/bash

# Seemianki Production Deployment Script
# Run this script to deploy infrastructure and applications to Azure

set -e  # Exit on any error

echo "🚀 Starting Seemianki Production Deployment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Installing..."
    # For Ubuntu/Debian
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
fi

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

echo "✅ Prerequisites check complete"

# Set variables
RESOURCE_GROUP="rg-seemianki-prod"
LOCATION="Canada Central"
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}

echo "🔐 Using database password: ${DB_PASSWORD:0:8}..."

# Login to Azure (if not already logged in)
echo "🔑 Checking Azure login..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📝 Using subscription: $SUBSCRIPTION_ID"

# Deploy infrastructure
echo "🏗️  Deploying infrastructure with Terraform..."
cd infrastructure

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
echo "✅ Terraform configuration is valid"

# Plan deployment
terraform plan -var="db_password=$DB_PASSWORD" -out=tfplan
echo "📋 Terraform plan created"

# Apply infrastructure
echo "🚀 Applying Terraform plan..."
terraform apply -auto-approve tfplan

# Get outputs
FUNCTION_APP_NAME=$(terraform output -raw function_app_url | sed 's|https://||' | sed 's|\.azurewebsites\.net||')
WEB_PUBSUB_ENDPOINT=$(terraform output -raw web_pubsub_endpoint)

echo "✅ Infrastructure deployed successfully!"
echo "📡 Function App: $FUNCTION_APP_NAME"
echo "🌐 Web PubSub: $WEB_PUBSUB_ENDPOINT"

# Build and deploy functions
cd ../functions
echo "🔧 Preparing Azure Functions deployment..."

# Create deployment package
zip -r ../functions.zip . -x "*.pyc" "*/__pycache__/*" "*.git*"

# Deploy functions
echo "🚀 Deploying Azure Functions..."
az functionapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --src ../functions.zip

echo "✅ Functions deployed successfully!"

# Build dashboard
cd ../apps/www
echo "🎨 Building Next.js dashboard..."

# Install dependencies
npm install -g pnpm
pnpm install

# Build for production
pnpm run build

echo "✅ Dashboard built successfully!"

# Deploy to Static Web App (if configured)
if [ ! -z "$AZURE_STATIC_WEB_APPS_API_TOKEN" ]; then
    echo "🌐 Deploying to Azure Static Web Apps..."
    npx @azure/static-web-apps-cli deploy \
        --app-location "." \
        --output-location "out" \
        --deployment-token "$AZURE_STATIC_WEB_APPS_API_TOKEN"
    echo "✅ Dashboard deployed to Static Web Apps!"
else
    echo "⚠️  AZURE_STATIC_WEB_APPS_API_TOKEN not set. Skipping Static Web App deployment."
    echo "   You can deploy manually or set up the token for automatic deployment."
fi

# Setup database schema
echo "🗄️  Setting up database schema..."
cd ../../infrastructure

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 30

# Apply database schema
if [ -f "db-setup.sql" ]; then
    DB_CONNECTION=$(terraform output -raw postgres_connection)
    psql "$DB_CONNECTION" -f db-setup.sql
    echo "✅ Database schema applied!"
else
    echo "⚠️  Database schema file not found. Creating basic tables..."
    DB_CONNECTION=$(terraform output -raw postgres_connection)
    psql "$DB_CONNECTION" -c "
    CREATE TABLE IF NOT EXISTS events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        device VARCHAR(255) NOT NULL,
        kind VARCHAR(100) NOT NULL,
        ts TIMESTAMP WITH TIME ZONE NOT NULL,
        payload JSONB NOT NULL DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    CREATE TABLE IF NOT EXISTS cimian_runs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        device VARCHAR(255) NOT NULL,
        ts TIMESTAMP WITH TIME ZONE NOT NULL,
        exit_code INTEGER,
        duration INTEGER,
        details TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device, ts DESC);
    CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
    CREATE INDEX IF NOT EXISTS idx_cimian_runs_device_ts ON cimian_runs(device, ts DESC);
    "
    echo "✅ Database schema created!"
fi

# Test deployment
echo "🧪 Testing deployment..."

# Test negotiate endpoint
FUNCTION_URL="https://$FUNCTION_APP_NAME.azurewebsites.net"
echo "🔗 Testing negotiate endpoint: $FUNCTION_URL/api/negotiate"

# Wait for function app to be ready
sleep 30

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_URL/api/negotiate?device=deployment-test" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Negotiate endpoint is working!"
else
    echo "⚠️  Negotiate endpoint returned status: $HTTP_STATUS"
    echo "   Functions may still be warming up. Try again in a few minutes."
fi

# Test ingest endpoint
echo "🧪 Testing ingest endpoint..."
curl -X POST "$FUNCTION_URL/api/ingest" \
    -H "Content-Type: application/json" \
    -d '{
        "device": "deployment-test",
        "kind": "deployment_verification",
        "payload": {
            "message": "Deployment test successful",
            "timestamp": "'$(date -Iseconds)'"
        }
    }' -w "\nHTTP Status: %{http_code}\n" || echo "Test request failed"

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📋 Deployment Summary:"
echo "  🏗️  Resource Group: $RESOURCE_GROUP"
echo "  🌐 Function App: https://$FUNCTION_APP_NAME.azurewebsites.net"
echo "  📡 Web PubSub: $WEB_PUBSUB_ENDPOINT"
echo "  🗄️  Database: PostgreSQL Flexible Server"
echo ""
echo "🔗 Important URLs:"
echo "  📊 Dashboard: Deploy to your Static Web App or hosting platform"
echo "  🔧 API Base: https://$FUNCTION_APP_NAME.azurewebsites.net"
echo "  📈 Monitor: https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo ""
echo "🔐 Save these credentials securely:"
echo "  Database Password: $DB_PASSWORD"
echo ""
echo "📚 Next Steps:"
echo "  1. Set up monitoring alerts in Application Insights"
echo "  2. Configure your domain for the dashboard"
echo "  3. Set up Azure DevOps CI/CD pipeline for automated deployments"
echo "  4. Test real-time event flow end-to-end"
echo ""
echo "🚀 Your real-time security events dashboard is now live!"
