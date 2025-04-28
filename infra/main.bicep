@secure()
param adminPassword string
param storageAccountName string
param dataFactoryName string
param sqlServerName string
param sqlDatabaseName string
param adminLogin string
param keyVaultName string
param applicationInsightsName string = 'DataValidationMonitor'

// Tenant ID irá utilizar o tenant atual onde o deployment é feito
var tenantId = subscription().tenantId
var location = resourceGroup().location

// Criação da Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Criação de containers no Blob Storage
resource blobServiceContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${storageAccountName}/default/input'
  dependsOn: [
    storageAccount
  ]
}

resource outputContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${storageAccountName}/default/output'
  dependsOn: [
    storageAccount
  ]
}

// Criação do Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Criação do Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enabledForDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: dataFactory.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Application Insights para monitoramento
resource monitor 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Log Analytics Workspace para Application Insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${applicationInsightsName}-workspace'
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

// SQL Server com TLS habilitado
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: 'westus'  // Forçando a usar 'westus' para corresponder ao servidor existente
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: 'westus'  // Forçando a usar 'westus' para corresponder ao servidor existente
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
}

// Diagnostic Settings para SQL
resource sqlDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'SQLDiagnosticSettings'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
    ]
  }
}

// Outputs para uso em scripts ou DevOps
output storageAccountId string = storageAccount.id
output dataFactoryId string = dataFactory.id
output keyVaultId string = keyVault.id
output applicationInsightsId string = monitor.id
output sqlServerId string = sqlServer.id
