# 🚀 Seemianki Production Deployment Guide

## Overview

This guide will help you deploy the Seemianki real-time security events dashboard to production using Terraform and Azure DevOps CI/CD.

## Prerequisites

### 1. Azure Setup

- [ ] Azure subscription with appropriate permissions
- [ ] Service Principal for Terraform (with Contributor role)
- [ ] Storage account for Terraform state (if not already created)

### 2. Azure DevOps Setup

- [ ] Azure DevOps project
- [ ] Service connection to Azure subscription
- [ ] Variable groups for secrets

## Step 1: Terraform State Backend Setup

If you haven't already, create a storage account for Terraform state:

```bash
# Create resource group for Terraform state
az group create --name tfstate-rg --location "Canada Central"

# Create storage account
az storage account create \
  --resource-group tfstate-rg \
  --name tfstatestorage$(date +%s) \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstatestorage$(date +%s)
```

## Step 2: Update Terraform Configuration

Update your `infrastructure/terraform.tf` file to include the backend configuration:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "your-terraform-storage-account" # Update this
    container_name        = "tfstate"
    key                   = "seemianki.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

## Step 3: Production-Ready Terraform Updates

### Add Environment Variables

Update `infrastructure/variables.tf`:

```hcl
variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "Canada Central"
}

variable "resource_prefix" {
  type    = string
  default = "seemianki"
}

# Database variables (existing)
variable "db_username" {
  type    = string
  default = "seemianki"
}

variable "db_password" {
  type      = string
  sensitive = true
}
```

### Update Resource Names for Production

Update `infrastructure/main.tf` to use consistent naming:

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "Seemianki"
    GitOps      = "Terraformed"
  }
  
  resource_suffix = "${var.resource_prefix}-${var.environment}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_suffix}"
  location = var.location
  tags     = local.common_tags
}

# Update all other resources to use local.resource_suffix
# and local.common_tags
```

## Step 4: Azure DevOps Pipeline Variables

Create these variable groups in Azure DevOps:

### Variable Group: `Seemianki-Production`

- `azureSubscription`: Your Azure service connection name
- `terraformBackendResourceGroup`: tfstate-rg
- `terraformBackendStorageAccount`: your-terraform-storage-account
- `terraformBackendContainerName`: tfstate
- `terraformBackendKey`: seemianki.tfstate
- `functionAppName`: seemianki-api
- `DB_PASSWORD`: (secret) Your database password

## Step 5: Simplified Azure DevOps Pipeline

Create `pipelines/azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main

variables:
  - group: Seemianki-Production
  - name: vmImageName
    value: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildAll
        pool:
          vmImage: $(vmImageName)
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '18.x'
          
          - script: |
              npm install -g pnpm
              cd apps/www
              pnpm install
              pnpm run build
            displayName: 'Build Dashboard'
          
          - task: UsePythonVersion@0
            inputs:
              versionSpec: '3.11'
          
          - script: |
              cd functions
              pip install -r requirements.txt
            displayName: 'Install Function Dependencies'
          
          - script: |
              mkdir -p $(Build.ArtifactStagingDirectory)/dashboard
              cp -r apps/www/* $(Build.ArtifactStagingDirectory)/dashboard/
              
              mkdir -p $(Build.ArtifactStagingDirectory)/functions
              cp -r functions/* $(Build.ArtifactStagingDirectory)/functions/
              
              mkdir -p $(Build.ArtifactStagingDirectory)/infrastructure
              cp -r infrastructure/* $(Build.ArtifactStagingDirectory)/infrastructure/
            displayName: 'Prepare Artifacts'
          
          - task: PublishBuildArtifacts@1
            inputs:
              pathtoPublish: '$(Build.ArtifactStagingDirectory)'
              artifactName: 'seemianki-artifacts'

  - stage: Deploy
    jobs:
      - deployment: DeployProduction
        environment: 'Production'
        pool:
          vmImage: $(vmImageName)
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadBuildArtifacts@0
                  inputs:
                    buildType: 'current'
                    downloadType: 'single'
                    artifactName: 'seemianki-artifacts'
                    downloadPath: '$(Pipeline.Workspace)'
                
                - script: |
                    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                    sudo apt update && sudo apt install terraform
                  displayName: 'Install Terraform'
                
                - task: AzureCLI@2
                  inputs:
                    azureSubscription: $(azureSubscription)
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      cd $(Pipeline.Workspace)/seemianki-artifacts/infrastructure
                      
                      terraform init \
                        -backend-config="resource_group_name=$(terraformBackendResourceGroup)" \
                        -backend-config="storage_account_name=$(terraformBackendStorageAccount)" \
                        -backend-config="container_name=$(terraformBackendContainerName)" \
                        -backend-config="key=$(terraformBackendKey)"
                      
                      terraform validate
                      terraform plan -var="db_password=$(DB_PASSWORD)" -out=tfplan
                      terraform apply -auto-approve tfplan
                  displayName: 'Deploy Infrastructure'
                
                - task: AzureFunctionApp@1
                  inputs:
                    azureSubscription: $(azureSubscription)
                    appType: 'functionAppLinux'
                    appName: $(functionAppName)
                    package: '$(Pipeline.Workspace)/seemianki-artifacts/functions'
                    runtimeStack: 'PYTHON|3.11'
                  displayName: 'Deploy Functions'
```

## Step 6: Production Configuration

### Environment Variables for Dashboard

Update `apps/www/.env.production`:

```bash
NEXT_PUBLIC_WPS_URL=wss://seemianki-signalr.webpubsub.azure.com/client/hubs/fleet
NEXT_PUBLIC_ENABLE_SIGNALR=true
NEXT_PUBLIC_API_BASE_URL=https://seemianki-api.azurewebsites.net
```

### Function App Settings

Your Terraform already configures these, but verify they're set:

- `EVENTS_CONNECTION`: Web PubSub connection string
- `DATABASE_URL`: PostgreSQL connection string
- `AZURE_STORAGE_CONNECTION_STRING`: Storage account connection
- `QUEUE_NAME`: osquery-ingest

## Step 7: Database Schema Setup

Create a migration script `infrastructure/db-setup.sql`:

```sql
-- Events table for generic events
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY,
    device VARCHAR(255) NOT NULL,
    kind VARCHAR(100) NOT NULL,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cimian runs table for specific cimian events
CREATE TABLE IF NOT EXISTS cimian_runs (
    id UUID PRIMARY KEY,
    device VARCHAR(255) NOT NULL,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_code INTEGER,
    duration INTEGER,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device, ts DESC);
CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
CREATE INDEX IF NOT EXISTS idx_cimian_runs_device_ts ON cimian_runs(device, ts DESC);
```

Run this after Terraform deployment:

```bash
# Connect to your PostgreSQL and run the schema
psql "postgresql://seemianki:your-password@seemianki-database.postgres.database.azure.com:5432/postgres?sslmode=require" -f infrastructure/db-setup.sql
```

## Step 8: Deployment Checklist

### Pre-Deployment

- [ ] Update service connection name in pipeline variables
- [ ] Set DB_PASSWORD in Azure DevOps variable group
- [ ] Update Terraform backend storage account name
- [ ] Verify Azure subscription permissions

### Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform validate
terraform plan -var="db_password=your-secure-password"
terraform apply
```

### Deploy Applications

- [ ] Push code to Azure DevOps repository
- [ ] Run the Azure Pipeline
- [ ] Verify Function App deployment
- [ ] Test SignalR connection from dashboard

### Post-Deployment Verification

- [ ] Test `/api/negotiate` endpoint returns valid tokens
- [ ] Send test event via `/api/test` endpoint
- [ ] Verify events appear in PostgreSQL database
- [ ] Confirm real-time updates work in dashboard
- [ ] Check Application Insights for telemetry

## Step 9: Production URLs

After deployment, your production URLs will be:

- **Dashboard**: `https://seemianki-dashboard.azurestaticapps.net` (or your chosen domain)
- **API**: `https://seemianki-api.azurewebsites.net`
- **Monitor**: Azure Portal → Application Insights

## Step 10: Ongoing Operations

### Monitoring

- Set up alerts in Application Insights
- Monitor Function App performance
- Track Web PubSub connection metrics
- Monitor PostgreSQL performance

### Security

- Enable Azure Key Vault for sensitive configuration
- Set up managed identities between services
- Configure network security groups if needed
- Regularly update dependencies

### Scaling

- Monitor concurrent SignalR connections
- Scale Function App consumption plan as needed
- Consider upgrading Web PubSub SKU for higher throughput
- Optimize PostgreSQL performance with proper indexing

## Troubleshooting

### Common Issues

1. **SignalR not connecting**: Check Web PubSub connection string and tokens
2. **Function deployment fails**: Verify Python version and dependencies
3. **Database connection errors**: Check firewall rules and connection strings
4. **Terraform state lock**: Manually unlock or check Azure DevOps pipeline concurrency

### Debug Commands

```bash
# Check Function App logs
az functionapp logs tail --name seemianki-api --resource-group rg-seemianki-prod

# Test Web PubSub connection
curl -X GET "https://seemianki-api.azurewebsites.net/api/negotiate?device=test"

# Check database connectivity
psql "postgresql://seemianki:password@seemianki-database.postgres.database.azure.com:5432/postgres?sslmode=require" -c "SELECT 1;"
```

---

🎉 **Congratulations!** Your real-time security events dashboard is now production-ready with proper CI/CD, monitoring, and scalability!
