@description('The dev center name')
param name string

@description('The location to deploy the dev center to')
param location string = resourceGroup().location

@description('The configuration for the dev center')
param config devCenterConfig

@description('The tags to apply to the dev center')
param tags object = {}

@description('The principal id to add as a admin of the dev center')
param principalId string = ''

@description('The name of the key vault to store secrets in')
param keyVaultName string = ''

@secure()
@description('The personal access token to use to access the catalog')
param catalogToken string = ''

param catalogSecretIdentifier string = ''

@description('The name of the log analytics workspace to send logs to')
param logWorkspaceName string = ''

type devCenterConfig = {
  orgName: string
  projects: project[]
  catalogs: catalog[]
  environmentTypes: devCenterEnvironmentType[]
}

type project = {
  name: string
  environmentTypes: projectEnvironmentType[]
  members: memberRoleAssignment[]
}

type catalog = {
  name: string
  repo: string
  branch: string?
  path: string?
  secretIdentifier: string?
}

type devCenterEnvironmentType = {
  name: string
  tags: object?
}

type projectEnvironmentType = {
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

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

module devCenterEnvType 'devcenter-environment-type.bicep' = [for envType in config.environmentTypes: {
  name: '${deployment().name}-${envType.name}'
  params: {
    name: envType.name
    tags: empty(envType.tags) ? {} : envType.tags
    devCenterName: devcenter.name
  }
}]

// Default to current principal id to have Project Admin role
var defaultProjectRoleAssignments = {
  user: principalId
  role: 'DevCenter Project Admin'
}

module devCenterProject 'project.bicep' = [for project in config.projects: {
  name: '${deployment().name}-${project.name}'
  params: {
    name: project.name
    location: location
    tags: tags
    devCenterName: devcenter.name
    environmentTypes: project.environmentTypes
    members: !empty(project.members) ? project.members : [ defaultProjectRoleAssignments ]
  }
}]

module devCenterKeyVaultAccess '../security/keyvault-access.bicep' = if (!empty(keyVaultName)) {
  name: '${deployment().name}-keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: devcenter.identity.principalId
  }
}

module devCenterCatalog 'catalog.bicep' = [for catalog in config.catalogs: {
  name: '${deployment().name}-${catalog.name}'
  params: {
    devCenterName: devcenter.name
    keyVaultName: keyVaultName
    name: catalog.name
    repoUri: catalog.repo
    branch: catalog.branch
    path: catalog.path
    patToken: catalogToken
    secretIdentifier: catalog.secretIdentifier
  }
}]

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(logWorkspaceName)) {
  name: logWorkspaceName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logWorkspaceName)) {
  name: 'logs'
  scope: devcenter
  properties: {
    workspaceId: logWorkspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}
