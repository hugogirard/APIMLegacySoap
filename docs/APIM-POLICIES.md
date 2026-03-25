# Azure API Management Policies Explained

This document provides a detailed explanation of the Azure API Management (APIM) policies used in this solution and how they enable the **passthrough gateway pattern** with intelligent routing.

## Problem & Solution Overview

### The Challenge

When importing SOAP services into Azure API Management, WSDLs containing **external schema references** can be problematic:
- Schema flattening is often required but can be complex and error-prone
- Multi-file WSDL definitions (WSDL with separate XSD files) may not import correctly
- Legacy SOAP services may have complex schema dependencies

### The Solution: APIM Passthrough with External WSDL Storage

This solution implements a **passthrough gateway pattern** that avoids WSDL import complexity:

1. **Store WSDL externally** in Azure Blob Storage (pre-flattened or complete with all schemas)
2. **APIM serves WSDL dynamically** when clients request `?wsdl` (retrieves from blob storage)
3. **APIM passes through SOAP operations** directly to the backend service (on-premises, Azure, or any endpoint)
4. **Additional policies can be layered** on top of the passthrough (rate limiting, auth, transformation, etc.)

### Key Capabilities

The APIM policies in this solution provide:

1. **Dynamic WSDL Serving**: Fetches WSDL from Azure Blob Storage using Managed Identity (workaround for import issues)
2. **SOAP Request Passthrough**: Routes SOAP operations directly to the backend service without modification
3. **Extensibility**: Foundation for adding additional policies without backend changes

## Policy File Location

**File**: `infra/modules/apim/def_policy.xml`

This policy is applied at the **API level** (not global or operation level), specifically to the `BankServiceWSDL` API.

## Complete Policy XML

```xml
<policies>
    <inbound>
        <base />
        <choose>
            <!-- Client wants to get the WSDL definition -->
            <when condition="@(context.Request.Url.Query.ContainsKey("wsdl"))">
                <!-- Get the WSDL definition using the Managed Identity of the APIM -->
                <send-request mode="new" timeout="20" response-variable-name="blobdata" ignore-error="false">
                    <set-url>https://{{storage_name}}.blob.core.windows.net/wsdl/service.wsdl</set-url>
                    <set-method>GET</set-method>
                    <set-header name="x-ms-version" exists-action="override">
                        <value>2019-07-07</value>
                    </set-header>
                    <authentication-managed-identity resource="https://storage.azure.com" />
                </send-request>
                <return-response>
                    <set-status code="200" reason="OK" />
                    <set-header name="Content-Type" exists-action="override">
                        <value>application/xml</value>
                    </set-header>
                    <set-body>@{
                        string wsdlContent = ((IResponse)context.Variables["blobdata"]).Body.As<string>();                
                        return wsdlContent.ToString();
                    }</set-body>
                </return-response>            
            </when>
            <!-- Passthrough the SOAP service (other policies can be defined) -->
            <otherwise>
                <set-backend-service base-url="{{soap_service}}"></set-backend-service>
            </otherwise>
        </choose>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Policy Sections Breakdown

### 1. Inbound Section

The `<inbound>` section processes incoming requests before they reach the backend.

#### Base Policy

```xml
<base />
```

Inherits policies from the parent scope (product and global levels).

#### Conditional Routing with `<choose>`

The policy uses a `<choose>` block (similar to switch/case) to route requests based on query parameters.

```xml
<choose>
    <when condition="...">...</when>
    <otherwise>...</otherwise>
</choose>
```

### 2. WSDL Request Handling

#### Condition Detection

```xml
<when condition="@(context.Request.Url.Query.ContainsKey("wsdl"))">
```

**What it does:**
- Uses APIM policy expression (C# syntax) prefixed with `@`
- Checks if the request URL contains a query parameter named `wsdl`
- Matches: `https://apim-xxx.azure-api.net/bank?wsdl`
- Matches: `https://apim-xxx.azure-api.net/bank?wsdl&someOtherParam=value`

**Why?**
- SOAP clients typically request WSDL using `?wsdl` or `?WSDL` query parameter
- This enables the policy to intercept WSDL requests and serve them dynamically

#### Fetching WSDL from Blob Storage

```xml
<send-request mode="new" timeout="20" response-variable-name="blobdata" ignore-error="false">
```

**Attributes:**
- `mode="new"`: Creates a new HTTP request independently of the current request
- `timeout="20"`: Request timeout in seconds
- `response-variable-name="blobdata"`: Stores response in a variable named `blobdata`
- `ignore-error="false"`: Fails the request if blob retrieval fails

##### Setting Request URL

```xml
<set-url>https://{{storage_name}}.blob.core.windows.net/wsdl/service.wsdl</set-url>
```

**Template Variable**: `{{storage_name}}`
- Replaced at deployment time using Bicep `replace()` function
- Actual value: Storage account name (e.g., `strabc123def`)
- Full URL: `https://strabc123def.blob.core.windows.net/wsdl/service.wsdl`

##### HTTP Method

```xml
<set-method>GET</set-method>
```

Uses HTTP GET to retrieve the blob (standard blob storage access).

##### Blob Storage API Version Header

```xml
<set-header name="x-ms-version" exists-action="override">
    <value>2019-07-07</value>
</set-header>
```

**Purpose**: Required by Azure Blob Storage REST API  
**Version**: `2019-07-07` (stable version)  
**Action**: Overrides any existing header

##### Managed Identity Authentication

```xml
<authentication-managed-identity resource="https://storage.azure.com" />
```

**Critical Security Feature:**
- Authenticates using APIM's system-assigned managed identity
- No credentials stored in policy or configuration
- `resource`: OAuth2 resource identifier for Azure Storage
- RBAC permission: APIM identity must have "Storage Blob Data Owner" role

**How it works:**
1. APIM requests token from Azure AD for `https://storage.azure.com`
2. Azure AD validates APIM's managed identity
3. Token is included in request to Blob Storage as `Authorization: Bearer {token}`
4. Blob Storage validates token and checks RBAC permissions

#### Returning WSDL to Client

```xml
<return-response>
    <set-status code="200" reason="OK" />
    <set-header name="Content-Type" exists-action="override">
        <value>application/xml</value>
    </set-header>
    <set-body>@{
        string wsdlContent = ((IResponse)context.Variables["blobdata"]).Body.As<string>();                
        return wsdlContent.ToString();
    }</set-body>
</return-response>
```

**`<return-response>`**: Short-circuits the policy pipeline and returns immediately (doesn't call backend)

##### Response Status
```xml
<set-status code="200" reason="OK" />
```
Returns HTTP 200 OK status.

##### Content-Type Header
```xml
<set-header name="Content-Type" exists-action="override">
    <value>application/xml</value>
</set-header>
```
Sets proper content type for WSDL (XML format).

##### Response Body
```xml
<set-body>@{
    string wsdlContent = ((IResponse)context.Variables["blobdata"]).Body.As<string>();                
    return wsdlContent.ToString();
}</set-body>
```

**Policy Expression (C# code):**
1. Retrieves the `blobdata` variable (from `send-request`)
2. Casts to `IResponse` interface
3. Gets the response body as a string
4. Returns the WSDL content

**Result**: Client receives the WSDL file stored in blob storage

### 3. SOAP Request Passthrough

```xml
<otherwise>
    <set-backend-service base-url="{{soap_service}}"></set-backend-service>
</otherwise>
```

**When executed**: Request does NOT contain `?wsdl` parameter (normal SOAP operation call)

**The Passthrough Pattern:**
This is the core of the passthrough approach - APIM simply forwards SOAP requests to the backend without modification. The backend service remains unchanged and unaware of APIM.

**Template Variable**: `{{soap_service}}`
- Replaced with APIM named value at deployment
- **Example**: `https://soap-api-{uniqueId}.azurewebsites.net` (Azure App Service)
- Source: Bicep parameter `webAppBackendEndpoint`

**Backend Flexibility:**
The backend can be hosted anywhere:
- ✅ **Azure App Service** (as shown in this example)
- ✅ **On-premises SOAP service** (via VPN, ExpressRoute, or public endpoint)
- ✅ **Third-party SOAP service**
- ✅ **Legacy systems** in your datacenter
- ✅ **Any HTTPS-accessible SOAP endpoint**

**Effect**: Routes the request to the backend SOAP service with zero transformation (pure passthrough)

**Extensibility**: You can add additional policies before or after this passthrough:
- Rate limiting: `<rate-limit calls="100" renewal-period="60" />`
- Authentication: `<validate-jwt>`, `<check-header>`, etc.
- Transformation: `<xsl-transform>`, `<set-body>`, etc.
- Logging: `<trace>`, `<log-to-eventhub>`, etc.

### 4. Backend Section

```xml
<backend>
    <base />
</backend>
```

**Purpose**: Handles request forwarding to backend  
**Action**: Inherits default behavior (forwards request to URL set by `set-backend-service`)

### 5. Outbound Section

```xml
<outbound>
    <base />
</outbound>
```

**Purpose**: Processes the response from backend before returning to client  
**Action**: Inherits default behavior (no response transformation)

**Potential Enhancements:**
- Response caching
- Response transformation
- Header manipulation
- Rate limiting information

### 6. On-Error Section

```xml
<on-error>
    <base />
</on-error>
```

**Purpose**: Handles errors during policy execution  
**Action**: Inherits default error handling

**Potential Enhancements:**
- Custom error messages
- Error logging to Application Insights
- Fallback behaviors

