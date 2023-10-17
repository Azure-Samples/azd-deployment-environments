@description('The dev center name')
param devCenterName string

@description('The project name')
param name string

@description('The environment types to create')
param environmentTypes environmentType[]

@description('The members to give access to the project')
param members memberRoleAssignment[]

@description('The location of the resource')
param location string = resourceGroup().location

@description('The tags of the resource')
param tags object = {}

type environmentType = {
  name: string
  deploymentTargetId: string?
  tags: object?
  roles: string[]
  members: memberRoleAssignment[]
}

type memberRoleAssignment = {
  user: string
  role: ('Deployment Environments User' | 'DevCenter Project Admin')
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

// Default roles for environment type will be owner unless explicitly specified
var defaultEnvironmentTypeRoles = [ 'Owner' ]

module projectEnvType 'project-environment-type.bicep' = [for envType in environmentTypes: {
  name: '${deployment().name}-${envType.name}'
  params: {
    devCenterName: devCenterName
    projectName: project.name
    deploymentTargetId: envType.deploymentTargetId
    name: envType.name
    location: location
    tags: envType.tags == null ? {} : envType.tags
    roles: !empty(envType.roles) ? envType.roles : defaultEnvironmentTypeRoles
    members: !empty(envType.members) ? envType.members : []
  }
}]

module memberAccess 'project-access.bicep' = [for member in members: {
  name: '${deployment().name}-member-access-${uniqueString(project.name, member.role, member.user)}'
  params: {
    projectName: project.name
    principalId: member.user
    role: member.role
  }
}]
