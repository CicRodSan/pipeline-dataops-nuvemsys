@secure()
param adminPassword string

param storageAccountName string
param dataFactoryName string
param sqlServerName string
param sqlDatabaseName string
param adminLogin string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceGroup().location
  properties: {}
}

resource monitor 'Microsoft.Insights/components@2020-02-02' = {
  name: 'DataValidationMonitor'
  location: resourceGroup().location
  properties: {
    Application_Type: 'web'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: 'West US'
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: 'West US'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
}
