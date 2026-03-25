# Azure Architecture

This document explains the complete Azure infrastructure deployed by this solution and how all components work together to implement the **APIM passthrough gateway pattern**.

## Overview

This solution demonstrates how to use Azure API Management as a **passthrough gateway** for legacy SOAP services, addressing the challenge of complex WSDL imports while maintaining full compatibility with existing SOAP clients.

**Key Pattern**: 
- WSDL served from Azure Blob Storage (workaround for WSDLs with external schemas)
- SOAP operations passed through APIM to backend (no transformation)
- Backend can be Azure App Service, on-premises, or any SOAP endpoint
- Additional policies can be layered on top without backend changes

## Architecture Diagram

```mermaid
graph TB
    subgraph Azure["Azure Subscription"]
        subgraph RG["Resource Group: rg-{environmentName}"]
            subgraph APIM["Azure API Management<br/>apim-{uniqueId}"]
                API["BankService API<br/>Path: /bank<br/>- WSDL Request Detection<br/>- Dynamic WSDL Serving<br/>- SOAP Passthrough"]
                MI["System-assigned<br/>Managed Identity"]
            end
            
            subgraph Storage["Azure Blob Storage<br/>str{uniqueId}"]
                Container["Container: wsdl<br/>- service.wsdl"]
            end
            
            subgraph ASP["App Service Plan<br/>asp-{uniqueId}<br/>SKU: PremiumV4 P0V4"]
                WebApp["Web App<br/>soap-api-{uniqueId}<br/>.NET Framework 4.0<br/>WCF SOAP Service<br/>Endpoint: /Service.svc"]
            end
            
            NamedValue["APIM Named Value<br/>soap_service<br/>https://soap-api-{uniqueId}.azurewebsites.net"]
        end
    end
    
    Client["External Clients"] -->|"HTTPS Request<br/>?wsdl or SOAP"| API
    MI -->|"RBAC: Storage Blob Data Owner<br/>Managed Identity Auth"| Container
    API -->|"WSDL Request"| MI
    API -->|"SOAP Request<br/>Backend URL"| NamedValue
    NamedValue -.->|"Routes to"| WebApp
    
    style Client fill:#4A90E2,stroke:#2E5C8A,stroke-width:3px,color:#fff
    style APIM fill:#FFA500,stroke:#CC8400,stroke-width:3px,color:#000
    style Storage fill:#50C878,stroke:#3A9B5C,stroke-width:3px,color:#fff
    style ASP fill:#9370DB,stroke:#6A4FB3,stroke-width:3px,color:#fff
    style MI fill:#FF6B6B,stroke:#CC5555,stroke-width:3px,color:#fff
```

## Network Architecture

```mermaid
graph LR
    Internet["Internet<br/>Clients"] -->|HTTPS| APIM["APIM Gateway<br/>Public Endpoint"]
    APIM -->|"HTTPS +<br/>Managed Identity"| Blob["Blob Storage<br/>WSDL"]
    APIM -->|HTTPS| AppService["App Service<br/>WCF SOAP Service<br/>Public Endpoint"]
    
    style Internet fill:#4A90E2,stroke:#2E5C8A,stroke-width:3px,color:#fff
    style APIM fill:#FFA500,stroke:#CC8400,stroke-width:3px,color:#000
    style Blob fill:#50C878,stroke:#3A9B5C,stroke-width:3px,color:#fff
    style AppService fill:#9370DB,stroke:#6A4FB3,stroke-width:3px,color:#fff
```
