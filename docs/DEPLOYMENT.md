# Deployment Guide

This guide walks you through deploying the Legacy SOAP WCF Service with Azure API Management.

## Prerequisites

Before deploying, ensure you have:

1. **Azure Subscription** with permissions to:
   - Create resource groups
   - Deploy API Management instances
   - Create App Services and Storage Accounts
   - Assign RBAC roles

2. **Azure CLI** installed and authenticated:
   ```bash
   az --version  # Should be 2.50.0 or higher
   az login
   ```

3. **Make** utility (pre-installed on Linux/macOS)
   ```bash
   make --version
   ```

4. **Git** (to clone the repository)

5. **Active Azure Subscription**:
   ```bash
   az account show
   ```

## Deployment Options

### Option 1: Full Deployment (Recommended)

The simplest way to deploy everything in one command:

```bash
make deploy-all
```

This command executes three steps automatically:
1. **Deploy Infrastructure**: Creates all Azure resources (APIM, App Service, Storage, RBAC)
2. **Upload WSDL**: Uploads the WSDL definition to blob storage
3. **Deploy Application**: Deploys the WCF SOAP service to App Service

**Duration**: Approximately 15-30 minutes (APIM provisioning takes the longest)

### Option 2: Step-by-Step Deployment

For more control, deploy each component separately:

#### Step 1: Deploy Infrastructure

```bash
make deploy
```

This deploys all Azure resources using Bicep templates and saves outputs to the `params` file.

**What gets created:**
- Resource Group
- Azure API Management instance
- App Service Plan and Web App
- Storage Account with WSDL container
- RBAC role assignments
- APIM API and policies

#### Step 2: Upload WSDL

```bash
make upload-wsdl
```

Uploads `infra/modules/web/service.wsdl` to the blob storage container.

#### Step 3: Deploy Application

```bash
make deploy-app
```

Deploys the WCF SOAP service code to Azure App Service using ZIP deployment.

## Makefile Commands Reference

### Available Commands

```bash
make help              # Show all available commands
make login             # Login to Azure and set subscription
make deploy-all        # Full deployment (recommended)
make deploy            # Deploy infrastructure only
make deploy-app        # Deploy WCF application only
make upload-wsdl       # Upload WSDL to storage
make show              # Display deployment outputs
make destroy           # Delete all resources
```

### Command Details

#### `make deploy-all`
- **Purpose**: Complete end-to-end deployment
- **Uses**: `scripts/deploy-all.sh`
- **Duration**: 15-30 minutes
- **Idempotent**: Yes (safe to run multiple times)

#### `make deploy`
- **Purpose**: Deploy Azure infrastructure using Bicep
- **Uses**: `scripts/deploy.sh`
- **Creates**: `params` file with deployment outputs
- **Duration**: 15-25 minutes (APIM is slow to provision)

#### `make deploy-app`
- **Purpose**: Deploy WCF service application code
- **Uses**: `scripts/deploy-app.sh`
- **Requires**: `params` file from `make deploy`
- **Duration**: 2-5 minutes

#### `make upload-wsdl`
- **Purpose**: Upload WSDL file to blob storage
- **Uses**: `scripts/upload-wsdl.sh`
- **Source**: `infra/modules/web/service.wsdl`
- **Destination**: `wsdl/service.wsdl` in blob container

#### `make show`
- **Purpose**: Display current deployment configuration
- **Reads**: `params` file
- **Shows**: Resource names, URLs, container names

#### `make destroy`
- **Purpose**: Delete the entire resource group
- **Confirmation**: Uses `--yes --no-wait` flags
- **Caution**: ⚠️ Permanent deletion!

## Configuration Variables

You can customize the deployment by setting environment variables or editing `infra/main.bicepparam`.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT_NAME` | `legacy-soap-apim` | Environment name used in resource group |
| `LOCATION` | `canadacentral` | Azure region for deployment |
| `APIM_SKU` | `Standardv2` | APIM tier (Basicv2, Standardv2, Premiumv2) |
| `PUBLISHER_EMAIL` | `contoso@noreply.com` | APIM publisher email |
| `PUBLISHER_NAME` | `Contoso` | APIM publisher name |

### Example: Custom Deployment

```bash
# Deploy to a different region with a custom name
ENVIRONMENT_NAME=banking-soap \
LOCATION=eastus \
APIM_SKU=Basicv2 \
make deploy-all
```

Or set them permanently in your shell:

```bash
export ENVIRONMENT_NAME=banking-soap
export LOCATION=eastus
export APIM_SKU=Basicv2
make deploy-all
```

> See [Configuration Guide](CONFIGURATION.md) for detailed customization options.

## Deployment Scripts

The Makefile calls these bash scripts in the `scripts/` directory:

### `scripts/deploy-all.sh`
Orchestrates the full deployment:
```bash
#!/bin/bash
set -e
"$SCRIPT_DIR/deploy.sh"
"$SCRIPT_DIR/upload-wsdl.sh"
"$SCRIPT_DIR/deploy-app.sh"
```

### `scripts/deploy.sh`
Deploys Bicep infrastructure:
```bash
az deployment sub create \
  --name $DEPLOYMENT_NAME \
  --location $LOCATION \
  --template-file $INFRA_DIR/main.bicep \
  --parameters $INFRA_DIR/main.bicepparam \
  --query properties.outputs -o json > params
```

### `scripts/upload-wsdl.sh`
Uploads WSDL to storage:
```bash
az storage blob upload \
  --account-name $STORAGE_NAME \
  --container-name $CONTAINER_NAME \
  --name service.wsdl \
  --file $INFRA_DIR/modules/web/service.wsdl \
  --overwrite
```

### `scripts/deploy-app.sh`
Deploys WCF service:
```bash
cd $SRC_DIR
zip -r package.zip * -x "*.git*"
az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --src-path package.zip \
  --type zip
```

## Post-Deployment Verification

### 1. Check Deployment Outputs

```bash
make show
```

Expected output:
```
resourceGroupName=rg-legacy-soap-apim
webAppName=soap-api-abc123def
storageResourceName=strabc123def
containerName=wsdl
webAppHostName=soap-api-abc123def.azurewebsites.net
apimGatewayHostName=https://apim-abc123def.azure-api.net
```

### 2. Test WSDL Endpoint

```bash
# Get APIM gateway URL from params
APIM_URL=$(cat params | grep apimGatewayHostName | cut -d'=' -f2)

# Test WSDL retrieval (browser or curl)
echo "WSDL URL: ${APIM_URL}/bank?wsdl"
# Open in browser or use: curl -i "${APIM_URL}/bank?wsdl"
```

Expected: HTTP 200 with WSDL XML content

### 3. Test Direct App Service Endpoint

```bash
# Get Web App hostname
WEB_APP=$(cat params | grep webAppHostName | cut -d'=' -f2)

# Test direct SOAP endpoint (browser or curl)
echo "Direct WSDL: https://${WEB_APP}/Service.svc?wsdl"
# Open in browser or use: curl -i "https://${WEB_APP}/Service.svc?wsdl"
```

Expected: HTTP 200 with WSDL XML content

### 4. Verify Storage Access

```bash
# Get storage and container names
STORAGE_NAME=$(cat params | grep storageResourceName | cut -d'=' -f2)
CONTAINER_NAME=$(cat params | grep containerName | cut -d'=' -f2)

# Verify WSDL file exists
az storage blob list \
  --account-name $STORAGE_NAME \
  --container-name $CONTAINER_NAME \
  --output table
```

Expected: `service.wsdl` listed

### 5. Test SOAP Operations with .NET Client

Use the included .NET console client to test all service operations:

```bash
# Navigate to the client directory
cd src/SoapClient/SoapClient

# Update Program.cs with your APIM URL (from 'make show')
# Line ~17: string endpointRemoteAddress = "https://apim-{uniqueId}.azure-api.net/bank";

# Run the client
dotnet run
```

**Interactive Menu:**

```
===========================================
   Welcome to the Banking System Client   
===========================================

Please select an option:
1. Check Balance
2. Deposit Money
3. Withdraw Money
4. View Account Information
5. Exit
```

Test each operation to verify the deployment:
- **GetBalance**: Enter account "12345" to check balance
- **Deposit**: Add funds and verify new balance
- **Withdraw**: Remove funds and verify new balance
- **GetAccountInfo**: View complete account details

Expected: Successful responses for all operations

> See [Client Usage Guide](CLIENT-USAGE.md) for detailed client integration examples.

## Troubleshooting

### APIM Provisioning Takes Long Time

**Issue**: APIM creation takes 15-30 minutes  
**Solution**: This is normal. APIM provisioning is slow by design. Use `Basicv2` for faster dev/test deployments.

### Deployment Fails with "Conflict" Error

**Issue**: Resource already exists  
**Solution**: 
```bash
# Delete the resource group and retry
make destroy
# Wait a few minutes, then redeploy
make deploy-all
```

### "params file not found" Error

**Issue**: `deploy-app` or `upload-wsdl` can't find outputs  
**Solution**: Run infrastructure deployment first:
```bash
make deploy
```

### WSDL Returns 404

**Issue**: APIM can't access blob storage  
**Solution**: 
1. Verify RBAC assignment:
   ```bash
   az role assignment list --scope /subscriptions/{sub-id}/resourceGroups/rg-legacy-soap-apim/providers/Microsoft.Storage/storageAccounts/str{suffix}
   ```
2. Check APIM managed identity is enabled:
   ```bash
   az apim identity show -n apim-{suffix} -g rg-legacy-soap-apim
   ```

### App Service Deployment Fails

**Issue**: ZIP deployment returns error  
**Solution**: 
1. Verify App Service is running:
   ```bash
   az webapp show -n soap-api-{suffix} -g rg-legacy-soap-apim --query state
   ```
2. Check deployment logs:
   ```bash
   az webapp log tail -n soap-api-{suffix} -g rg-legacy-soap-apim
   ```

### Invalid Location Error

**Issue**: Location not available for APIM  
**Solution**: Use one of the allowed locations from `main.bicep`:
- australiaeast, canadacentral, centralus, eastus, eastus2
- francecentral, northeurope, southcentralus, switzerlandnorth
- westeurope, westus2, westus3

## Re-deployment Scenarios

### Update Application Code Only

If you only changed the WCF service code:

```bash
make deploy-app
```

Duration: ~2-5 minutes

### Update Infrastructure Only

If you changed Bicep templates or policies:

```bash
make deploy
```

Duration: ~5-10 minutes (unless APIM SKU changes)

### Update WSDL File

If you modified the WSDL:

```bash
make upload-wsdl
```

Duration: ~30 seconds

### Full Clean Redeployment

```bash
make destroy
# Wait 5-10 minutes for cleanup
make deploy-all
```

## Cost Estimation

Approximate monthly costs (US pricing, as of 2026):

| Resource | SKU | Est. Monthly Cost |
|----------|-----|-------------------|
| API Management | Standardv2 (1 unit) | ~$675 |
| App Service Plan | PremiumV4 P0V4 | ~$85 |
| Storage Account | Standard LRS | ~$0.50 |
| **Total** | | **~$760/month** |

**Cost Savings Tips:**
- Use `Basicv2` APIM SKU for dev/test (~$250/month)
- Use `B1` App Service tier for non-production (~$13/month)
- Delete resources when not in use: `make destroy`

## Next Steps

After successful deployment:

1. **Test the Service**: See [Client Usage Guide](CLIENT-USAGE.md)
2. **Customize Configuration**: See [Configuration Guide](CONFIGURATION.md)
3. **Understand Policies**: See [APIM Policies Explained](APIM-POLICIES.md)

---

**Need Help?** Check the [main README](../README.md) or Azure Portal diagnostics.
