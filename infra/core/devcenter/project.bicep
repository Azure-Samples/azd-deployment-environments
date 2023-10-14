@description('The dev center name')
param devCenterName string

@description('The project name')
param name string

@description('The environment types to create')
param environmentTypes environmentType[]

param members string[]

@description('The location of the resource')
param location string = resourceGroup().location

@description('The tags of the resource')
param tags object = {}

type environmentType = {
  name: string
  deploymentTargetId: string?
  tags: object?
  roles: string[]?
}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    devCenterId: devcenter.id
  }
}

module projectEnvType 'project-environment-type.bicep' = [for envType in environmentTypes: {
  name: '${project.name}-environment-type-${envType.name}'
  params: {
    projectName: project.name
    deploymentTargetId: envType.deploymentTargetId
    name: envType.name
    location: location
    tags: envType.tags == null ? {} : envType.tags
    roles: envType.roles == null ? [] : envType.roles
  }
}]

module memberAccess 'project-access.bicep' = [for member in members: {
  name: '${project.name}-member-${member}'
  params: {
    projectName: project.name
    principalId: member
  }
}]
