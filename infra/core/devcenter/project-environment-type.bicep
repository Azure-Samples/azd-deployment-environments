@description('The name of the dev center project')
param projectName string

@description('The subscription id of the deployment target. If not specified, the current subscription is used')
param deploymentTargetId string = ''

@description('The name of the environment type')
param name string

@description('The location of the environment type')
param location string = resourceGroup().location

@description('The roles to assign to the environment type')
param roles string[] = []

@description('The members to give access to the project')
param members string[] = []

@description('The tags to assign to the environment type')
param tags object = {}

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

var builtInRoleMap = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var envTypeRoles = map(roles, (name) => { name: name, objectId: builtInRoleMap[toLower(name)] })

var roleMap = reduce(envTypeRoles, {}, (cur, next) => union(cur, {
      '${next.objectId}': {}
    }))

var subscriptionId = empty(deploymentTargetId) ? subscription().subscriptionId : deploymentTargetId

resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' = {
  name: name
  location: location
  tags: tags == null ? {} : tags
  parent: project
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    creatorRoleAssignment: {
      roles: roleMap
    }
    deploymentTargetId: '/subscriptions/${subscriptionId}'
    status: 'Enabled'
  }
}

var ownerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

module subscriptionAccess 'subscription-access.bicep' = {
  name: 'subscription-access-${project.name}-${environmentType.name}'
  scope: subscription(subscriptionId)
  params: {
    principalId: environmentType.identity.principalId
    roleDefinitionId: ownerRole
    principalType: 'ServicePrincipal'
  }
}

module memberAccess 'project-environment-type-access.bicep' = [for member in members: {
  name: '${project.name}-member-${member}'
  params: {
    projectName: project.name
    environmentTypeName: environmentType.name
    principalId: member
  }
}]
