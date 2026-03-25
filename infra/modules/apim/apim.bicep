param apimServiceName string
param location string
param tags object
//param WebAppURL string
param apimSku string
param publisherEmail string
param publisherName string

resource apimService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: apimSku
    capacity: 1
  }
  tags: tags
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'None'
    publicNetworkAccess: 'Enabled'
    developerPortalStatus: 'Enabled'
  }
}

output apimPrincipalIdentityId string = apimService.identity.principalId
output resourceName string = apimService.name
output gatewayHostName string = apimService.properties.gatewayUrl
