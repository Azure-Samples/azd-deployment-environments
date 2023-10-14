@description('The dev center name')
param name string

@description('The name of the key vault to store secrets in')
param keyVaultName string

@description('The name of the log analytics workspace to send logs to')
param logWorkspaceName string

@description('The location to deploy the dev center to')
param location string = resourceGroup().location

@description('The configuration for the dev center')
param config devCenterConfig

@description('The tags to apply to the dev center')
param tags object = {}

param principalId string = ''

@secure()
@description('The personal access token to use to access the catalog')
param catalogToken string

type devCenterConfig = {
  projects: project[]
  catalogs: catalog[]
  environmentTypes: devCenterEnvironmentType[]
}

type project = {
  name: string
  environmentTypes: projectEnvironmentType[]
  members: string[]?
}

type catalog = {
  name: string
  repo: string
  branch: string?
  path: string?
}

type devCenterEnvironmentType = {
  name: string
  tags: object?
}

type projectEnvironmentType = {
  name: string
  deploymentTargetId: string?
  tags: object?
  roles: string[]?
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
  name: '${devcenter.name}-environment-type-${envType.name}'
  params: {
    name: envType.name
    tags: empty(envType.tags) ? {} : envType.tags
    devCenterName: devcenter.name
  }
}]

module devCenterProject 'project.bicep' = [for project in config.projects: {
  name: '${devcenter.name}-project-${project.name}'
  params: {
    name: project.name
    location: location
    tags: tags
    devCenterName: devcenter.name
    environmentTypes: project.environmentTypes
    members: [principalId]
  }
}]

module devCenterKeyVaultAccess '../security/keyvault-access.bicep' = {
  name: '${devcenter.name}-keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: devcenter.identity.principalId
  }
}

module catalogPatToken '../security/keyvault-secret.bicep' = {
  name: '${devcenter.name}-catalog-token'
  params: {
    name: '${devcenter.name}-catalog-token'
    keyVaultName: keyVaultName
    secretValue: catalogToken
  }
}

module devCenterCatalog 'catalog.bicep' = [for catalog in config.catalogs: {
  name: '${devcenter.name}-catalog-${catalog.name}'
  params: {
    devCenterName: devcenter.name
    name: catalog.name
    repoUri: catalog.repo
    branch: catalog.branch
    path: catalog.path
    secretPatIdentifier: catalogPatToken.outputs.secretUri
  }
}]

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logWorkspaceName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
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
