#!/bin/bash
# Get environment variables from Terraform outputs for deployment

set -e

cd infrastructure

echo "🔧 Extracting deployment environment variables..."

# Get Terraform outputs
DB_PASSWORD=$(terraform output -raw db_password 2>/dev/null || echo "")
STORAGE_CONNECTION=$(terraform output -raw storage_connection_string 2>/dev/null || echo "")
WPS_CONNECTION=$(terraform output -raw web_pubsub_connection_string 2>/dev/null || echo "")
FUNCTION_URL=$(terraform output -raw function_app_url 2>/dev/null || echo "")
WPS_ENDPOINT=$(terraform output -raw web_pubsub_endpoint 2>/dev/null || echo "")

# Create environment file
cat > ../.env.deployment << EOF
# Generated deployment environment variables
NODE_ENV=production

# Database
DATABASE_URL=postgresql://reportmate:${DB_PASSWORD}@reportmate-database.postgres.database.azure.com:5432/reportmate?sslmode=require

# Azure Storage
AZURE_STORAGE_CONNECTION_STRING=${STORAGE_CONNECTION}
QUEUE_NAME=osquery-ingest

# Web PubSub
EVENTS_CONNECTION=${WPS_CONNECTION}

# Frontend Configuration
NEXT_PUBLIC_WPS_URL=wss://${WPS_ENDPOINT}/client/hubs/events
NEXT_PUBLIC_ENABLE_SIGNALR=true
NEXT_PUBLIC_API_BASE_URL=${FUNCTION_URL}
EOF

echo "✅ Environment file created: .env.deployment"
echo "💡 Source this file before deployment: source .env.deployment"

cd ..
