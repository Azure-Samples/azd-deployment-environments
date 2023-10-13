@description('Creates a new environment type in the specified Dev Center.')
param devCenterName string

@description('The name of the environment type to create.')
param name string

@description('The tags to associate with the environment type.')
param tags object = {}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

resource environmentType 'Microsoft.DevCenter/devcenters/environmentTypes@2023-04-01' = {
  name: name
  tags: tags == null ? {} : tags
  parent: devcenter
}
