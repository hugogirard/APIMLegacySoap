# Azure Architecture

This document explains the complete Azure infrastructure deployed by this solution and how all components work together.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                       │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Resource Group: rg-{environmentName}           │ │
│  │                                                              │ │
│  │   ┌──────────────────────────────────────────────────┐    │ │
│  │   │  Azure API Management (apim-{uniqueId})          │    │ │
│  │   │  ┌────────────────────────────────────────────┐  │    │ │
│  │   │  │ BankService API                            │  │    │ │
│  │   │  │ Path: /bank                                │  │    │ │
│  │   │  │ - WSDL Request Detection                   │  │    │ │
│  │   │  │ - Dynamic WSDL Serving from Blob           │  │    │ │
│  │   │  │ - SOAP Request Passthrough                 │  │    │ │
│  │   │  └────────────────────────────────────────────┘  │    │ │
│  │   │                                                    │    │ │
│  │   │  System-assigned Managed Identity ────────┐      │    │ │
│  │   │  (principalId)                             │      │    │ │
│  │   └──────────────────────────────────────────────────┘    │ │
│  │                                                 │           │ │
│  │   ┌─────────────────────────────────────────────────────┐ │ │
│  │   │  Azure Blob Storage (str{uniqueId})               │ │ │
│  │   │  ┌──────────────────────────┐                     │ │ │
│  │   │  │ Container: wsdl          │                     │ │ │
│  │   │  │ - service.wsdl           │◄────────────────────┘ │ │
│  │   │  └──────────────────────────┘     RBAC:            │ │
│  │   │                                  Storage Blob       │ │
│  │   │                                  Data Owner         │ │
│  │   └─────────────────────────────────────────────────────┘ │ │
│  │                                                              │ │
│  │   ┌────────────────────────────────────────────────────┐  │ │
│  │   │  Azure App Service Plan (asp-{uniqueId})           │  │ │
│  │   │  SKU: PremiumV4 (P0V4)                             │  │ │
│  │   │                                                      │  │ │
│  │   │  ┌──────────────────────────────────────────────┐  │  │ │
│  │   │  │ Web App (soap-api-{uniqueId})                │  │  │ │
│  │   │  │ - .NET Framework 4.0                         │  │  │ │
│  │   │  │ - WCF SOAP Service (BankService)             │  │  │ │
│  │   │  │ - Endpoint: /Service.svc                     │  │  │ │
│  │   │  └──────────────────────────────────────────────┘  │  │ │
│  │   │          ▲                                          │  │ │
│  │   └──────────┼──────────────────────────────────────────┘  │ │
│  │              │ Backend URL (set-backend-service)           │ │
│  │              │                                              │ │
│  │   ┌──────────┴──────────────────────────────────────────┐  │ │
│  │   │  APIM Named Value: soap_service                     │  │ │
│  │   │  Value: https://soap-api-{uniqueId}.azurewebsites..│  │ │
│  │   └─────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘

External Clients
    │
    └──> HTTPS Request to:
         https://apim-{uniqueId}.azure-api.net/bank?wsdl
         https://apim-{uniqueId}.azure-api.net/bank (SOAP)
```

## Azure Resources

### 1. Resource Group

**Name**: `rg-{environmentName}`  
**Default**: `rg-legacy-soap-apim`

Contains all resources deployed by this solution. Tagged with:
- `azd-env-name`: Environment identifier
- `SecurityControl`: Ignore (for demo purposes)

### 2. Azure API Management (APIM)

**Resource Name**: `apim-{uniqueId}`  
**SKU**: Standardv2 (configurable: Basicv2, Standardv2, Premiumv2)  
**Purpose**: Acts as a secure gateway and intelligent proxy for the SOAP service

#### Key Features:
- **System-Assigned Managed Identity**: Enables passwordless authentication to Azure resources
- **Developer Portal**: Enabled for API documentation and testing
- **Public Network Access**: Enabled for external client access
- **Gateway URL**: `https://apim-{uniqueId}.azure-api.net`

#### API Configuration:
- **API Name**: BankServiceWSDL
- **API Path**: `/bank`
- **Subscription Required**: No (simplifies legacy SOAP client access)
- **Protocol**: HTTPS only
- **API Format**: OpenAPI (defined in `wcf.yaml`)

#### Named Values:
- **soap_service**: Backend endpoint URL for the WCF service
  - Value: `https://soap-api-{uniqueId}.azurewebsites.net`
  - Used in policies to route requests

### 3. Azure App Service

**App Service Plan**: `asp-{uniqueId}`  
**SKU**: PremiumV4 (P0V4) - Cost-optimized for production workloads

**Web App Name**: `soap-api-{uniqueId}`  
**Purpose**: Hosts the legacy WCF SOAP service

#### Configuration:
- **Runtime**: .NET Framework v4.0
- **Always On**: Enabled (prevents cold starts)
- **HTTPS Only**: Enabled
- **PHP**: Disabled
- **Client Affinity**: Disabled (stateless service)
- **Public Network Access**: Enabled

#### Endpoints:
- **SOAP Service**: `https://soap-api-{uniqueId}.azurewebsites.net/Service.svc`
- **WSDL**: `https://soap-api-{uniqueId}.azurewebsites.net/Service.svc?wsdl`

### 4. Azure Blob Storage

**Storage Account Name**: `str{uniqueId}`  
**Purpose**: Hosts the WSDL definition file for APIM to serve

#### Container:
- **Name**: `wsdl`
- **Access Level**: Private (accessed via Managed Identity)
- **Contents**: `service.wsdl` file

#### Security:
- **RBAC Role Assignment**: APIM's managed identity has "Storage Blob Data Owner" role
- **Authentication**: Managed Identity (passwordless)
- **Network Access**: Public endpoint (secured by RBAC)

### 5. RBAC (Role-Based Access Control)

**Purpose**: Grants APIM permission to read WSDL from Blob Storage

#### Role Assignment:
- **Principal**: APIM System-Assigned Managed Identity
- **Role**: Storage Blob Data Owner (`b7e6dc6d-f1e8-4753-8033-0f276bb0955b`)
- **Scope**: Storage Account
- **Module**: Azure Verified Module (AVM) pattern

## Request Flow Scenarios

### Scenario 1: Client Requests WSDL

```
1. Client → https://apim-{uniqueId}.azure-api.net/bank?wsdl
2. APIM Policy detects ?wsdl query parameter
3. APIM uses Managed Identity to authenticate to Blob Storage
4. APIM retrieves service.wsdl from blob storage
5. APIM returns WSDL to client with Content-Type: application/xml
```

### Scenario 2: Client Sends SOAP Request

```
1. Client → https://apim-{uniqueId}.azure-api.net/bank
   (SOAP envelope in POST body)
2. APIM Policy detects absence of ?wsdl parameter
3. APIM uses soap_service named value as backend
4. APIM forwards request to Azure App Service
5. WCF Service processes SOAP request
6. Response flows back: App Service → APIM → Client
```

## Network Architecture

```
┌─────────────────┐
│  Internet       │
│  Clients        │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────────┐
│  APIM Gateway       │
│  Public Endpoint    │
└────┬───────┬────────┘
     │       │
     │       │ HTTPS + Managed Identity
     │       ▼
     │    ┌──────────────────┐
     │    │  Blob Storage    │
     │    │  (WSDL)          │
     │    └──────────────────┘
     │
     │ HTTPS
     ▼
┌──────────────────────┐
│  App Service         │
│  (WCF SOAP Service)  │
│  Public Endpoint     │
└──────────────────────┘
```

## Resource Naming Convention

All resources use a unique suffix generated from the resource group ID to ensure global uniqueness:

```bicep
var suffix = uniqueString(rg.id)
```

| Resource Type | Naming Pattern |
|--------------|----------------|
| Resource Group | `rg-{environmentName}` |
| API Management | `apim-{suffix}` |
| App Service Plan | `asp-{suffix}` |
| Web App | `soap-api-{suffix}` |
| Storage Account | `str{suffix}` (lowercase, no hyphens) |

## Scale and Performance Considerations

### API Management
- **Standardv2**: Supports up to 99.9% SLA, auto-scaling
- **Capacity**: 1 unit (can be scaled up)
- **Caching**: Not configured (can be added via policies)

### App Service
- **PremiumV4 (P0V4)**: 210 total ACU, 3.5 GB memory
- **Always On**: Prevents cold starts
- **Scale Out**: Manual or auto-scale can be configured

### Blob Storage
- **Access Tier**: Hot (default for wsdl container)
- **Replication**: LRS (Locally Redundant Storage)
- **Performance**: Standard tier

## Security Considerations

1. **No Hardcoded Credentials**: Managed Identity used throughout
2. **HTTPS Everywhere**: All endpoints enforce TLS
3. **RBAC**: Least-privilege access between services
4. **No Public Storage**: WSDL only accessible via APIM with managed identity
5. **API Subscription**: Disabled for backward compatibility (can be enabled)

## Cost Optimization Tips

1. **APIM SKU**: Start with Basicv2 for dev/test, use Standardv2+ for production
2. **App Service**: P0V4 is cost-optimized; consider Consumption plan for sporadic workloads
3. **Storage**: Use lifecycle policies if storing multiple WSDL versions
4. **Monitoring**: Basic logs are free; configure only needed diagnostics

## Deployment Outputs

After deployment, the following outputs are available (saved to `params` file):

```bash
resourceGroupName=rg-legacy-soap-apim
webAppName=soap-api-{uniqueId}
storageResourceName=str{uniqueId}
containerName=wsdl
webAppHostName=soap-api-{uniqueId}.azurewebsites.net
apimGatewayHostName=https://apim-{uniqueId}.azure-api.net
```

These values are used by deployment scripts and can be referenced for configuration.

---

**Next**: Learn how the [APIM Policies](APIM-POLICIES.md) enable intelligent request routing.
