// Criação de recursos básicos no Azure
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'datavalidationstorage'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'DataValidationFactory'
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

// Adicionando um banco de dados fictício no Azure SQL Database
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: 'datavalidation-sqlserver'
  location: resourceGroup().location
  properties: {
    administratorLogin: 'adminUser'
    administratorLoginPassword: 'P@ssw0rd1234'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: 'fictitiousdb'
  parent: sqlServer
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
}
