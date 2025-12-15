Param(
    [Parameter(Mandatory = $true)]$CertOfficerLogin
)
#az extension add --name application-insights
az config set extension.dynamic_install_allow_preview=true

$Location = "uksouth"
$RGName = "RG-SPOExplorer"
$SAName = "saspoexplorer"
$FAppName = "fapp-spoexplorer"
$KVName = "kv-spoexplorer"
#$CertCommonName = "Cert-SPOExplorer"
#$CertDownloadPath = "c:\temp\SPOExplorer.Cert.Pem"
#$AppDisplayName = "App-SPExplorerFunctions"
#$TenantId = az account tenant list --query "[].tenantId | [0]"

$resourceGroup = $null
$resourceGroup = az group list --query "[?name=='$($RGName)'].name | [0]"

if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}

if ($null -eq $resourceGroup) {
    Write-Host -ForegroundColor Blue "Creating resource group"
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
    Write-Host -ForegroundColor Blue "Creating storage account"
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
    Write-Host -ForegroundColor Blue "Creating Function App"
    az functionapp create --resource-group $RGName --name $FAppName --flexconsumption-location $Location `
        --runtime dotnet-isolated --runtime-version "8.0" --storage-account $SAName `
        --deployment-storage-auth-type SystemAssignedIdentity
}
else {
    Write-Warning "$($FAppName) Function App already exists"
}
$FunctionAppPrincipalId = az functionapp show --resource-group $RGName --name $FappName --query "identity.principalId"
#$FunctionAppPrincipalId = az ad sp list --display-name $FAppName --query "[].id | [0]"

Write-Host -ForegroundColor Blue "Assigning Storage Ac's 'Storage Blob Data Owner' role to the function app Service Principal id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Storage Blob Data Owner" --scope $StorageAcId

$AppInsightsId = az monitor app-insights component show --resource-group $RGName --app $FAppName --query "id"
Write-Host -ForegroundColor Blue "Assigning App Insight's 'Monitoring Metrices Publisher' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Monitoring Metrics Publisher" --scope $AppInsightsId

$keyVault = az keyvault list --query "[?name=='$($KVName)'].name | [0]"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "An error occured"
    return
}
if ($null -eq $keyVault) {
    Write-Host -ForegroundColor Blue "Creating Key Vault"
    $keyVaultOutput = az keyvault create --resource-group $RGName --name $KVName --location $Location --sku "STANDARD"
    $keyVault = $keyVaultOutput | ConvertFrom-Json
    $keyVault
    $vaultUri = $keyVault.vaultUri
    Write-Host "VAULT URI"
    Write-Host $vaultUri
}
else {
    Write-Warning "$($KVName) Key vault already exists"
}

#FOLLOWING SHOULD BE RUN BY THE CERTIFICATE OFFICER.
$keyVaultId = az keyvault show --name $KVName --resource-group $rgName --query "id"
Write-Host -ForegroundColor Blue "Assigning Key Vault's $($keyVaultId) 'Key Vault Certificate User' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Key Vault Certificate User" --scope $keyVaultId
Write-Host -ForegroundColor Blue "Assigning Key Vault's $($keyVaultId) 'Key Vault Secrets User' role to Function app Service Principal Id"
az role assignment create --assignee $FunctionAppPrincipalId --role "Key Vault Secrets User" --scope $keyVaultId
Write-Host -ForegroundColor Blue "Assigning Key Vault's $($keyVaultId) 'Key Vault Certificates Officer' role to Current User: $($CertOfficerLogin)"
az role assignment create --assignee $CertOfficerLogin --role "Key Vault Certificates Officer" --scope $keyVaultId

