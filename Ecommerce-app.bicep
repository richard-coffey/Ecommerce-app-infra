param location string = resourceGroup().location

//App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'ecommerce-prod-AppServicePlan'
  location: location
  sku: {
    name: 'P1V3'
    tier: 'Premium'
  }
}
//Web App
resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: 'ecommerce-prod-WebApp'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
  }
}
//Deployment Slot
resource deploymentSlot 'Microsoft.Web/sites/slots@2021-02-01' = {
  name: 'ecommerce-prod-WebApp/staging'
  location: location
  kind: 'app'
  dependsOn: [
    webApp
  ]
  properties: {
    serverFarmId: appServicePlan.id
    // Enable auto swap
    autoSwapSlotName: 'production'
  }
}
//Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'ecommerceprodcontainer'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
//Storage Queue
resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-06-01' = {
  name: '${storageAccount.name}/default/ecommercedevcontainer'
  dependsOn: [
    storageAccount
  ]
  properties: {
    queueName: 'ecommercedevcontainer'
  }
}
// CDN Profile
resource cdnProfile 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: 'ecommerce-prod-CDNProfile'
  location: location
  sku: {
    name: 'Standard_Microsoft'
  }
}
// Function App
resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: 'ecommerce-prod-FunctionApp'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: ''
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=<storage-account-name>;AccountKey=<storage-account-key>;EndpointSuffix=core.windows.net'
        }
      ]
      use32BitWorkerProcess: false
    }
  }
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
}
// Premium Plan
resource functionPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'ecommerce-prod-FunctionPlan'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
}
// Set the serverFarmId property of the Function App to the ID of the Premium Plan
resource functionAppSetPlan 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${functionApp.name}/web'
  dependsOn: [
    functionApp
  ]
  properties: {
    serverFarmId: functionPlan.id
  }
}
// Function Deployment Slots
resource deploymentFunctionSlot 'Microsoft.Web/sites/slots@2021-02-01' = {
  name: 'staging'
  parent: functionApp
  location: location
  properties: {
    serverFarmId: functionPlan.id
  }
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
}
// Configure Auto Swap
resource deploymentFunctionSlotConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${functionApp.name}/slotconf'
  properties: {
    autoSwapSlotName: 'production'
  }
}
//Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'ecommerceprodazkeyvault'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}
resource key 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: '${keyVault.name}/myKey'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
    ]
  }
}
//SQL Server
resource server 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: 'ecommerce-prod-sql'
  location: location
  properties: {
    administratorLogin: 'adminuser'
    administratorLoginPassword: 'Pass1234'
    version: '12.0'
  }
  sku: {
    name: 'Standard'
    tier: 'GeneralPurpose'
    capacity: 2
    family: 'Gen5'
  }
}
resource database 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${server.name}/ecommerce-prod-sql-db'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Standard'
    maxSizeBytes: 1073741824
  }
  dependsOn: [
    server
  ]
}
