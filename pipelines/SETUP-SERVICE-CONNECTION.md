# 🔐 Azure DevOps Service Connection Setup

Quick reference for setting up Azure service connections for Reportmate CI/CD pipelines.

> **Note**: For complete deployment instructions, see [../docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md)

## � Quick Setup

### Step 1: Create Service Connection

1. **Azure DevOps** → **Project Settings** → **Service connections**
2. **New service connection** → **Azure Resource Manager** → **Service principal (automatic)**
3. **Configure**:
   - **Subscription**: Your Azure subscription
   - **Service connection name**: `reportmate-azure-connection`
   - **Security**: ✅ Grant access permission to all pipelines
4. **Save**

### Step 2: Create Variable Group

1. **Library** → **Variable groups** → **New**
2. **Name**: `reportmate-secrets`
3. **Variables**:
   ```
   DB_PASSWORD: [your-secure-password] (mark as secret)
   AZURE_SUBSCRIPTION_ID: [your-subscription-id]
   ```

### Step 3: Update Pipeline

Update your pipeline YAML:
```yaml
variables:
  azureSubscription: 'reportmate-azure-connection'  # Your connection name
  resourceGroupName: 'Reportmate'
```

## ✅ Required Permissions

The service principal automatically gets these permissions via **Terraform RBAC** (no manual commands needed!):

### Terraform Managed
- ✅ **Storage Queue Data Contributor**
- ✅ **Storage Blob Data Contributor**  
- ✅ **Web PubSub Service Owner**
- ✅ **AcrPull** / **AcrPush**
- ✅ **Monitoring Contributor**
- ✅ **Container Apps Contributor**

### Manual (if needed)
- **Contributor** - Deploy and manage resources
- **User Access Administrator** - Assign roles to managed identities

## 🧪 Test Connection

```bash
# Quick test
az account show
az group show --name Reportmate
```

## 🔧 Troubleshooting

**Connection fails?** → Check service principal expiration in Azure DevOps
**Permission denied?** → Verify Contributor role on subscription
**Variable group not found?** → Ensure exact name match in pipeline YAML

---

**✨ Your Terraform infrastructure handles all the RBAC automatically!**

For complete setup including infrastructure deployment, container configuration, and monitoring, see the [full deployment guide](../docs/DEPLOYMENT.md).
