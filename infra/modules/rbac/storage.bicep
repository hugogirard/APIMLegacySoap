param principalId string
param storageResourceName string

resource account 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: storageResourceName
}

@description('Built-in Role: [Storage Blob Data Owner]')
resource storage_blob_data_owner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  scope: subscription()
}

module rbac_storage_blob_data_owner 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  params: {
    principalId: principalId
    resourceId: account.id
    roleDefinitionId: storage_blob_data_owner.id
  }
}
