# Legacy SOAP WCF Service on Azure with API Management

This solution demonstrates a **passthrough gateway pattern** using Azure API Management (APIM) to protect and expose legacy SOAP APIs without modifying the underlying service.

## 🎯 Problem Statement

When importing SOAP services into Azure API Management, you may encounter challenges with WSDLs that contain external schema references. Flattening these schemas can be complex and error-prone. Additionally, you may want to:

- Protect legacy SOAP services (on-premises or cloud-hosted) without code changes
- Apply modern API management policies (rate limiting, authentication, monitoring) on top of existing SOAP services
- Provide WSDL discovery without exposing backend infrastructure
- Enable a passthrough approach where APIM acts purely as a secure gateway

## 💡 Solution Approach

This solution demonstrates the **APIM passthrough pattern** with intelligent WSDL serving:

1. **WSDL Storage Workaround**: Instead of importing complex WSDLs with external schemas into APIM, store the WSDL in Azure Blob Storage
2. **Dynamic WSDL Serving**: APIM policies detect `?wsdl` requests and serve the WSDL from blob storage using Managed Identity
3. **SOAP Passthrough**: All SOAP operation requests pass through APIM directly to the backend service (Azure App Service, on-premises, or any SOAP endpoint)
4. **Extensible Policies**: Add additional policies on top of the passthrough (rate limiting, caching, transformation, authentication) without touching the backend

**Key Benefits:**
- ✅ No backend code changes required
- ✅ Works with complex WSDLs containing external schemas
- ✅ Backend can be hosted anywhere (Azure, on-premises, third-party)
- ✅ Apply modern API management capabilities to legacy services
- ✅ Centralized monitoring and governance

## 🏗️ What This Solution Provides

- **Legacy WCF SOAP Service** hosted on Azure App Service (can be adapted for on-premises)
- **Azure API Management** as a passthrough gateway with intelligent routing
- **WSDL Hosting** via Azure Blob Storage with managed identity authentication
- **Custom APIM Policies** for WSDL serving and SOAP passthrough
- **Complete Infrastructure as Code** using Bicep
- **Automated Deployment** with simple Makefile commands

## 📚 Documentation

### Architecture & Design
- **[Azure Architecture](docs/ARCHITECTURE.md)** - Complete overview of all Azure resources created
- **[APIM Policies Explained](docs/APIM-POLICIES.md)** - How the API Management policies work

## 🚀 Quick Deployment

The fastest way to deploy the entire solution:

```bash
make deploy-all
```

This single command will:
1. Deploy all Azure infrastructure (APIM, App Service, Storage)
2. Upload the WSDL definition to blob storage
3. Deploy the WCF SOAP service application

> This is the recommended deployment method. All Azure infrastructure, WSDL storage, and application code are deployed automatically.

## 🏗️ Azure Resources Created

This solution deploys the following Azure resources:

| Resource Type | Purpose |
|--------------|---------|
| **Azure API Management** | Passthrough gateway with intelligent routing and WSDL serving |
| **Azure App Service** | Hosts the legacy WCF SOAP service (can be on-premises in your scenario) |
| **Azure Blob Storage** | Stores and serves the WSDL definition file (workaround for complex schemas) |
| **Managed Identity** | Enables secure authentication between APIM and Storage |
| **RBAC Assignments** | Grants APIM permissions to access blob storage |

> See [Azure Architecture](docs/ARCHITECTURE.md) for detailed architecture diagrams and resource descriptions.

## 📋 Prerequisites

- **Azure Subscription** with permissions to create resources
- **Azure CLI** installed and configured
- **Make** utility (typically pre-installed on Linux/macOS)
- **.NET Framework 4.x** for the WCF service

## 🔧 Common Commands

```bash
# Show all available commands
make help

# Deploy everything (recommended)
make deploy-all

# Deploy only infrastructure
make deploy

# Deploy only the application
make deploy-app

# Upload WSDL to storage
make upload-wsdl

# Show current deployment parameters
make show

# Delete all resources
make destroy
```

## 🌐 Service Endpoints

After deployment, you'll have access to:

- **APIM Gateway URL**: `https://apim-{uniqueid}.azure-api.net/bank`
- **WSDL Endpoint**: `https://apim-{uniqueid}.azure-api.net/bank?wsdl`

> **Always use the APIM Gateway URL** for all client connections. The actual URLs are displayed after deployment with `make show`.

## 🎯 Bank Service API

The solution includes a sample Bank Service with the following operations:

- `GetBalance(accountNumber)` - Retrieve account balance
- `Deposit(accountNumber, amount)` - Deposit funds
- `Withdraw(accountNumber, amount)` - Withdraw funds
- `GetAccountInfo(accountNumber)` - Get complete account information

### Testing the Service

A complete .NET console client is included in `src/SoapClient/SoapClient/` for testing all service operations.

**To use the client:**

1. **Get your APIM Gateway URL** from deployment outputs:
   ```bash
   make show
   # Look for: apimGatewayHostName=https://apim-{uniqueId}.azure-api.net
   ```

2. **Update the endpoint** in `src/SoapClient/SoapClient/Program.cs`:
   ```csharp
   string endpointRemoteAddress = "https://apim-{uniqueId}.azure-api.net/bank";
   ```

3. **Open and run** the client in Visual Studio:
   - Open `src/SoapClient/SoapClient.sln` in Visual Studio
   - Build the solution (F6)
   - Run the application (F5 or Ctrl+F5)

4. **Use the interactive menu** to test operations:
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

See [APIM Policies](docs/APIM-POLICIES.md) to understand how the passthrough gateway works.

## 📖 Project Structure

```
├── infra/                      # Infrastructure as Code (Bicep)
│   ├── main.bicep             # Main deployment template
│   ├── main.bicepparam        # Default parameters
│   └── modules/
│       ├── apim/              # API Management configuration
│       ├── web/               # App Service configuration
│       ├── storage/           # Blob Storage configuration
│       └── rbac/              # Role assignments
├── src/
│   ├── BankService/           # WCF SOAP service source code
│   └── SoapClient/            # Sample client applications
├── scripts/                   # Deployment automation scripts
├── Makefile                   # Simplified deployment commands
└── docs/                      # Documentation (created by this README)
```

## 🔐 Security & Policy Features

This solution demonstrates a **baseline passthrough pattern** that can be extended with additional APIM policies:

**Implemented:**
- **Managed Identity**: APIM uses system-assigned managed identity for secure storage access
- **HTTPS Only**: All endpoints enforce HTTPS
- **RBAC**: Fine-grained access control using Azure role assignments
- **Intelligent Routing**: Dynamic routing based on request type (WSDL vs SOAP operations)

**Extensible - Add Policies On Top:**
- **Rate Limiting**: Throttle requests per consumer or globally
- **Authentication**: Add API keys, OAuth, JWT validation
- **IP Filtering**: Whitelist/blacklist IP addresses
- **Request/Response Transformation**: Modify SOAP messages in transit
- **Caching**: Cache WSDL or SOAP responses
- **Logging & Monitoring**: Send telemetry to Application Insights
- **Content Validation**: Validate SOAP messages against schema

> See [APIM Policies Explained](docs/APIM-POLICIES.md) for details on the current passthrough implementation and how to add additional policies.

## � License

See [LICENSE](LICENSE) file for details.
