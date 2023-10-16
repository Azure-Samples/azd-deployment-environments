@description('The name of the devcenter project')
param projectName string

@description('The principal id for the role assignment')
param principalId string

@description('The principal role for the role assignment')
param principalRole string

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(project.name, principalRole, principalId)
  scope: project
  properties: {
    principalId: principalId
    roleDefinitionId: principalRole
  }
}
