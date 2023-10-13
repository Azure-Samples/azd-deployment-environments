targetScope = 'subscription'

@description('The principal id for the role assignment')
param principalId string

@description('The role definition id for the role assignment')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, roleDefinitionId, principalId)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
