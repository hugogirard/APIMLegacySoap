# Client Usage Guide

This guide explains how to consume the WCF SOAP service through Azure API Management (APIM) from various client applications and platforms.

## Service Endpoints

After deployment, your service is available at the following endpoints:

### APIM Gateway Endpoints (Recommended)

- **WSDL**: `https://apim-{uniqueId}.azure-api.net/bank?wsdl`
- **SOAP Service**: `https://apim-{uniqueId}.azure-api.net/bank`

**Benefits of using APIM:**
- ✅ Centralized access point
- ✅ Policy enforcement (rate limiting, caching, etc.)
- ✅ Monitoring and analytics
- ✅ Decoupling from backend changes

### Direct App Service Endpoints (Not Recommended)

- **WSDL**: `https://soap-api-{uniqueId}.azurewebsites.net/Service.svc?wsdl`
- **SOAP Service**: `https://soap-api-{uniqueId}.azurewebsites.net/Service.svc`

**Use only for:**
- Troubleshooting
- Direct testing during development

## Get Your Service URLs

```bash
# View deployment outputs
make show

# Or extract specific URLs
APIM_URL=$(cat params | grep apimGatewayHostName | cut -d'=' -f2)
echo "WSDL: ${APIM_URL}/bank?wsdl"
echo "Service: ${APIM_URL}/bank"
```

## Service Operations

The Bank Service provides the following operations:

### 1. GetBalance

**Description**: Retrieve account balance  
**Input**: `accountNumber` (string)  
**Output**: `decimal`

### 2. Deposit

**Description**: Deposit funds to account  
**Input**: `accountNumber` (string), `amount` (decimal)  
**Output**: `boolean` (success status)

### 3. Withdraw

**Description**: Withdraw funds from account  
**Input**: `accountNumber` (string), `amount` (decimal)  
**Output**: `boolean` (success status)

### 4. GetAccountInfo

**Description**: Get complete account information  
**Input**: `accountNumber` (string)  
**Output**: `AccountInfo` object with:
- `AccountNumber` (string)
- `AccountHolderName` (string)
- `Balance` (decimal)
- `AccountType` (string)

## Client Implementation Examples

> **⭐ Quick Start**: Use the included [.NET Console Client](#included-net-console-client-recommended-for-testing) for immediate testing of all service operations.

### Included .NET Console Client (Recommended for Testing)

The solution includes a complete **interactive .NET client** for testing all service operations.

**Location**: `src/SoapClient/SoapClient/`

#### Quick Start

1. **Get your APIM Gateway URL**:
   ```bash
   make show
   # Output: apimGatewayHostName=https://apim-{uniqueId}.azure-api.net
   ```

2. **Update endpoint** in `Program.cs` (line ~17):
   ```csharp
   string endpointRemoteAddress = "https://apim-{uniqueId}.azure-api.net/bank";
   ```

3. **Run the client** in Visual Studio:
   - Open `src/SoapClient/SoapClient.sln`
   - Build the solution (F6)
   - Run (F5 or Ctrl+F5)

#### Features

Interactive menu-driven interface:

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

Enter your choice (1-5): 
```

#### Sample Usage

**Check Balance:**
```
Enter your choice (1-5): 1
Enter Account Number: 12345

Current Balance: $1,234.56
```

**Deposit:**
```
Enter your choice (1-5): 2
Enter Account Number: 12345
Enter Deposit Amount: $100

Deposit successful! $100.00 has been added to your account.
New Balance: $1,334.56
```

**View Account Info:**
```
Enter your choice (1-5): 4
Enter Account Number: 12345

===========================================
          Account Information
===========================================
Account Number:    12345
Account Holder:    John Doe
Account Type:      Checking
Current Balance:   $1,334.56
===========================================
```

#### How It Works

The client uses WCF Service Reference:

```csharp
using SoapClient.Bank;

string endpointConfigurationName = "BasicHttpsBinding_IBankService";
string endpointRemoteAddress = "https://apim-{uniqueId}.azure-api.net/bank";

using (var client = new BankServiceClient(endpointConfigurationName, endpointRemoteAddress))
{
    // Check balance
    decimal balance = client.GetBalance("12345");
    
    // Deposit
    bool success = client.Deposit("12345", 100.00m);
    
    // Get account info
    AccountInfo info = client.GetAccountInfo("12345");
}
```

> **Tip**: This client demonstrates best practices for consuming the SOAP service through APIM. Use it as a reference for your own implementation.

---

### .NET Framework (WCF Service Reference)

#### Option 1: Visual Studio Service Reference (Recommended)

1. **Right-click project** → **Add** → **Service Reference**
2. **Address**: `https://apim-{uniqueId}.azure-api.net/bank?wsdl`
3. **Namespace**: `BankServiceReference`
4. Click **Go** → **OK**

**Usage Code:**

```csharp
using System;
using BankServiceReference;

class Program
{
    static void Main(string[] args)
    {
        // Create client using APIM endpoint
        var client = new BankServiceClient();
        
        // Configure endpoint (if not using default)
        client.Endpoint.Address = new EndpointAddress(
            "https://apim-{uniqueId}.azure-api.net/bank"
        );
        
        try
        {
            // Call operations
            decimal balance = client.GetBalance("12345");
            Console.WriteLine($"Balance: {balance:C}");
            
            bool depositSuccess = client.Deposit("12345", 100.00m);
            Console.WriteLine($"Deposit: {depositSuccess}");
            
            var accountInfo = client.GetAccountInfo("12345");
            Console.WriteLine($"Account: {accountInfo.AccountHolderName}");
            Console.WriteLine($"Balance: {accountInfo.Balance:C}");
            Console.WriteLine($"Type: {accountInfo.AccountType}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
        finally
        {
            client.Close();
        }
    }
}
```

#### Option 2: Manual Configuration (App.config)

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.serviceModel>
    <bindings>
      <basicHttpBinding>
        <binding name="BankServiceBinding" maxReceivedMessageSize="2147483647">
          <security mode="Transport">
            <transport clientCredentialType="None" />
          </security>
        </binding>
      </basicHttpBinding>
    </bindings>
    <client>
      <endpoint 
        address="https://apim-abc123def.azure-api.net/bank"
        binding="basicHttpBinding"
        bindingConfiguration="BankServiceBinding"
        contract="BankServiceReference.IBankService"
        name="BankServiceEndpoint" />
    </client>
  </system.serviceModel>
</configuration>
```

### .NET Core / .NET 5+ (Connected Services)

#### Using WCF Connected Service Extension

1. **Install Extension**: WCF Web Service Reference Provider
2. **Right-click project** → **Add** → **Connected Service**
3. **Select**: Microsoft WCF Web Service Reference Provider
4. **URI**: `https://apim-{uniqueId}.azure-api.net/bank?wsdl`
5. Click **Finish**

**Usage Code:**

```csharp
using System;
using System.ServiceModel;
using System.Threading.Tasks;

namespace BankClient
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Configure binding
            var binding = new BasicHttpBinding(BasicHttpSecurityMode.Transport);
            binding.MaxReceivedMessageSize = 2147483647;
            
            // Configure endpoint
            var endpoint = new EndpointAddress(
                "https://apim-{uniqueId}.azure-api.net/bank"
            );
            
            // Create client
            var client = new BankServiceClient(binding, endpoint);
            
            try
            {
                // Call operations asynchronously
                decimal balance = await client.GetBalanceAsync("12345");
                Console.WriteLine($"Balance: {balance:C}");
                
                bool depositSuccess = await client.DepositAsync("12345", 100.00m);
                Console.WriteLine($"Deposit: {depositSuccess}");
                
                var accountInfo = await client.GetAccountInfoAsync("12345");
                Console.WriteLine($"Account: {accountInfo.AccountHolderName}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
            finally
            {
                await client.CloseAsync();
            }
        }
    }
}
```

### Python (zeep library)

#### Installation

```bash
pip install zeep
```

#### Usage Code

```python
from zeep import Client
from zeep.transports import Transport
from requests import Session

# Create session with timeout
session = Session()
session.verify = True  # SSL verification
transport = Transport(session=session, timeout=30)

# Create SOAP client
wsdl_url = "https://apim-{uniqueId}.azure-api.net/bank?wsdl"
client = Client(wsdl=wsdl_url, transport=transport)

# Set service endpoint (override WSDL endpoint with APIM endpoint)
service = client.create_service(
    '{http://tempuri.org/}BasicHttpBinding_IBankService',
    'https://apim-{uniqueId}.azure-api.net/bank'
)

# Call operations
try:
    # GetBalance
    balance = service.GetBalance(accountNumber="12345")
    print(f"Balance: ${balance}")
    
    # Deposit
    deposit_result = service.Deposit(accountNumber="12345", amount=100.00)
    print(f"Deposit success: {deposit_result}")
    
    # GetAccountInfo
    account_info = service.GetAccountInfo(accountNumber="12345")
    print(f"Account Holder: {account_info.AccountHolderName}")
    print(f"Balance: ${account_info.Balance}")
    print(f"Type: {account_info.AccountType}")
    
except Exception as e:
    print(f"Error: {e}")
```

### Java (JAX-WS)

#### Generate Client Classes

```bash
# Using wsimport tool
wsimport -keep -p com.example.bankservice \
  https://apim-{uniqueId}.azure-api.net/bank?wsdl
```

#### Usage Code

```java
package com.example;

import com.example.bankservice.*;
import javax.xml.ws.BindingProvider;
import java.net.URL;

public class BankClient {
    public static void main(String[] args) {
        try {
            // Create service from WSDL
            URL wsdlUrl = new URL("https://apim-{uniqueId}.azure-api.net/bank?wsdl");
            BankService service = new BankService(wsdlUrl);
            IBankService port = service.getBasicHttpBindingIBankService();
            
            // Set endpoint to APIM gateway
            BindingProvider bp = (BindingProvider) port;
            bp.getRequestContext().put(
                BindingProvider.ENDPOINT_ADDRESS_PROPERTY,
                "https://apim-{uniqueId}.azure-api.net/bank"
            );
            
            // Call operations
            double balance = port.getBalance("12345");
            System.out.println("Balance: $" + balance);
            
            boolean depositSuccess = port.deposit("12345", 100.00);
            System.out.println("Deposit success: " + depositSuccess);
            
            AccountInfo accountInfo = port.getAccountInfo("12345");
            System.out.println("Account: " + accountInfo.getAccountHolderName());
            System.out.println("Balance: $" + accountInfo.getBalance());
            
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

### Node.js (soap library)

#### Installation

```bash
npm install soap
```

#### Usage Code

```javascript
const soap = require('soap');

const wsdlUrl = 'https://apim-{uniqueId}.azure-api.net/bank?wsdl';
const serviceEndpoint = 'https://apim-{uniqueId}.azure-api.net/bank';

// Create SOAP client
soap.createClient(wsdlUrl, {}, (err, client) => {
    if (err) {
        console.error('Error creating client:', err);
        return;
    }
    
    // Override endpoint to use APIM gateway
    client.setEndpoint(serviceEndpoint);
    
    // GetBalance
    client.GetBalance({ accountNumber: '12345' }, (err, result) => {
        if (err) {
            console.error('GetBalance error:', err);
            return;
        }
        console.log('Balance:', result.GetBalanceResult);
    });
    
    // Deposit
    client.Deposit({ 
        accountNumber: '12345', 
        amount: 100.00 
    }, (err, result) => {
        if (err) {
            console.error('Deposit error:', err);
            return;
        }
        console.log('Deposit success:', result.DepositResult);
    });
    
    // GetAccountInfo
    client.GetAccountInfo({ accountNumber: '12345' }, (err, result) => {
        if (err) {
            console.error('GetAccountInfo error:', err);
            return;
        }
        const account = result.GetAccountInfoResult;
        console.log('Account Holder:', account.AccountHolderName);
        console.log('Balance:', account.Balance);
        console.log('Type:', account.AccountType);
    });
});
```

### PowerShell

```powershell
# Define SOAP envelope
$soapEnvelope = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
               xmlns:tem="http://tempuri.org/">
  <soap:Body>
    <tem:GetBalance>
      <tem:accountNumber>12345</tem:accountNumber>
    </tem:GetBalance>
  </soap:Body>
</soap:Envelope>
"@

# Make SOAP request
$uri = "https://apim-{uniqueId}.azure-api.net/bank"
$headers = @{
    "Content-Type" = "text/xml; charset=utf-8"
    "SOAPAction" = "http://tempuri.org/IBankService/GetBalance"
}

try {
    $response = Invoke-WebRequest -Uri $uri -Method Post -Body $soapEnvelope -Headers $headers
    
    # Parse SOAP response
    [xml]$xmlResponse = $response.Content
    $balance = $xmlResponse.Envelope.Body.GetBalanceResponse.GetBalanceResult
    Write-Host "Balance: $$balance"
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
}
```

## Testing with SOAP UI

### Setup

1. **Download**: [SoapUI](https://www.soapui.org/downloads/soapui/)
2. **New SOAP Project**
3. **Initial WSDL**: `https://apim-{uniqueId}.azure-api.net/bank?wsdl`
4. **Project Name**: BankService

### Configure Endpoint

1. Right-click project → **Show Service Viewer**
2. Double-click endpoint
3. Change to: `https://apim-{uniqueId}.azure-api.net/bank`

### Test Operations

1. Expand **BankServiceWSDL** → **BankServiceSoap** → **GetBalance**
2. Double-click **Request 1**
3. Fill in the request:
   ```xml
   <tem:accountNumber>12345</tem:accountNumber>
   ```
4. Click green **Play** button

## Testing with Postman

### Import WSDL

1. **Import** → **Link**
2. **URL**: `https://apim-{uniqueId}.azure-api.net/bank?wsdl`
3. **Import as**: OpenAPI 3.0 (Postman converts WSDL)

### Manual SOAP Request

1. **New Request** → **POST**
2. **URL**: `https://apim-{uniqueId}.azure-api.net/bank`
3. **Headers**:
   - `Content-Type`: `text/xml; charset=utf-8`
   - `SOAPAction`: `http://tempuri.org/IBankService/GetBalance`
4. **Body** → **raw** → **XML**:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
     <soap:Body>
       <tem:GetBalance>
         <tem:accountNumber>12345</tem:accountNumber>
       </tem:GetBalance>
     </soap:Body>
   </soap:Envelope>
   ```

## Common Issues and Solutions

### Issue 1: SSL Certificate Errors

**Error**: "The SSL connection could not be established"

**Solution**:
```csharp
// .NET: Bypass SSL validation (DEV ONLY - DO NOT USE IN PRODUCTION)
ServicePointManager.ServerCertificateValidationCallback = 
    (sender, certificate, chain, sslPolicyErrors) => true;
```

```python
# Python: Disable SSL verification (DEV ONLY)
session.verify = False
```

### Issue 2: Wrong Endpoint in Generated Code

**Problem**: Generated code points to App Service instead of APIM

**Solution**: Manually override endpoint address in code (see examples above)

### Issue 3: "404 Not Found" Response

**Causes**:
- Wrong URL path (should be `/bank`, not `/Service.svc`)
- APIM policy not deployed

**Solution**:
```bash
# Verify APIM endpoint returns WSDL
# Test in browser or: curl -i "https://apim-{uniqueId}.azure-api.net/bank?wsdl"
# Should return HTTP 200 with WSDL

# Then test with the .NET client
# Open src/SoapClient/SoapClient.sln in Visual Studio and run
```

### Issue 4: WSDL Returns Incorrect URLs

**Problem**: WSDL contains internal App Service URLs

**Solution**: APIM serves WSDL as-is. Use APIM gateway URL when creating clients, not the URLs in WSDL.

## Best Practices

### 1. Always Use APIM Gateway

✅ **Do**: Use `https://apim-{uniqueId}.azure-api.net/bank`  
❌ **Don't**: Use `https://soap-api-{uniqueId}.azurewebsites.net/Service.svc`

**Why?** APIM provides:
- Monitoring and analytics
- Policy enforcement
- Decoupling from backend

### 2. Configure Timeouts

```csharp
// .NET example
var binding = new BasicHttpBinding();
binding.SendTimeout = TimeSpan.FromSeconds(30);
binding.ReceiveTimeout = TimeSpan.FromSeconds(30);
```

### 3. Implement Retry Logic

```csharp
// .NET example with Polly
var retryPolicy = Policy
    .Handle<TimeoutException>()
    .Or<CommunicationException>()
    .Retry(3, (exception, retryCount) => 
    {
        Console.WriteLine($"Retry {retryCount} due to {exception.Message}");
    });

retryPolicy.Execute(() => 
{
    var result = client.GetBalance("12345");
});
```

### 4. Close Connections Properly

```csharp
try
{
    // Service calls
}
finally
{
    if (client.State == CommunicationState.Faulted)
        client.Abort();
    else
        client.Close();
}
```

### 5. Handle SOAP Faults

```python
from zeep.exceptions import Fault

try:
    result = service.GetBalance(accountNumber="12345")
except Fault as fault:
    print(f"SOAP Fault: {fault.message}")
    print(f"Detail: {fault.detail}")
```

## Monitoring Client Requests

### View Requests in Azure Portal

1. Navigate to APIM instance
2. Go to **Monitoring** → **Metrics**
3. Add metrics:
   - **Requests**: Total requests count
   - **Failed Requests**: Error count
   - **Successful Requests**: Success count

### Enable Application Insights

```bash
# Link APIM to Application Insights
az apim api update \
  --resource-group rg-legacy-soap-apim \
  --service-name apim-{uniqueId} \
  --api-id BankServiceWSDL \
  --set enabledLogger=true
```

View detailed traces in Application Insights.

## Next Steps

- **Understand Policies**: See [APIM Policies Explained](APIM-POLICIES.md)
- **Review Architecture**: See [Architecture](ARCHITECTURE.md) to understand the complete flow.
