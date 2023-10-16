@description('The dev center name')
param devCenterName string

@description('The project name')
param name string

@description('The environment types to create')
param environmentTypes environmentType[]

@description('The project admin to give access to the project')
param projectAdminId string = ''

@description('The members to give access to the project')
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
  members: string[]?
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
  name: '${deployment().name}-${envType.name}'
  params: {
    devCenterName: devCenterName
    projectName: project.name
    deploymentTargetId: envType.deploymentTargetId
    name: envType.name
    location: location
    tags: envType.tags == null ? {} : envType.tags
    roles: envType.roles == null ? [] : envType.roles
    members: envType.members == null ? [] : envType.members
  }
}]

var deploymentEnvironmentsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18e40d4e-8d2e-438d-97e1-9528336e149c')
var projectAdmin = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')

module memberAccess 'project-access.bicep' = [for member in members: {
  name: '${deployment().name}-member-access-${uniqueString(project.name, member)}'
  params: {
    projectName: project.name
    principalId: member
    principalRole: deploymentEnvironmentsUser
  }
}]

module projectAdminAccess 'project-access.bicep' = if (!empty(projectAdminId)) {
  name: '${deployment().name}-admin-access-${uniqueString(project.name, projectAdminId)}'
  params: {
    projectName: project.name
    principalId: projectAdminId
    principalRole: projectAdmin
  }
}
