#$Location = "uksouth"
$RGName = "RG-SPOExplorer"
#$SAName = "saspoexplorer"
$KVName = "kv-spoexplorer"
$CertCommonName = "Cert-SPOExplorer"
#$CertDownloadPath = "c:\temp\SPOExplorer.Cert.Pem"
$AppDisplayName = "App-SPExplorerFunctions"
$TenantId = az account tenant list --query "[].tenantId | [0]"

$cert = az keyvault certificate show --vault-name $KVName --name $CertCommonName
if ($null -eq $cert) {
    Write-Host -ForegroundColor Blue "Get Certificate policy"
    $certPolicy = az keyvault certificate get-default-policy | ConvertFrom-Json
    $certPolicyJson = $($certPolicy | ConvertTo-Json -Depth 100 -Compress).Replace('"', '\"')

    Write-Host -ForegroundColor Blue "Create new certificate: $($CertCommonName) with Certificate policy"
    $certificate = az keyvault certificate create --vault-name $KVName --name $CertCommonName --policy $certPolicyJson
}
else {
    Write-Warning "Certificate $($CertCommonName), already exists in keyvault"
}
#Write-Host -ForegroundColor Blue "Download certificate to $($CertDownloadPath)"
#az keyvault certificate download --vault-name $KVName --name $CertCommonName --file $CertDownloadPath



$app = az ad app list --display-name $AppDisplayName --query "[0]"
if ($null -eq $app) {
    Write-Host -ForegroundColor Blue "Create new app: $($AppDisplayName)"
    $app = az ad app create --display-name $AppDisplayName

    $ctr = 0
    do {
        $app = az ad app list --display-name $AppDisplayName
        Write-Host -ForegroundColor Blue "Waiting for the app to be provisioned."
        Start-Sleep -Seconds 2.5
        ++$ctr
    }while ($null -eq $app -or $ctr -lt 20)

    if ($null -eq $app) {
        Write-Warning "App was not created."
        return
    }
}
else {
    Write-Warning "App $($AppDisplayName) already exists"
}
$appObj = $app | ConvertFrom-Json

Write-Host -ForegroundColor Blue "Update App credentials with newly created Certificate."
az ad app credential reset --id $appObj.appId --cert $CertCommonName --append --keyvault $KVName

$IssuerUrl = "https://sts.windows.net/$($TenantId)/"
Write-Host -ForegroundColor Blue "Retrieve certificate from key vault."
$certificateObject = (az keyvault certificate show --vault-name $KVName --name $CertCommonName) | ConvertFrom-Json
Write-Host $certificateObject.x509ThumbprintHex






    