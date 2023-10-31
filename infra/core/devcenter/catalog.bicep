@description('Create a new catalog in the specified Dev Center')
param devCenterName string

@description('The keyvault name where the GitHub personal access token is stored')
param keyVaultName string = ''

@description('The name of the catalog')
param name string

@description('The URI of the GitHub repository')
param repoUri string

@description('The branch of the GitHub repository')
param branch string = 'main'

@description('The path of the GitHub repository where the catalog is located')
param path string = ''

@description('The secret identifier of the GitHub personal access token')
param secretIdentifier string = ''

@secure()
param patToken string = ''

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

var createSecret = !empty(patToken) && !empty(keyVaultName)
var secretIdentifierValue = !empty(secretIdentifier) ? secretIdentifier : createSecret ? catalogPatToken.outputs.secretUri : null

resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-04-01' = {
  name: name
  parent: devcenter
  properties: {
    gitHub: {
      branch: branch
      path: path
      secretIdentifier: secretIdentifierValue
      uri: repoUri
    }
  }
}

module catalogPatToken '../security/keyvault-secret.bicep' = if (createSecret) {
  name: '${deployment().name}-pat-token'
  params: {
    name: '${devcenter.name}-pat-token'
    keyVaultName: keyVaultName
    secretValue: patToken
  }
}
