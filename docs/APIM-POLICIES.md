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

## Request Flow Diagrams

### Flow 1: WSDL Request

```mermaid
sequenceDiagram
    participant Client
    participant APIM as APIM Gateway<br/>&lt;inbound&gt; policy
    participant SendReq as &lt;send-request&gt;<br/>mode="new"
    participant Blob as Blob Storage<br/>/wsdl/service.wsdl
    participant Return as &lt;return-response&gt;
    
    Client->>APIM: GET /bank?wsdl
    Note over APIM: Query.ContainsKey('wsdl') → TRUE
    APIM->>SendReq: Execute policy
    SendReq->>Blob: GET service.wsdl<br/>Header: x-ms-version: 2019-07-07<br/>Auth: Managed Identity
    Blob-->>SendReq: Returns WSDL XML
    SendReq->>Return: Store in variable
    Return-->>Client: HTTP 200<br/>Content-Type: application/xml<br/>WSDL XML content
    Note over Client: Generates client code
```

### Flow 2: SOAP Operation Request

```mermaid
sequenceDiagram
    participant Client
    participant APIM as APIM Gateway<br/>&lt;inbound&gt; policy
    participant Backend as &lt;backend&gt; policy
    participant AppService as Azure App Service<br/>WCF SOAP Service
    participant Outbound as &lt;outbound&gt; policy
    
    Client->>APIM: POST /bank<br/>Content-Type: text/xml<br/>&lt;soap:Envelope&gt;
    Note over APIM: Query.ContainsKey('wsdl') → FALSE
    APIM->>APIM: &lt;set-backend-service&gt;<br/>URL = {{soap_service}}
    APIM->>Backend: Forward request
    Backend->>AppService: POST /Service.svc<br/>SOAP request
    Note over AppService: Process SOAP operation
    AppService-->>Backend: SOAP response
    Backend->>Outbound: Pass response
    Outbound-->>Client: SOAP response (unchanged)
    Note over Client: Receives result
```

## Named Values (Template Variables)

### {{storage_name}}

**Set in**: `infra/modules/apim/soap.bicep`  
**Method**: Bicep `replace()` function during deployment

```bicep
value: replace(loadTextContent('./def_policy.xml'), '{{storage_name}}', storageResourceName)
```

**Runtime Value**: Storage account name (e.g., `strabc123def`)

### {{soap_service}}

**Set as**: APIM Named Value resource  
**Defined in**: `infra/modules/apim/apim.bicep`

```bicep
resource symbolicname 'Microsoft.ApiManagement/service/namedValues@2025-03-01-preview' = {
  parent: apimService
  name: 'soap_service'
  properties: {
    displayName: 'soap_service'
    secret: false
    value: webAppBackendEndpoint
  }
}
```

**Runtime Value**: `https://soap-api-{uniqueId}.azurewebsites.net`

**Why Named Value?**
- Can be updated without redeploying policies
- Supports secrets (though not used here)
- Can be environment-specific

## Security Implications

### ✅ Secure Practices

1. **Managed Identity Authentication**: No credentials in policies or config
2. **RBAC-based Access**: Fine-grained permissions for blob access
3. **HTTPS Enforcement**: All communication encrypted
4. **No Credential Exposure**: Tokens never logged or visible

### ⚠️ Considerations

1. **No Subscription Key**: API is publicly accessible
   - **Pro**: Compatible with legacy SOAP clients
   - **Con**: No built-in throttling per consumer
   - **Mitigation**: Can be enabled if needed

2. **Public Blob Storage Endpoint**: Storage account accessible from internet
   - **Pro**: No network complexity
   - **Con**: Storage endpoint is public (but secured by RBAC)
   - **Mitigation**: Use private endpoints for higher security

3. **Error Messages**: Default error handling may expose internals
   - **Mitigation**: Add custom error policies

## Performance Considerations

### WSDL Requests

- **Latency**: Extra hop to Blob Storage (~50-100ms)
- **Optimization**: Add response caching:

```xml
<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
```

### SOAP Requests

- **Latency**: Direct passthrough, minimal overhead (~10-20ms added by APIM)
- **Optimization**: Already optimal for passthrough scenario

## Policy Enhancements (Optional)

### 1. Add Response Caching for WSDL

```xml
<when condition="@(context.Request.Url.Query.ContainsKey("wsdl"))">
    <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
    <send-request mode="new" timeout="20" response-variable-name="blobdata" ignore-error="false">
        <!-- ... existing code ... -->
    </send-request>
    <return-response>
        <!-- ... existing code ... -->
    </return-response>
    <cache-store duration="3600" />
</when>
```

**Benefit**: WSDL cached for 1 hour, reduces blob storage requests

### 2. Add Request Rate Limiting

```xml
<inbound>
    <rate-limit calls="100" renewal-period="60" />
    <base />
    <!-- ... rest of policy ... -->
</inbound>
```

**Benefit**: Limits requests to 100 per minute per IP

### 3. Add Comprehensive Logging

```xml
<inbound>
    <base />
    <trace source="bank-api-policy" severity="information">
        <message>@($"Request: {context.Request.Method} {context.Request.Url}")</message>
    </trace>
    <!-- ... rest of policy ... -->
</inbound>
```

**Benefit**: Better diagnostics in APIM trace logs

### 4. Add Custom Error Responses

```xml
<on-error>
    <base />
    <set-body>@{
        return new JObject(
            new JProperty("error", context.LastError.Message),
            new JProperty("timestamp", DateTime.UtcNow)
        ).ToString();
    }</set-body>
    <set-header name="Content-Type" exists-action="override">
        <value>application/json</value>
    </set-header>
</on-error>
```

**Benefit**: Structured error responses

## Testing Policies

### Test WSDL Retrieval

```bash
# Open in browser or test with curl
echo "https://apim-{uniqueId}.azure-api.net/bank?wsdl"
```

Expected: WSDL XML document is returned

### Test SOAP Request

Use the included .NET client:

```bash
# Update endpoint in Program.cs to: https://apim-{uniqueId}.azure-api.net/bank
# Open src/SoapClient/SoapClient.sln in Visual Studio
# Run the application and select option 1 to test GetBalance
```

Or use any SOAP client that sends POST requests to the APIM gateway endpoint.

### Test Policy Trace (Azure Portal)

1. Go to APIM instance in Azure Portal
2. Navigate to **APIs** → **BankServiceWSDL**
3. Click **Test** tab
4. Select an operation
5. Click **Trace** to see policy execution steps

## Summary

The APIM policies in this solution provide:

✅ **Intelligent Routing**: WSDL requests go to blob storage, SOAP requests go to backend  
✅ **Secure Access**: Managed identity authentication with RBAC  
✅ **Zero Code Changes**: Legacy SOAP service unaware of APIM  
✅ **Flexibility**: WSDL can be updated independently of service  
✅ **Performance**: Minimal overhead with room for caching optimization  

---

**Next**: Learn how to [consume the service](CLIENT-USAGE.md) from client applications.
