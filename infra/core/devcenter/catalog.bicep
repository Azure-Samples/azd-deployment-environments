@description('Create a new catalog in the specified Dev Center')
param devCenterName string

@description('The name of the catalog')
param name string

@description('The URI of the GitHub repository')
param repoUri string

@description('The branch of the GitHub repository')
param branch string = 'main'

@description('The path of the GitHub repository where the catalog is located')
param path string = ''

@secure()
@description('The secret identifier of the GitHub personal access token')
param secretPatIdentifier string

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-04-01' = {
  name: name
  parent: devcenter
  properties: {
    gitHub: {
      branch: branch
      path: path
      secretIdentifier: secretPatIdentifier
      uri: repoUri
    }
  }
}
