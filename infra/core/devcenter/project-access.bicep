@description('The name of the devcenter project')
param projectName string

@description('The principal id for the role assignment')
param principalId string

var deploymentEnvironmentsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18e40d4e-8d2e-438d-97e1-9528336e149c')

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deploymentEnvironmentsUser, principalId)
  scope: project
  properties: {
    principalId: principalId
    roleDefinitionId: deploymentEnvironmentsUser
  }
}
