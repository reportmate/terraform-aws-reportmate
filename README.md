# Seemianki Azure DevOps Pipeline Configuration

This directory contains the Azure DevOps CI/CD pipeline configuration for the Seemianki project.

## Pipeline Files

- `azure-pipelines.yml` - Main CI/CD pipeline for production deployment

## Setup Instructions

### 1. Azure DevOps Project Setup

1. Create a new Azure DevOps project or use an existing one
2. Connect your repository to Azure DevOps
3. Set up the pipeline using `pipelines/azure-pipelines.yml`

### 2. Service Connections

Create an Azure Resource Manager service connection:

- Name: `Seemianki-Production` (or update the variable in the pipeline)
- Subscription: Your target Azure subscription
- Service principal: Automatic or manual

### 3. Variable Groups

Create a variable group named `Seemianki-Production` with these variables:

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `azureSubscription` | Your service connection name | No |
| `terraformBackendResourceGroup` | tfstate-rg | No |
| `terraformBackendStorageAccount` | your-terraform-storage-account | No |
| `terraformBackendContainerName` | tfstate | No |
| `terraformBackendKey` | seemianki.tfstate | No |
| `functionAppName` | seemianki-api | No |
| `DB_PASSWORD` | Your secure database password | Yes |

### 4. Environments

Create an environment named `Production` in Azure DevOps:

- Go to Pipelines → Environments
- Create new environment: `Production`
- Add approvals if needed for production deployments

### 5. Pipeline Triggers

The pipeline is configured to trigger on:

- Push to `main` branch
- Push to `develop` branch

## Pipeline Stages

1. **Build** - Builds Next.js dashboard and prepares Azure Functions
2. **Deploy** - Deploys infrastructure with Terraform and applications

## Manual Deployment

For local/manual deployment, use the deployment script in the root directory:

```bash
./deploy.sh
```

## Troubleshooting

### Common Issues

1. **Service connection authentication fails**
   - Verify the service principal has Contributor access to the subscription
   - Check the service connection is not expired

2. **Terraform backend access denied**
   - Ensure the storage account exists and is accessible
   - Verify the service principal has Storage Blob Data Contributor role

3. **Function deployment fails**
   - Check the function app name is unique
   - Verify Python runtime version matches (3.11)

4. **Variable group not found**
   - Ensure the variable group name matches exactly
   - Check the pipeline has access to the variable group

### Pipeline Monitoring

Monitor your pipeline execution in Azure DevOps:

- Go to Pipelines → Recent runs
- Check logs for detailed error information
- Use Application Insights for runtime monitoring

## Security Best Practices

- Use variable groups for sensitive data
- Enable branch policies for main branch
- Set up approval gates for production environment
- Regularly rotate service principal credentials
- Monitor pipeline execution for suspicious activity
