# Configuration Guide

This guide explains how to customize and configure your Azure SOAP service deployment, including changing environment names, URLs, regions, and other settings.

## Configuration Methods

There are two primary ways to configure the deployment:

1. **Environment Variables** (for temporary/one-time changes)
2. **Bicep Parameter File** (for persistent changes)

## Quick Reference

| Setting | Environment Variable | Bicep Parameter | Default Value |
|---------|---------------------|-----------------|---------------|
| Environment Name | `ENVIRONMENT_NAME` | `environmentName` | `legacy-soap-apim` |
| Azure Region | `LOCATION` | `location` | `canadacentral` |
| APIM SKU | `APIM_SKU` | `apimSku` | `Standardv2` |
| Publisher Email | `PUBLISHER_EMAIL` | `publisherEmail` | `contoso@noreply.com` |
| Publisher Name | `PUBLISHER_NAME` | `publisherName` | `Contoso` |

## Method 1: Using Environment Variables

### Temporary Configuration (Single Deployment)

Set environment variables before running `make` commands:

```bash
# Deploy with custom settings
ENVIRONMENT_NAME=banking-api \
LOCATION=eastus \
APIM_SKU=Basicv2 \
PUBLISHER_EMAIL=admin@example.com \
PUBLISHER_NAME="Example Corp" \
make deploy-all
```

### Persistent Session Configuration

Export variables in your shell session:

```bash
# Set variables for the session
export ENVIRONMENT_NAME=banking-api
export LOCATION=eastus
export APIM_SKU=Basicv2
export PUBLISHER_EMAIL=admin@example.com
export PUBLISHER_NAME="Example Corp"

# Deploy (uses exported variables)
make deploy-all
```

### Permanent Configuration (.bashrc / .zshrc)

Add to your shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

```bash
# Azure SOAP Service Configuration
export ENVIRONMENT_NAME=banking-api
export LOCATION=eastus
export APIM_SKU=Standardv2
export PUBLISHER_EMAIL=admin@mycompany.com
export PUBLISHER_NAME="My Company"
```

Reload shell:
```bash
source ~/.bashrc
```

## Method 2: Using Bicep Parameter File

### Edit Parameters File

**File**: `infra/main.bicepparam`

```bicep
using 'main.bicep'

param apimSku = 'Standardv2'
param environmentName = 'legacy-soap-apim'
param location = 'canadacentral'
param publisherEmail = 'contoso@noreply.com'
param publisherName = 'Contoso'
```

### Customize and Deploy

1. Edit `infra/main.bicepparam` with your values:

```bicep
using 'main.bicep'

param apimSku = 'Basicv2'
param environmentName = 'banking-soap-prod'
param location = 'eastus'
param publisherEmail = 'api-admin@mycompany.com'
param publisherName = 'My Company Inc'
```

2. Deploy:

```bash
make deploy-all
```

## Configuration Parameters Explained

### 1. Environment Name

**Parameter**: `environmentName`  
**Variable**: `ENVIRONMENT_NAME`  
**Default**: `legacy-soap-apim`

**Purpose**: Used to name the resource group and as a tag for all resources.

**Constraints**:
- Must be 1-64 characters
- Alphanumeric and hyphens only
- No spaces

**Impact**:
- Resource Group: `rg-{environmentName}`
- Tag: `azd-env-name = {environmentName}`

**Examples**:
```bash
# Development environment
ENVIRONMENT_NAME=soap-dev make deploy-all

# Production environment
ENVIRONMENT_NAME=soap-prod make deploy-all

# Department-specific
ENVIRONMENT_NAME=finance-soap make deploy-all
```

### 2. Azure Region (Location)

**Parameter**: `location`  
**Variable**: `LOCATION`  
**Default**: `canadacentral`

**Purpose**: Specifies the Azure region for all resources.

**Allowed Values**:
- `australiaeast`
- `canadacentral`
- `centralus`
- `eastus`
- `eastus2`
- `francecentral`
- `northeurope`
- `southcentralus`
- `switzerlandnorth`
- `westeurope`
- `westus2`
- `westus3`

**Considerations**:
- Choose region closest to your users for best latency
- Verify APIM availability in the region
- Consider data residency requirements
- Pricing may vary by region

**Example**:
```bash
# Deploy to East US
LOCATION=eastus make deploy-all

# Deploy to Europe
LOCATION=westeurope make deploy-all
```

### 3. APIM SKU (Service Tier)

**Parameter**: `apimSku`  
**Variable**: `APIM_SKU`  
**Default**: `Standardv2`

**Purpose**: Determines the API Management service tier and capabilities.

**Allowed Values**:

| SKU | Capacity | SLA | Est. Monthly Cost | Use Case |
|-----|----------|-----|-------------------|----------|
| `Basicv2` | 10 units | 99.95% | ~$250 | Dev/Test |
| `Standardv2` | 10 units | 99.95% | ~$675 | Production |
| `Premiumv2` | 10 units | 99.99% | ~$3,000 | Enterprise |

**Feature Differences**:

| Feature | Basicv2 | Standardv2 | Premiumv2 |
|---------|---------|------------|-----------|
| Multi-region | ❌ | ❌ | ✅ |
| Custom domains | ❌ | ✅ | ✅ |
| VNet integration | ❌ | ❌ | ✅ |
| Developer portal | ✅ | ✅ | ✅ |
| Caching | ✅ | ✅ | ✅ |
| Scale units | 1-2 | 1-10 | 1-12 |

**Recommendation**:
- **Dev/Test**: Use `Basicv2` to minimize costs
- **Production**: Use `Standardv2` for reliability
- **Enterprise**: Use `Premiumv2` for multi-region and VNet

**Example**:
```bash
# Development (cost-effective)
APIM_SKU=Basicv2 make deploy-all

# Production (recommended)
APIM_SKU=Standardv2 make deploy-all

# Enterprise (high availability)
APIM_SKU=Premiumv2 make deploy-all
```

### 4. Publisher Email

**Parameter**: `publisherEmail`  
**Variable**: `PUBLISHER_EMAIL`  
**Default**: `contoso@noreply.com`

**Purpose**: Email address displayed in the APIM developer portal and used for notifications.

**Constraints**:
- Must be a valid email format
- Used for APIM system notifications
- Visible in developer portal

**Example**:
```bash
PUBLISHER_EMAIL=api-admin@mycompany.com make deploy-all
```

### 5. Publisher Name

**Parameter**: `publisherName`  
**Variable**: `PUBLISHER_NAME`  
**Default**: `Contoso`

**Purpose**: Organization name displayed in the APIM developer portal.

**Constraints**:
- Any string (quotes recommended if spaces)

**Example**:
```bash
PUBLISHER_NAME="Acme Corporation" make deploy-all
```

## Changing the URL Name

The service URLs are determined by the **unique suffix** generated from the resource group ID. You cannot directly control the suffix, but you can influence it by choosing different environment names.

### Understanding URL Generation

```bicep
var suffix = uniqueString(rg.id)
```

The `suffix` is a deterministic hash of the resource group ID, ensuring:
- **Global uniqueness**: No naming conflicts across Azure
- **Consistency**: Same suffix on redeployments to same resource group
- **Unpredictability**: Different for each environment

### Example URLs

| Environment Name | Resource Group | Generated Suffix | APIM URL |
|-----------------|----------------|------------------|----------|
| `legacy-soap-apim` | `rg-legacy-soap-apim` | `abc123def` | `apim-abc123def.azure-api.net` |
| `banking-prod` | `rg-banking-prod` | `xyz789ghi` | `apim-xyz789ghi.azure-api.net` |
| `finance-api` | `rg-finance-api` | `mno456pqr` | `apim-mno456pqr.azure-api.net` |

### Option 1: Use Custom Domain (Recommended)

For branded URLs, configure a custom domain in APIM:

#### Prerequisites
- Registered domain name
- SSL certificate

#### Steps

1. **Create DNS CNAME Record**:
   ```
   api.mycompany.com  →  apim-{suffix}.azure-api.net
   ```

2. **Upload Certificate** (Azure Portal or CLI):
   ```bash
   az apim update \
     --resource-group rg-legacy-soap-apim \
     --name apim-{suffix} \
     --custom-domain-name api.mycompany.com \
     --certificate-path /path/to/cert.pfx \
     --certificate-password "password"
   ```

3. **Update Client URLs**:
   - WSDL: `https://api.mycompany.com/bank?wsdl`
   - Service: `https://api.mycompany.com/bank`

> **Note**: Custom domains require Standardv2 or Premiumv2 SKU.

### Option 2: Change Environment Name

Change the environment name to get a different suffix:

```bash
# Different environment = different suffix
ENVIRONMENT_NAME=banking-api-v2 make deploy-all
```

This creates a new resource group and resources with a different suffix.

### Option 3: Use APIM Named Value Override (Advanced)

Keep the same infrastructure but change the API path:

**Edit**: `infra/modules/apim/soap.bicep`

```bicep
properties: {
  path: 'myservice'  // Change from 'bank' to 'myservice'
  // ...
}
```

**Result**: 
- WSDL: `https://apim-{suffix}.azure-api.net/myservice?wsdl`
- Service: `https://apim-{suffix}.azure-api.net/myservice`

**Deploy**:
```bash
make deploy
```

## Advanced Configuration Scenarios

### Scenario 1: Multi-Environment Setup

Create separate environments for dev, test, and production:

**Development:**
```bash
export ENVIRONMENT_NAME=soap-dev
export LOCATION=eastus
export APIM_SKU=Basicv2
make deploy-all
```

**Staging:**
```bash
export ENVIRONMENT_NAME=soap-staging
export LOCATION=eastus
export APIM_SKU=Standardv2
make deploy-all
```

**Production:**
```bash
export ENVIRONMENT_NAME=soap-prod
export LOCATION=eastus
export APIM_SKU=Premiumv2
make deploy-all
```

### Scenario 2: Regional Deployments

Deploy to multiple regions with region-specific names:

**US East:**
```bash
ENVIRONMENT_NAME=soap-us-east LOCATION=eastus make deploy-all
```

**Europe:**
```bash
ENVIRONMENT_NAME=soap-eu-west LOCATION=westeurope make deploy-all
```

**Canada:**
```bash
ENVIRONMENT_NAME=soap-ca-central LOCATION=canadacentral make deploy-all
```

### Scenario 3: Department-Specific Deployments

```bash
# Finance department
ENVIRONMENT_NAME=finance-soap \
PUBLISHER_NAME="Finance Department" \
make deploy-all

# HR department
ENVIRONMENT_NAME=hr-soap \
PUBLISHER_NAME="Human Resources" \
make deploy-all
```

## Updating Existing Deployments

### Change Configuration After Initial Deployment

1. **Update parameters** (environment variable or `.bicepparam` file)

2. **Redeploy infrastructure**:
   ```bash
   make deploy
   ```

3. **Redeploy application** (if needed):
   ```bash
   make deploy-app
   ```

### Safe Configuration Changes

These can be updated without recreating resources:
- ✅ Publisher Email
- ✅ Publisher Name
- ✅ App Service configuration
- ✅ APIM policies

### Destructive Configuration Changes

These require resource recreation (data loss):
- ⚠️ **Location**: Creates new resources in new region
- ⚠️ **Environment Name**: Creates new resource group
- ⚠️ **APIM SKU**: May cause downtime during tier change

**For destructive changes:**
```bash
# 1. Backup APIM configuration (if needed)
az apim backup ...

# 2. Delete existing deployment
make destroy

# 3. Update configuration

# 4. Redeploy
make deploy-all
```

## Configuration Best Practices

### 1. Use Consistent Naming

```bash
# Good: Clear, consistent pattern
ENVIRONMENT_NAME=myapp-soap-prod

# Bad: Inconsistent, unclear
ENVIRONMENT_NAME=test123
```

### 2. Document Your Configuration

Create a `config.sh` file:

```bash
#!/bin/bash
# Azure SOAP Service Configuration
# Environment: Production
# Last Updated: 2026-03-24

export ENVIRONMENT_NAME=banking-soap-prod
export LOCATION=eastus
export APIM_SKU=Standardv2
export PUBLISHER_EMAIL=api-admin@mycompany.com
export PUBLISHER_NAME="My Company Inc"
```

Use it:
```bash
source config.sh
make deploy-all
```

### 3. Use Different Configs for Environments

```
config-dev.sh
config-staging.sh
config-prod.sh
```

```bash
# Deploy to production
source config-prod.sh
make deploy-all
```

### 4. Version Control Configuration

**DO**:
- ✅ Commit `main.bicep` and `main.bicepparam` to Git
- ✅ Commit `config-*.sh` templates (with placeholder values)

**DON'T**:
- ❌ Commit actual email addresses or sensitive config
- ❌ Commit `params` file (contains generated values)

Add to `.gitignore`:
```
params
config-local.sh
*.local.sh
```

### 5. Use Azure Key Vault for Secrets

For sensitive configuration (API keys, connection strings):

```bicep
// In main.bicep
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

module apim 'modules/apim/apim.bicep' = {
  params: {
    apiKey: kv.getSecret('api-key')
  }
}
```

## Troubleshooting Configuration Issues

### Issue: Deployment Fails with "InvalidParameter"

**Cause**: Invalid value for a parameter  
**Solution**: Check allowed values in `main.bicep`:

```bash
# View allowed locations
grep -A 15 "@allowed" infra/main.bicep
```

### Issue: "Location not available for resource type"

**Cause**: APIM not available in selected region  
**Solution**: Choose a different location from the allowed list

### Issue: Environment Variable Not Applied

**Cause**: Variable not exported or `make` not picking it up  
**Solution**:

```bash
# Verify variable is set
echo $ENVIRONMENT_NAME

# Use inline variable
ENVIRONMENT_NAME=my-env make deploy-all
```

### Issue: Changes Not Reflected After Redeployment

**Cause**: Bicep template is idempotent; no changes detected  
**Solution**:

```bash
# Force redeployment by deleting and recreating
make destroy
make deploy-all
```

## View Current Configuration

### Show Makefile Defaults

```bash
make -n deploy-all
```

### Show Environment Variables

```bash
env | grep -E '(ENVIRONMENT_NAME|LOCATION|APIM_SKU|PUBLISHER)'
```

### Show Deployed Configuration

```bash
# View resource group tags
az group show --name rg-legacy-soap-apim --query tags

# View APIM configuration
az apim show \
  --resource-group rg-legacy-soap-apim \
  --name apim-{suffix} \
  --query '{sku:sku, location:location, publisher:publisherEmail}'
```

### Show Deployment Outputs

```bash
make show
```

## Configuration Checklist

Before deploying to production:

- [ ] Environment name follows naming convention
- [ ] Location chosen for optimal latency
- [ ] APIM SKU appropriate for workload
- [ ] Publisher email is valid and monitored
- [ ] Publisher name represents your organization
- [ ] Configuration documented in version control
- [ ] Backup/disaster recovery plan in place
- [ ] Cost estimation reviewed and approved

## Next Steps

- **Deploy Your Configuration**: [Deployment Guide](DEPLOYMENT.md)
- **Test Your Service**: [Client Usage Guide](CLIENT-USAGE.md)
- **Understand Architecture**: [Azure Architecture](ARCHITECTURE.md)

---

**Questions?** Review the [main README](../README.md) or Azure documentation.
