Param(
    [Parameter(Mandatory = $true)]$CertOfficerLogin
)
#az extension add --name application-insights
az config set extension.dynamic_install_allow_preview=true

$Location = "uksouth"
$RGName = "RG-SPOExplorer"
$SAName = "saspoexplorer"
$FAppName = "fapp-spoexplorer"
$KVName = "kv-spexplorer"
$CertCommonName = "Cert-SPOExplorer"
$CertDownloadPath = "c:\temp\SPOExplorer.Cert.Pem"
$AppDisplayName = "App-SPExplorerFunctions"
$TenantId = az account tenant list --query "[].tenantId | [0]"

$resourceGroup = $null
$resourceGroup = az group list --query "[?name=='$($RGName)'].name | [0]"

if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}

if ($null -eq $resourceGroup) {
    Write-Host "Creating resource group"
    $resourceGroup = az group create --name $RGName --location $Location --tags "spexplorer"
}
else {
    Write-Warning "$($RGName): Resource group already exists"
}


$storageAccount = az storage account list --query "[?name=='$($SAName)'].name | [0]"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}
if ($null -eq $storageAccount) {
    Write-Host "Creating storage account"
    $storageAccount = az storage account create --name $SAName --location $Location --resource-group $RGName `
        --sku "Standard_LRS" --allow-blob-public-access false --allow-shared-key-access true
}
else {
    Write-Warning "$($SAName) Storage Account already exists"
}
$StorageAcId = az storage account show --resource-group $RGName --name $SAName --query "id"

$fApp = az functionapp list --query "[?name=='$($FAppName)'].name | [0]"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}
if ($null -eq $fApp) {
    Write-Host "Creating Function App"
    az functionapp create --resource-group $RGName --name $FAppName --flexconsumption-location $Location `
        --runtime dotnet-isolated --runtime-version "8.0" --storage-account $SAName `
        --deployment-storage-auth-type SystemAssignedIdentity
}
else {
    Write-Warning "$($FAppName) Function App already exists"
}
$FunctionAppPrincipalId = az functionapp show --resource-group $RGName --name $FappName --query "identity.principalId"
#$FunctionAppPrincipalId = az ad sp list --display-name $FAppName --query "[].id | [0]"

Write-Host "Assigning Storage Ac's 'Storage Blob Data Owner' role to the function app Service Principal id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Storage Blob Data Owner" --scope $StorageAcId

$AppInsightsId = az monitor app-insights component show --resource-group $RGName --app $FAppName --query "id"
Write-Host "Assigning App Insight's 'Monitoring Metrices Publisher' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Monitoring Metrics Publisher" --scope $AppInsightsId

$keyVault = az keyvault list --query "[?name=='$($KVName)'].name | [0]"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}
if ($null -eq $keyVault) {
    Write-Host "Creating Key Vault"
    az keyvault create --resource-group $RGName --name $KVName --location $Location --sku "STANDARD"
}
else {
    Write-Warning "$($KVName) Key vault already exists"
}

$keyVaultId = az keyvault show --name $KVName --resource-group $rgName --query "id"
Write-Host "Assigning Key Vault's $($keyVaultId) 'Key Vault Certificate User' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Key Vault Certificate User" --scope $keyVaultId
Write-Host "Assigning Key Vault's $($keyVaultId) 'Key Vault Secrets User' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Key Vault Secrets User" --scope $keyVaultId
Write-Host "Assigning Key Vault's $($keyVaultId) 'Key Vault Certificates Officer' role to Current User: $($CertOfficerLogin)"
az role assignment create --assignee $CertOfficerLogin --role "Key Vault Certificates Officer" --scope $keyVaultId

Write-Host "Get Certificate policy"
$certPolicy = az keyvault certificate get-default-policy | ConvertFrom-Json
$certPolicyJson = $($certPolicy | ConvertTo-Json -Depth 100 -Compress).Replace('"', '\"')

Write-Host "Add certificate: $($CertCommonName) to json"
$certificate = az keyvault certificate create --vault-name $KVName --name $CertCommonName --policy $certPolicyJson

Write-Host "Download certificate to $($CertDownloadPath)"
az keyvault certificate download --vault-name $KVName --name $CertCommonName --file $CertDownloadPath
$certificateObject = (az keyvault certificate show --vault-name $KVName --name "Cert2") | ConvertFrom-Json

$app = az ad app list --display-name $AppDisplayName
if ($null -eq $app) {
    Write-Host "Create new app: $($AppDisplayName)"
    $app = az ad app create --display-name $AppDisplayName
}
else {
    Write-Warning "App@ $($AppDisplayName) already exists"
}
$appObj = $app | ConvertFrom-Json

Write-Host "Update App credentials with newly created Certificate."
az ad app credential reset --id $appObj.appId --cert $CertCommonName --append --keyvault $KVName

Write-Host "Upgrading Function apps auth to version 2"
az webapp auth config-version upgrade --name $FAppName --resource-group $RGName

Write-Host "Enabling authentication"
az webapp auth update --name $FappName --resource-group $rgName --enabled

Write-Host "Adding Microsoft App Authentication provider"
az webapp auth microsoft update --tenant-id $TenantId --name $FappName --resource-group $rgName `
    --client-id $appObj.appId --client-secret-certificate-thumbprint $certificateObject.x509ThumbprintHex 












    