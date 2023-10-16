@description('The name of the dev center project')
param devCenterName string

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

resource devCenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

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

// The devcenter principal requires owner access on the target subscription
module devCenterSubscriptionAccess 'subscription-access.bicep' = {
  name: '${deployment().name}-devcenter-subscription-access'
  scope: subscription(subscriptionId)
  params: {
    name: guid(devCenter.id, ownerRole, devCenter.identity.principalId)
    principalId: devCenter.identity.principalId
    roleDefinitionId: ownerRole
    principalType: 'ServicePrincipal'
  }
}

// The environment type principal requires owner access on the target subscription
module environmentTypeSubscriptionAccess 'subscription-access.bicep' = {
  name: '${deployment().name}-subscription-access'
  scope: subscription(subscriptionId)
  params: {
    name: guid(environmentType.id, ownerRole, environmentType.identity.principalId)
    principalId: environmentType.identity.principalId
    roleDefinitionId: ownerRole
    principalType: 'ServicePrincipal'
  }
}

module memberAccess 'project-environment-type-access.bicep' = [for member in members: {
  name: '${deployment().name}-member-access-${uniqueString(project.name, environmentType.name, member)}'
  params: {
    projectName: project.name
    environmentTypeName: environmentType.name
    principalId: member
  }
}]
