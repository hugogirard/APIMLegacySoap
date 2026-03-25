targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('The publisher email')
param publisherEmail string

@description('The publisher name')
param publisherName string

@minLength(1)
@description('Primary location for all resources')
@allowed([
  'australiaeast'
  'canadacentral'
  'centralus'
  'eastus'
  'eastus2'
  'francecentral'
  'northeurope'
  'southcentralus'
  'switzerlandnorth'
  'westeurope'
  'westus2'
  'westus3'
])
param location string

// @description('Id of the user or app to assign application roles')
// param principalId string

@description('The SKU of the APIM instance')
@allowed([
  'Basicv2'
  'Standardv2'
  'Premiumv2'
])
param apimSku string

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
  SecurityControl: 'Ignore'
}

var suffix = uniqueString(rg.id)

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// deploy the conferenceAPI app first, as it is required for the APIM deployment
// module conferenceAPI 'modules/conferenceAPI.bicep' = {
//   scope: rg
//   name: 'conferenceAPI'
//   params: {
//     location: location
//     tags: tags
//     principalId: principalId
//   }
// }

module storage 'modules/storage/storage.bicep' = {
  scope: rg
  params: {
    location: location
    tags: tags
    resourceName: 'str${suffix}'
  }
}

module apim 'modules/apim/apim.bicep' = {
  name: 'apim'
  scope: rg
  params: {
    apimServiceName: 'apim-${suffix}'
    location: location
    tags: tags
    apimSku: apimSku
    publisherEmail: publisherEmail
    publisherName: publisherName
    webAppBackendEndpoint: soapapi.outputs.soapEndpoint
  }
}

module soapapi 'modules/web/soapserver.bicep' = {
  scope: rg
  params: {
    location: location
    suffix: suffix
  }
}

module soapApiDef 'modules/apim/soap.bicep' = {
  scope: rg
  params: {
    azureApimResourceName: apim.outputs.resourceName
    storageResourceName: storage.outputs.storageResourceName
  }
}

module rbac 'modules/rbac/storage.bicep' = {
  scope: rg
  params: {
    principalId: apim.outputs.apimPrincipalIdentityId
    storageResourceName: storage.outputs.storageResourceName
  }
}

output resourceGroupName string = rg.name
output webAppName string = soapapi.outputs.webAppResourceName
output storageResourceName string = storage.outputs.storageResourceName
output containerName string = storage.outputs.containerName
output webAppHostName string = soapapi.outputs.hostName
output apimGatewayHostName string = apim.outputs.gatewayHostName
