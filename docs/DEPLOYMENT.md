# 🚀 Reportmate Deployment Guide

Complete deployment instructions for the Reportmate real-time security events dashboard.

## 📋 Prerequisites

### Azure Requirements
- **Azure Subscription** with appropriate permissions
- **Contributor** role on the subscription (or resource group)
- **User Access Administrator** role (for RBAC assignments)

### Development Tools
- **Azure CLI** installed and authenticated
- **Docker** (for local development and container building)
- **Terraform** (for infrastructure deployment)
- **Azure DevOps** project access (for CI/CD)

## 🎯 Deployment Options

| Option | Best For | Time | Complexity | Features |
|--------|----------|------|------------|----------|
| **[Container Apps](#container-deployment)** | Production | 30 min | Medium | Auto-scaling, zero-downtime |
| **[Azure Functions](#serverless-deployment)** | Event-driven | 20 min | Low | Pay-per-use, proven |
| **[Local Development](#local-development)** | Testing | 10 min | Low | Full local environment |
| **[Hybrid](#hybrid-deployment)** | Migration | 45 min | High | Best of both worlds |

---

## 🐳 Container Deployment (Recommended)

Modern, scalable deployment using Azure Container Apps.

### Step 1: Azure DevOps Setup

#### Create Service Connection

1. **Navigate to Azure DevOps Project**
   - Go to **Project Settings** → **Service connections**
   - Click **New service connection** → **Azure Resource Manager**
   - Choose **Service principal (automatic)**

2. **Configure Connection**
   - **Subscription**: Select your Azure subscription
   - **Resource group**: Select `Reportmate` (or leave empty for subscription scope)
   - **Service connection name**: `reportmate-azure-connection`
   - **Security**: ✅ Grant access permission to all pipelines

3. **Test Connection**
   - Click **Verify** → **Save**

#### Create Variable Group

1. **Go to Library** → **Variable groups**
2. **Create new group**: `reportmate-secrets`
3. **Add variables**:
   ```
   DB_PASSWORD: [your-secure-database-password] (mark as secret)
   AZURE_SUBSCRIPTION_ID: [your-subscription-id]
   ```

### Step 2: Infrastructure Deployment

#### Option A: Azure DevOps Pipeline (Recommended)

1. **Update pipeline variables** in `pipelines/reportmate-deploy-full.yml`:
   ```yaml
   variables:
     azureSubscription: 'reportmate-azure-connection'  # Your service connection name
     resourceGroupName: 'Reportmate'
     containerRegistryName: 'reportmateacr'
   ```

2. **Run the pipeline**:
   - Go to **Pipelines** → **New pipeline**
   - Select your repository
   - Choose **Existing Azure Pipelines YAML file**
   - Select `pipelines/reportmate-deploy-full.yml`
   - **Run**

#### Option B: Local Deployment

```bash
# Clone repository
git clone <your-repo-url>
cd Reportmate

# Set up environment
cp .env.example .env
# Edit .env with your Azure subscription details

# Deploy infrastructure
cd infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# Deploy containers
cd ..
./deploy-containers.sh
```

### Step 3: Verify Deployment

```bash
# Check resources
az group show --name Reportmate

# Test API endpoints
curl https://reportmate-api.azurewebsites.net/api/negotiate?device=test

# Access dashboard
# https://reportmate-frontend.{random}.canadacentral.azurecontainerapps.io
```

---

## ⚡ Serverless Deployment

Traditional Azure Functions deployment for event-driven architecture.

### Step 1: Infrastructure Only

```bash
# Deploy infrastructure only
cd infrastructure
terraform init
terraform plan -target=azurerm_linux_function_app.reportmate_api
terraform apply -auto-approve
```

### Step 2: Function Deployment

Use the existing pipeline: `pipelines/reportmate-deploy-infra.yml`

**What this deploys**:
- ✅ Azure Functions (Python runtime)
- ✅ PostgreSQL Flexible Server
- ✅ Web PubSub for real-time updates
- ✅ Storage Queue for event processing
- ✅ Application Insights for monitoring

---

## 🏠 Local Development

Full local environment for development and testing.

### Step 1: Prerequisites

```bash
# Install dependencies
brew install docker docker-compose
npm install -g pnpm

# Verify installations
docker --version
pnpm --version
```

### Step 2: Environment Setup

```bash
# Clone and setup
git clone <your-repo-url>
cd Reportmate

# Copy environment template
cp .env.example .env

# Edit .env file with your preferences
# For local development, you can use default values
```

### Step 3: Start Services

```bash
# Start all services
docker-compose up -d

# Setup database
./scripts/setup-database.sh

# Install frontend dependencies
cd apps/www
pnpm install

# Start development server
pnpm dev
```

### Step 4: Test Local Setup

```bash
# Access dashboard
open http://localhost:3000/dashboard

# Test API
curl -X POST http://localhost:7071/api/ingest \
  -H "Content-Type: application/json" \
  -d '{"device":"test","kind":"info","payload":{"message":"Hello Local!"}}'

# Generate demo data
cd apps/www
pnpm demo
```

---

## 🔄 Hybrid Deployment

Combine container frontend with serverless backend.

### Architecture
```text
┌─────────────────┐    ┌──────────────────┐
│  Container Apps │    │ Azure Functions  │
│  (Frontend)     │───▶│  (Backend APIs)  │
│                 │    │                  │
│ - Dashboard UI  │    │ - Event Ingest   │
│ - Real-time     │    │ - Device APIs    │
│ - Auto-scaling  │    │ - Queue Process  │
└─────────────────┘    └──────────────────┘
```

### Deployment Steps

1. **Deploy Functions first** (proven backend)
2. **Add Container Apps** (modern frontend)
3. **Migrate gradually** as needed

```bash
# Step 1: Deploy serverless backend
terraform apply -target=azurerm_linux_function_app.reportmate_api

# Step 2: Add container support
terraform apply -target=azurerm_container_app.frontend

# Step 3: Test both environments
curl https://reportmate-api.azurewebsites.net/api/negotiate
```

---

## 🔐 Security Configuration

### Managed Identity (Automated by Terraform)

Your Terraform configuration automatically creates:

- ✅ **User-assigned managed identity**
- ✅ **Storage Queue Data Contributor** role
- ✅ **Storage Blob Data Contributor** role  
- ✅ **Web PubSub Service Owner** role
- ✅ **AcrPull** role for container images
- ✅ **Monitoring Contributor** role

**No manual `az role assignment` commands needed!** 🎉

### Service Principal Permissions

For Azure DevOps pipeline, the service principal needs:

```yaml
# Automatically assigned by Terraform when:
enable_pipeline_permissions = true
pipeline_service_principal_id = "your-sp-object-id"
```

Roles assigned:
- **Container Registry Contributor** - Push/pull images
- **Container Apps Contributor** - Deploy containers

### Environment Variables

**Production** (automatically configured by Terraform):
- `DATABASE_URL` - PostgreSQL connection string
- `EVENTS_CONNECTION` - Web PubSub connection string
- `AZURE_STORAGE_CONNECTION_STRING` - Storage account
- `QUEUE_NAME` - Event processing queue

**Development** (in `.env` file):
```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:7071
NEXT_PUBLIC_ENABLE_SIGNALR=false
DATABASE_URL=postgresql://user:pass@localhost:5432/reportmate
```

---

## 🧪 Testing Your Deployment

### Health Checks

```bash
# Function App health
curl https://reportmate-api.azurewebsites.net/api/negotiate?device=health-check

# Container Apps health  
curl https://reportmate-frontend.{random}.canadacentral.azurecontainerapps.io/

# Database connection
az postgres flexible-server connect --name reportmate-db --admin-user reportmate
```

### Device Testing

```bash
# Send test events
curl -X POST https://reportmate-api.azurewebsites.net/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "device": "device-001",
    "kind": "info",
    "payload": {
      "message": "Device status update",
      "cpu_usage": "23%",
      "uptime": "5 days 2 hours"
    }
  }'

# Verify real-time dashboard updates
# Should appear instantly on the dashboard!
```

### Load Testing

```bash
# Generate multiple events
for i in {1..100}; do
  curl -X POST https://reportmate-api.azurewebsites.net/api/ingest \
    -H "Content-Type: application/json" \
    -d '{"device":"load-test-'$i'","kind":"info","payload":{"test":true}}'
done
```

---

## 📊 Monitoring & Observability

### Application Insights

Monitor your deployment:

1. **Azure Portal** → **Application Insights** → **reportmate-ai**
2. **Key metrics**:
   - Request rate and response times
   - Failed requests and exceptions
   - Real-time SignalR connections
   - Container resource usage

### Container Logs

```bash
# View container logs
az containerapp logs show \
  --name reportmate-frontend \
  --resource-group Reportmate \
  --follow

# Function logs
az functionapp logs tail \
  --name reportmate-api \
  --resource-group Reportmate
```

### Database Monitoring

```bash
# Connection statistics
az postgres flexible-server show \
  --name reportmate-db \
  --resource-group Reportmate

# Query performance
# Available in Azure Portal → PostgreSQL → Monitoring
```

---

## 🔧 Configuration Options

### Infrastructure Customization

Update `infrastructure/terraform.tfvars`:

```hcl
# Basic configuration
db_username = "reportmate"
db_password = "YourSecurePassword123!"

# Container configuration
frontend_image_tag = "latest"
functions_image_tag = "latest"

# Pipeline integration
enable_pipeline_permissions = true
pipeline_service_principal_id = "your-service-principal-object-id"

# Environment customization
allowed_ips = ["0.0.0.0/0"]  # Restrict in production
```

### Frontend Configuration

Update `apps/www/.env.production`:

```bash
# API endpoint
NEXT_PUBLIC_API_BASE_URL=https://reportmate-api.azurewebsites.net

# Real-time features
NEXT_PUBLIC_ENABLE_SIGNALR=true
NEXT_PUBLIC_WPS_URL=wss://reportmate-signalr.webpubsub.azure.com/client/hubs/fleet

# UI configuration
NEXT_PUBLIC_THEME=dark
NEXT_PUBLIC_REFRESH_INTERVAL=5000
```

---

## 🆘 Troubleshooting

### Common Deployment Issues

**"The subscription could not be found"**
```bash
# Verify subscription
az account show
az account list --output table

# Set correct subscription  
az account set --subscription "your-subscription-id"
```

**"Insufficient privileges to complete the operation"**
```bash
# Check permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# Required roles:
# - Contributor (for resource management)
# - User Access Administrator (for RBAC assignments)
```

**"Container registry login fails"**
```bash
# Verify ACR exists
az acr list --query "[?name=='reportmateacr']"

# Login to ACR
az acr login --name reportmateacr

# Check permissions
az role assignment list --scope "/subscriptions/{subscription}/resourceGroups/Reportmate/providers/Microsoft.ContainerRegistry/registries/reportmateacr"
```

**"Terraform backend access denied"**
```bash
# Create terraform state storage
az group create --name tfstate-rg --location "Canada Central"
az storage account create --name tfstatestorage$(date +%s) --resource-group tfstate-rg --sku Standard_LRS
az storage container create --name tfstate --account-name [storage-account-name]
```

### Pipeline Issues

**"Variable group not found"**
- Verify variable group name matches pipeline YAML
- Check pipeline has permissions to access variable group
- Ensure variables are correctly marked as secrets

**"Service connection authentication fails"**
- Check service principal expiration
- Verify service connection scope includes target subscription
- Test connection in Azure DevOps UI

### Runtime Issues

**"Dashboard not loading"**
```bash
# Check container status
az containerapp show --name reportmate-frontend --resource-group Reportmate

# View logs
az containerapp logs show --name reportmate-frontend --resource-group Reportmate --tail 50
```

**"API not responding"**
```bash
# Check function app status
az functionapp show --name reportmate-api --resource-group Reportmate --query "state"

# Test function directly
curl https://reportmate-api.azurewebsites.net/api/negotiate
```

**"Real-time updates not working"**
- Verify Web PubSub connection string
- Check SignalR negotiation endpoint
- Confirm client authentication token

---

## 🎉 Deployment Complete!

Your Reportmate deployment is now ready for enterprise device management:

### ✅ What You Have
- **Scalable infrastructure** with auto-scaling Container Apps
- **Secure authentication** with managed identity (zero hardcoded secrets)
- **Real-time dashboard** with WebSocket connections
- **Comprehensive monitoring** with Application Insights
- **CI/CD pipeline** for continuous deployment
- **Database with schema** ready for device data

### 🚀 Next Steps
1. **Connect your devices** to the ingestion API
2. **Monitor dashboard** for real-time updates
3. **Scale resources** based on device volume
4. **Customize widgets** for your specific needs
5. **Set up alerts** for critical events

### 📞 Support
- **Infrastructure Issues**: Check Terraform outputs and Azure Portal
- **Application Issues**: Monitor Application Insights dashboard
- **Pipeline Issues**: Review Azure DevOps pipeline logs
- **General Support**: See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

**Your enterprise-grade device management platform is live!** 🎊
