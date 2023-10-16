targetScope = 'subscription'

@description('The role assignment name')
param name string

@description('The principal id for the role assignment')
param principalId string

@description('The principal type for the role assignment')
param principalType ('User' | 'Group' | 'ServicePrincipal')

@description('The role definition id for the role assignment')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: name
  properties: {
    principalType: principalType
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
