targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Name of the devcenter')
param devCenterName string = ''

@description('Name of the key vault')
param keyVaultName string = ''

@description('Name of the log analytics workspace')
param logWorkspaceName string = ''

@secure()
@description('Token used to access the catalog')
param catalogToken string = ''

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Id of the user or app to assign application roles')
param principalId string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

var devCenterConfig = loadYamlContent('./devcenter.yaml')
module devcenter 'core/devcenter/devcenter.bicep' = {
  name: 'devcenter'
  scope: rg
  params: {
    name: !empty(devCenterName) ? devCenterName : 'dc-${devCenterConfig.orgName}-${resourceToken}'
    location: location
    tags: tags
    config: devCenterConfig
    catalogToken: catalogToken
    keyVaultName: !empty(catalogToken) ? keyVault.outputs.name : ''
    logWorkspaceName: logging.outputs.name
    principalId: principalId
  }
}

module keyVault './core/security/keyvault.bicep' = if (!empty(catalogToken)) {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
    permissions: {
      secrets: [
        'get'
        'list'
        'set'
        'delete'
      ]
    }
  }
}

module logging './core/monitor/loganalytics.bicep' = {
  name: 'logging'
  scope: rg
  params: {
    name: !empty(logWorkspaceName) ? logWorkspaceName : 'law-${resourceToken}'
    location: location
    tags: tags
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
