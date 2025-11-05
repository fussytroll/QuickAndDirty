
<#Pre-Requisites : A Valid Azure Subscription, Power Shell 7 and AZ CLI.
#this script can be done entirely in bash or by using Azure RM powershell instead of CLI. 
#Following is a quick and dirty script to provision
#Resource Group
#Storage Account
#Az Function App with App Insights
#Key Vault
#https://learn.microsoft.com/en-us/azure/azure-functions/how-to-create-function-azure-cli?tabs=windows%2Cbash%2Cazure-cli&pivots=programming-language-csharp
#>


#to revert to browser based authentication uncomment the lines below.
#https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively?view=azure-cli-latest
#$val = $(az config get core.enable_broker_on_windows)
#az config set core.enable_broker_on_windows=false
#az login

#to use app insights related commands 
az extension add --name application-insights

$region = "UK South"
$rgName = "RG-AzureUtility"
$saName = "saazureutility" #only numbers and lowercase letters allowed.
$appName = "App-AzureUtilityFunctions"
$keyVaultName = "KV-AzureUtility"

#Section: Create a resource group
$rgExists = az group exists --name $rgName
if ($rgExists -eq "true") {
    Write-Host "Resource group: $($rgName) already exists"
}
else {
    Write-Host "Creating new resource group: $($rgName)"
    az group create --name $rgName --location $region    
}

#Section: Create storage account
$saListJson = (az storage account list --query "[?name=='$($saName)']" --output json ) -Join ""
$saArr = ConvertFrom-Json $saListJson
$saExists = $saArr.Length -gt 0

if ($saExists) {
    Write-Host "Storage ac: $($saName) already exists".
}
else {
    Write-Host "Creating storage ac: $($saName)"
    az storage account create --name $saName --location $region --resource-group $rgName --sku "Standard_LRS" --allow-blob-public-access false --allow-shared-key-access true
}

#Section: Create AZ Function App
$faListJson = (az functionapp list --query "[?name=='$($appName)']" --output json ) -Join ""
$faArr = ConvertFrom-Json $faListJson
$faExists = $faArr.Length -gt 0

if ($faExists) {
    Write-Host "Function app: $($appName) already exists".
}
else {
    #az functionapp list-runtimes : list the runtimes available
    Write-Host "Creating function app: $($appName)"

    #create function app
    #this will grant Storage Blob Data Contributor role to the System Managed identity for the function app.
    az functionapp create --resource-group $rgName --name $appName --flexconsumption-location $region --runtime dotnet-isolated --runtime-version "8.0" --storage-account $saName --deployment-storage-auth-type SystemAssignedIdentity
}

#Section: Provision a keyvault
$kvListJson = (az keyvault list --query "[?name=='$($keyVaultName)']" --output json) -join ""
$kvArr = ConvertFrom-Json $kvListJson
$kvExists = $kvArr.Length -gt 0
$kvId = $null
if ($kvExists) {
    Write-Host "Keyvault : $($keyVaultName) already exists".
}
else {
    Write-Host "Creating keyvault: $($keyVaultName)"
    az keyvault create --resource-group $rgName --name $keyVaultName --location $region --sku "STANDARD"
}

#get System Managed Id assigned to Function App
Write-Host "Getting System managed identity for the Function App"
$funcAppSysMgdIdPrincipalId = az ad sp list --display-name $appname --query "[].id" --output tsv

#Section Assign permissions to Storage Account 
Write-Host "Getting resource id for the storage account"
$saResourceId = $(az storage account show --resource-group $rgName --name $saName --query 'id' -o tsv)

Write-Host "Assigning Storage Ac's 'Storage Blob Data Owner' role to the function app sys mgd id"
az role assignment create --assignee $funcAppSysMgdIdPrincipalId --role "Storage Blob Data Owner" --scope $saResourceId

#Section: Assign permissions to App Insights
Write-Host "Getting Resource Id for App Insights"
$appInsightsResourceId = $(az monitor app-insights component show --resource-group $rgName --app $appName --query "id" --output tsv)

Write-Host "Assigning App Insight's 'Monitoring Metrices Publisher' role to Function app Sys mgd Id"
az role assignment create --assignee $funcAppSysMgdIdPrincipalId --role "Monitoring Metrics Publisher" --scope $appInsightsResourceId

$kvListJson = (az keyvault list --query "[?name=='$($keyVaultName)']" --output json) -join ""
$kvArr = ConvertFrom-Json $kvListJson
$kvId = $kvArr[0].id
Write-Host "Assigning Key Vault's $($kvId) 'Key Vault Certificate User' role to Function app Sys mgd Id"
az role assignment create --assignee $funcAppSysMgdIdPrincipalId --role "Key Vault Certificate User" --scope $kvId