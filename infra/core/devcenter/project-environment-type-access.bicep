@description('The name of the devcenter project')
param projectName string

@description('The name of the environment type')
param environmentTypeName string

@description('The principal id for the role assignment')
param principalId string

@description('The principal role for the role assignment')
param role string

var roleMap = {
  'deployment environments user': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18e40d4e-8d2e-438d-97e1-9528336e149c')
  'devCenter project admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' existing = {
  name: environmentTypeName
  parent: project
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(environmentType.id, roleMap[toLower(role)], principalId)
  scope: environmentType
  properties: {
    principalId: principalId
    roleDefinitionId: roleMap[toLower(role)]
  }
}
