# Legacy SOAP WCF Service on Azure with API Management

This solution demonstrates how to modernize and expose a legacy WCF SOAP service through Azure API Management (APIM), enabling secure access, WSDL hosting, and seamless integration with modern applications.

## 🎯 What This Solution Provides

- **Legacy WCF SOAP Service** hosted on Azure App Service
- **Azure API Management** as a secure gateway for the SOAP service
- **WSDL Hosting** via Azure Blob Storage with managed identity authentication
- **Complete Infrastructure as Code** using Bicep
- **Automated Deployment** with simple Makefile commands

## 📚 Documentation

### Quick Start
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Step-by-step deployment instructions using `make deploy-all`

### Architecture & Design
- **[Azure Architecture](docs/ARCHITECTURE.md)** - Complete overview of all Azure resources created
- **[APIM Policies Explained](docs/APIM-POLICIES.md)** - How the API Management policies work

### Configuration & Usage
- **[Configuration Guide](docs/CONFIGURATION.md)** - How to customize environment name, location, and URLs
- **[Client Usage Guide](docs/CLIENT-USAGE.md)** - How to consume the WCF service through APIM

## 🚀 Quick Deployment

The fastest way to deploy the entire solution:

```bash
make deploy-all
```

This single command will:
1. Deploy all Azure infrastructure (APIM, App Service, Storage)
2. Upload the WSDL definition to blob storage
3. Deploy the WCF SOAP service application

> See the [Deployment Guide](docs/DEPLOYMENT.md) for detailed instructions and alternative deployment options.

## 🏗️ Azure Resources Created

This solution deploys the following Azure resources:

| Resource Type | Purpose |
|--------------|---------|
| **Azure API Management** | Acts as a secure gateway and WSDL proxy for the SOAP service |
| **Azure App Service** | Hosts the legacy WCF SOAP service |
| **Azure Blob Storage** | Stores and serves the WSDL definition file |
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
- **Direct SOAP Service**: `https://soap-api-{uniqueid}.azurewebsites.net/Service.svc`

> The actual URLs are displayed after deployment. See [Client Usage Guide](docs/CLIENT-USAGE.md) for consumption examples.

## 🎯 Bank Service API

The solution includes a sample Bank Service with the following operations:

- `GetBalance(accountNumber)` - Retrieve account balance
- `Deposit(accountNumber, amount)` - Deposit funds
- `Withdraw(accountNumber, amount)` - Withdraw funds
- `GetAccountInfo(accountNumber)` - Get complete account information

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

## 🔐 Security Features

- **Managed Identity**: APIM uses system-assigned managed identity for secure storage access
- **HTTPS Only**: All endpoints enforce HTTPS
- **RBAC**: Fine-grained access control using Azure role assignments
- **No Subscription Keys Required**: Simplified access for legacy SOAP clients

## 📞 Support

For issues or questions:
1. Check the [Configuration Guide](docs/CONFIGURATION.md) for common customization scenarios
2. Review [APIM Policies](docs/APIM-POLICIES.md) to understand the request flow
3. Consult the [Client Usage Guide](docs/CLIENT-USAGE.md) for integration examples

## 📄 License

See [LICENSE](LICENSE) file for details.

---

**Next Steps**: Start with the [Deployment Guide](docs/DEPLOYMENT.md) to get your solution running in Azure.
