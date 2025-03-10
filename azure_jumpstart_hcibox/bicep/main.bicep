@description('Azure service principal client id')
param spnClientId string

@description('Azure service principal client secret')
@secure()
param spnClientSecret string

@description('Azure AD tenant id for your service principal')
param spnTenantId string

@description('Azure AD object id for your Microsoft.AzureStackHCI resource provider')
param spnProviderId string

@description('Username for Windows account')
param windowsAdminUsername string

@description('Password for Windows account. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. The value must be between 12 and 123 characters long')
@minLength(12)
@maxLength(123)
@secure()
param windowsAdminPassword string

@description('Name for your log analytics workspace')
param logAnalyticsWorkspaceName string

@description('Public DNS to use for the domain')
param natDNS string = '8.8.8.8'

@description('Target GitHub account')
param githubAccount string = 'AKEMXP'

@description('Target GitHub branch')
param githubBranch string = 'main'

@description('Choice to deploy Bastion to connect to the client VM')
param deployBastion bool = false

@description('Location to deploy resources')
param location string = resourceGroup().location

@description('Override default RDP port using this parameter. Default is 3389. No changes will be made to the client VM.')
param rdpPort string = '3389'

@description('Choice to enable automatic deployment of Azure Arc enabled HCI cluster resource after the client VM deployment is complete. Default is false.')
param autoDeployClusterResource bool = false

@description('Choice to enable automatic upgrade of Azure Arc enabled HCI cluster resource after the client VM deployment is complete. Only applicable when autoDeployClusterResource is true. Default is false.')
param autoUpgradeClusterResource bool = false

@description('Enable automatic logon into HCIBox Virtual Machine')
param vmAutologon bool = true

var templateBaseUrl = 'https://raw.githubusercontent.com/${githubAccount}/azure_arc/${githubBranch}/azure_jumpstart_hcibox/'

module mgmtArtifactsAndPolicyDeployment 'mgmt/mgmtArtifacts.bicep' = {
  name: 'mgmtArtifactsAndPolicyDeployment'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
  }
}

module networkDeployment 'network/network.bicep' = {
  name: 'networkDeployment'
  params: {
    deployBastion: deployBastion
    location: location
  }
}

module storageAccountDeployment 'mgmt/storageAccount.bicep' = {
  name: 'stagingStorageAccountDeployment'
  params: {
    location: location
  }
}

module hostDeployment 'host/host.bicep' = {
  name: 'hostVmDeployment'
  params: {
    windowsAdminUsername: windowsAdminUsername
    windowsAdminPassword: windowsAdminPassword
    spnClientId: spnClientId
    spnClientSecret: spnClientSecret
    spnTenantId: spnTenantId
    spnProviderId: spnProviderId
    workspaceName: logAnalyticsWorkspaceName
    stagingStorageAccountName: storageAccountDeployment.outputs.storageAccountName
    templateBaseUrl: templateBaseUrl
    subnetId: networkDeployment.outputs.subnetId
    deployBastion: deployBastion
    natDNS: natDNS
    location: location
    rdpPort: rdpPort
    autoDeployClusterResource: autoDeployClusterResource
    autoUpgradeClusterResource: autoUpgradeClusterResource
    vmAutologon: vmAutologon
  }
}
