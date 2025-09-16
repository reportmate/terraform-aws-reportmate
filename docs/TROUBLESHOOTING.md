# 🆘 ReportMate Troubleshooting Guide

Comprehensive troubleshooting and support guide for ReportMate deployment and operation.

## 🚨 Common Issues & Solutions

### Azure Authentication Issues

#### "The subscription could not be found"

**Symptoms**: Pipeline fails with subscription not found error

**Solutions**:
```bash
# Verify current subscription
az account show

# List all subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "your-subscription-id"

# Verify service principal access
az ad sp show --id "your-service-principal-id"
```

#### "Insufficient privileges to complete the operation"

**Symptoms**: Permission denied errors during deployment

**Solutions**:
```bash
# Check current user permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# Required roles for deployment:
# - Contributor (resource management)
# - User Access Administrator (RBAC assignments)

# Assign missing roles
az role assignment create \
  --assignee "your-service-principal-id" \
  --role "Contributor" \
  --scope "/subscriptions/your-subscription-id"

az role assignment create \
  --assignee "your-service-principal-id" \
  --role "User Access Administrator" \
  --scope "/subscriptions/your-subscription-id"
```

---

### Terraform Issues

#### "Backend initialization failed"

**Symptoms**: Terraform can't access remote state storage

**Solutions**:
```bash
# Create Terraform state storage account
az group create --name tfstate-rg --location "Canada Central"

az storage account create \
  --name tfstatestorage$(date +%s) \
  --resource-group tfstate-rg \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name [your-storage-account-name]

# Update backend configuration in infrastructure/terraform.tf
# Ensure service principal has "Storage Blob Data Contributor" role
```

#### "Resource already exists"

**Symptoms**: Terraform fails because resources already exist

**Solutions**:
```bash
# Import existing resources
terraform import azurerm_resource_group.rg /subscriptions/{subscription-id}/resourceGroups/ReportMate

# Or destroy and recreate
terraform destroy -auto-approve
terraform apply -auto-approve

# For specific resources
terraform destroy -target=azurerm_container_registry.acr
terraform apply -target=azurerm_container_registry.acr
```

#### "Invalid RBAC role assignment"

**Symptoms**: Role assignment fails during Terraform apply

**Solutions**:
```bash
# Verify managed identity exists
az identity show --name reportmate-identity --resource-group ReportMate

# Check if role assignment already exists
az role assignment list --assignee $(az identity show --name reportmate-identity --resource-group ReportMate --query principalId -o tsv)

# Wait for Azure AD propagation (can take 5-10 minutes)
# Then retry Terraform apply
```

---

### Container Registry Issues

#### "Container registry login fails"

**Symptoms**: Cannot push/pull images from ACR

**Solutions**:
```bash
# Verify ACR exists
az acr list --query "[?name=='reportmateacr']"

# Login to ACR
az acr login --name reportmateacr

# Check ACR permissions
az role assignment list \
  --scope "/subscriptions/{subscription}/resourceGroups/ReportMate/providers/Microsoft.ContainerRegistry/registries/reportmateacr"

# Enable admin access temporarily (for debugging only)
az acr update --name reportmateacr --admin-enabled true
az acr credential show --name reportmateacr
```

#### "Image push/pull fails"

**Symptoms**: Docker operations fail with authentication errors

**Solutions**:
```bash
# Check Docker daemon status
docker info

# Test ACR connectivity
az acr check-health --name reportmateacr

# Manual image push test
docker build -t reportmateacr.azurecr.io/test:latest .
docker push reportmateacr.azurecr.io/test:latest

# Check ACR repositories
az acr repository list --name reportmateacr
```

---

### Azure DevOps Pipeline Issues

#### "Service connection authentication fails"

**Symptoms**: Pipeline cannot authenticate to Azure

**Solutions**:
1. **Check service connection**:
   - Go to Project Settings → Service connections
   - Test the connection
   - Verify expiration date

2. **Recreate service connection**:
   - Delete existing connection
   - Create new automatic service connection
   - Update pipeline YAML with new name

3. **Manual service principal**:
   ```bash
   # Create new service principal
   az ad sp create-for-rbac \
     --name "reportmate-devops-sp-$(date +%s)" \
     --role "Contributor" \
     --scopes "/subscriptions/your-subscription-id"
   ```

#### "Variable group not found"

**Symptoms**: Pipeline fails to find variable group

**Solutions**:
1. **Verify variable group exists**:
   - Go to Library → Variable groups
   - Ensure name matches pipeline YAML exactly

2. **Check permissions**:
   - Variable group → Security
   - Grant pipeline access to variable group

3. **Create missing variable group**:
   ```yaml
   # Required variables:
   DB_PASSWORD: [secret]
   AZURE_SUBSCRIPTION_ID: [your-subscription-id]
   ```

#### "Build agent timeout"

**Symptoms**: Pipeline times out during build

**Solutions**:
```yaml
# Increase timeout in pipeline YAML
jobs:
- job: Build
  timeoutInMinutes: 120  # Increase from default 60
  
  steps:
  # Your build steps
```

---

### Container Apps Issues

#### "Container app startup fails"

**Symptoms**: Container app shows unhealthy status

**Solutions**:
```bash
# Check container app status
az containerapp show \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --query "properties.provisioningState"

# View container logs
az containerapp logs show \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --tail 50

# Check container app revisions
az containerapp revision list \
  --name reportmate-frontend \
  --resource-group ReportMate
```

#### "Container app can't pull images"

**Symptoms**: Container app fails to pull images from ACR

**Solutions**:
```bash
# Verify managed identity has AcrPull role
az role assignment list \
  --assignee $(az identity show --name reportmate-identity --resource-group ReportMate --query principalId -o tsv) \
  --scope $(az acr show --name reportmateacr --resource-group ReportMate --query id -o tsv)

# Test image pull manually
az acr login --name reportmateacr
docker pull reportmateacr.azurecr.io/reportmate-frontend:latest
```

#### "Container app networking issues"

**Symptoms**: Container app can't connect to dependencies

**Solutions**:
```bash
# Check container app environment
az containerapp env show \
  --name reportmate-env \
  --resource-group ReportMate

# Verify ingress configuration
az containerapp ingress show \
  --name reportmate-frontend \
  --resource-group ReportMate

# Test internal connectivity
az containerapp exec \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --command "/bin/sh"
```

---

### Function App Issues

#### "Function app deployment fails"

**Symptoms**: Azure Functions deployment unsuccessful

**Solutions**:
```bash
# Check function app status
az functionapp show \
  --name reportmate-api \
  --resource-group ReportMate \
  --query "state"

# View function app logs
az functionapp logs tail \
  --name reportmate-api \
  --resource-group ReportMate

# Check function app configuration
az functionapp config appsettings list \
  --name reportmate-api \
  --resource-group ReportMate
```

#### "Function app runtime errors"

**Symptoms**: Functions return 500 errors or don't respond

**Solutions**:
```bash
# Check Python runtime version
az functionapp config show \
  --name reportmate-api \
  --resource-group ReportMate \
  --query "pythonVersion"

# Verify required environment variables
az functionapp config appsettings show \
  --name reportmate-api \
  --resource-group ReportMate \
  --setting-names "DATABASE_URL" "EVENTS_CONNECTION"

# Test function locally
cd functions
func start --python
```

---

### Database Issues

#### "Database connection fails"

**Symptoms**: Applications can't connect to PostgreSQL

**Solutions**:
```bash
# Check PostgreSQL server status
az postgres flexible-server show \
  --name reportmate-db \
  --resource-group ReportMate \
  --query "state"

# Test database connectivity
az postgres flexible-server connect \
  --name reportmate-db \
  --admin-user reportmate \
  --database reportmate

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --name reportmate-db \
  --resource-group ReportMate
```

#### "Database schema issues"

**Symptoms**: Database tables missing or incorrect

**Solutions**:
```bash
# Run database setup script
cd scripts
./setup-database.sh

# Manual schema setup
psql $DATABASE_URL -f ../infrastructure/schemas/modular-database-schema.sql

# Check existing tables
psql $DATABASE_URL -c "\dt"
```

---

### Real-time Dashboard Issues

#### "SignalR connection fails"

**Symptoms**: Dashboard doesn't show real-time updates

**Solutions**:
```bash
# Check Web PubSub service
az webpubsub show \
  --name reportmate-signalr \
  --resource-group ReportMate \
  --query "provisioningState"

# Test negotiation endpoint
curl https://reportmate-api.azurewebsites.net/api/negotiate?device=test

# Check Web PubSub connection string
az functionapp config appsettings show \
  --name reportmate-api \
  --resource-group ReportMate \
  --setting-names "EVENTS_CONNECTION"
```

#### "Dashboard not loading"

**Symptoms**: Frontend application won't start or load

**Solutions**:
```bash
# Check frontend container logs
az containerapp logs show \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --tail 100

# Test local development
cd apps/www
pnpm install
pnpm dev

# Check environment variables
az containerapp show \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --query "properties.template.containers[0].env"
```

---

### API Issues

#### "Event ingestion fails"

**Symptoms**: Device events not being received

**Solutions**:
```bash
# Test ingestion endpoint
curl -X POST https://reportmate-api.azurewebsites.net/api/ingest \
  -H "Content-Type: application/json" \
  -d '{"device":"test","kind":"info","payload":{"test":true}}'

# Check queue processing
az storage queue peek \
  --name osquery-ingest \
  --account-name reportmatestorage

# Verify function app logs
az functionapp logs tail \
  --name reportmate-api \
  --resource-group ReportMate
```

#### "API returns 500 errors"

**Symptoms**: API endpoints returning server errors

**Solutions**:
```bash
# Check Application Insights
# Go to Azure Portal → Application Insights → reportmate-ai
# Review failures and exceptions

# Check function-specific logs
az functionapp logs show \
  --name reportmate-api \
  --resource-group ReportMate \
  --function-name ingest

# Test individual functions
curl https://reportmate-api.azurewebsites.net/api/negotiate
curl https://reportmate-api.azurewebsites.net/api/ingest -X POST -d '{}'
```

---

## 🔍 Monitoring & Diagnostics

### Application Insights

**Access**: Azure Portal → Application Insights → reportmate-ai

**Key Metrics to Monitor**:
- Request rate and response times
- Failed requests percentage
- Exceptions and errors
- SignalR connection count
- Database query performance

### Container Logs

```bash
# Real-time logs
az containerapp logs show \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --follow

# Function app logs
az functionapp logs tail \
  --name reportmate-api \
  --resource-group ReportMate \
  --follow
```

### Database Monitoring

```bash
# Connection statistics
az postgres flexible-server show \
  --name reportmate-db \
  --resource-group ReportMate

# Query performance (via Azure Portal)
# PostgreSQL → Query Performance Insight
```

### Resource Health

```bash
# Check all resources in resource group
az resource list \
  --resource-group ReportMate \
  --query "[].{Name:name, Type:type, Status:properties.provisioningState}"
```

---

## 🛠️ Debugging Tools

### Local Development

```bash
# Start full local environment
docker-compose up -d

# Debug specific service
docker-compose logs -f frontend
docker-compose logs -f functions

# Connect to database
docker-compose exec postgres psql -U reportmate -d reportmate
```

### Azure CLI Debugging

```bash
# Enable debug logging
az config set core.only_show_errors=false
az config set logging.enable_log_file=true

# View detailed error messages
az --debug [command]
```

### Terraform Debugging

```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform plan
terraform apply

# Target specific resources
terraform plan -target=azurerm_container_app.frontend
```

---

## 📞 Getting Help

### Azure Support Channels

1. **Azure Portal**: Resource → Support + troubleshooting
2. **Azure CLI**: `az feedback` command
3. **Microsoft Q&A**: [aka.ms/azureqa](https://aka.ms/azureqa)
4. **Azure Documentation**: [docs.microsoft.com/azure](https://docs.microsoft.com/azure)

### Community Resources

1. **GitHub Issues**: Create issue in project repository
2. **Stack Overflow**: Tag questions with `azure` + `reportmate`
3. **Azure DevOps Community**: [developercommunity.visualstudio.com](https://developercommunity.visualstudio.com)

### Emergency Procedures

#### Quick Rollback

```bash
# Rollback container app
az containerapp revision set-active \
  --name reportmate-frontend \
  --resource-group ReportMate \
  --revision [previous-revision-name]

# Rollback function app
az functionapp deployment source config-zip \
  --name reportmate-api \
  --resource-group ReportMate \
  --src [previous-deployment.zip]
```

#### Service Restart

```bash
# Restart container app
az containerapp restart \
  --name reportmate-frontend \
  --resource-group ReportMate

# Restart function app
az functionapp restart \
  --name reportmate-api \
  --resource-group ReportMate
```

---

## 📋 Diagnostic Checklist

### Pre-Deployment Check
- [ ] Azure CLI authenticated
- [ ] Correct subscription selected
- [ ] Service principal permissions verified
- [ ] Terraform backend accessible
- [ ] Variable groups configured

### Post-Deployment Check
- [ ] All resources provisioned successfully
- [ ] RBAC assignments applied
- [ ] Container apps running
- [ ] Function apps responding
- [ ] Database accessible
- [ ] API endpoints working
- [ ] Dashboard loading
- [ ] Real-time updates functioning

### Performance Check
- [ ] Response times under 2 seconds
- [ ] No 500 errors in logs
- [ ] Container resource usage normal
- [ ] Database query performance good
- [ ] SignalR connections stable

---

**Need more help?** Check the [deployment guide](./DEPLOYMENT.md) or [development guide](./DEVELOPMENT.md) for additional context.

Your ReportMate deployment should be running smoothly with these troubleshooting steps! 🎉
