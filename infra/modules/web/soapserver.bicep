param suffix string
param location string

resource serverFarm 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: 'asp-${suffix}'
  location: location
  sku: {
    tier: 'PremiumV4'
    name: 'P0V4'
  }
}

resource api 'Microsoft.Web/sites@2025-03-01' = {
  name: 'soap-api-${suffix}'
  location: location
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      netFrameworkVersion: 'v4.0'
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
      alwaysOn: true
      phpVersion: 'OFF'
    }
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

output webAppResourceName string = api.name
