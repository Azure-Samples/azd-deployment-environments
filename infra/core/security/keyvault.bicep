metadata description = 'Creates an Azure Key Vault.'
param name string
param location string = resourceGroup().location
param tags object = {}

param principalId string = ''
param permissions object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: empty(permissions) ? { secrets: [ 'get', 'list' ] } : permissions
        tenantId: subscription().tenantId
      }
    ] : []
  }
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
