param azureApimResourceName string
param storageResourceName string

resource apim 'Microsoft.ApiManagement/service@2025-03-01-preview' existing = {
  name: azureApimResourceName
}

resource wsdl 'Microsoft.ApiManagement/service/apis@2025-03-01-preview' = {
  parent: apim
  name: 'BankServiceWSDL'
  properties: {
    path: 'bank'
    apiRevision: '1'
    isCurrent: true
    subscriptionRequired: false
    displayName: 'BankService WSDL definition'
    serviceUrl: 'https://contoso.com' // This doesn't matter since the policy manage everything
    format: 'openapi'
    value: loadTextContent('./wcf.yaml')
    protocols: [
      'https'
    ]
  }
}

resource wsdlPolicy 'Microsoft.ApiManagement/service/apis/policies@2025-03-01-preview' = {
  parent: wsdl
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: replace(loadTextContent('./def_policy.xml'), '{{storage_name}}', storageResourceName)
  }
}
