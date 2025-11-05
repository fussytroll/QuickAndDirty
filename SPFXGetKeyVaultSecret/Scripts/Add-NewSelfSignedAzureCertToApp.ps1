Param(
    [Parameter(Mandatory=$true)]$AppDisplayName,
    [Parameter(Mandatory=$true)]$CertificateCommonName,
    [Parameter(Mandatory=$true)]$ValidForYears,
    [Parameter(Mandatory=$true)][SecureString]$CertificatePassword,
    [Parameter(Mandatory=$true)]$ExportToFolderPath
)

$PnPContext = Get-PnPContext -ErrorAction SilentlyContinue
if($null -eq $PnPContext){
    throw "Please connect using PnP PowerShell before continuing"
}

$MgContext = Get-MgContext -ErrorAction SilentlyContinue
if($null -eq $MgContext){
    throw "Please connect using Graph PowerShell before continuing"
}

$AppReg = ./Ensure-AzureApp.ps1 -DisplayName $AppDisplayName

$ClientId = $AppReg.AppId
$ApplicationId = $AppReg.Id
Write-Host "Application registration found/created"
Write-Host "ClientId: $($ClientId)"
Write-Host "ObjectId: $($ApplicationId)"

$PFXFile = [System.IO.Path]::Combine($ExportToFolderPath, $CertificateCommonName + ".pfx")
$CERFile = [System.IO.Path]::Combine($ExportToFolderPath, $CertificateCommonName + ".cer")
$OutFile = [System.IO.Path]::Combine($ExportToFolderPath, $CertificateCommonName + ".txt")

Write-Host "Creating a new certificate"
$Response = New-PnPAzureCertificate -CommonName $CertificateCommonName `
    -ValidYears $ValidForYears `
    -OutPfx $PFXFile -OutCert $CERFile `
    -CertificatePassword $CertificatePassword

Write-Host "saving ootput"
$Response | Out-File -FilePath $OutFile

$StartDate = $Response.NotBefore.ToFileTimeUtc()
$EndDate = $Response.NotAfter.ToFileTimeUtc()
$KeyCreds = ConvertFrom-Json -InputObject $Response.KeyCredentials
$Key = [System.Text.Encoding]::ASCII.GetBytes($KeyCreds.value);

$params = @{
	keyCredentials = @(
		@{
			endDateTime = $EndDate
			startDateTime = $StartDate
			type = "AsymmetricX509Cert"
			usage = "Verify"
			key = $Key
			displayName = $Response.Subject
		}
	)
}

Update-MgApplication -ApplicationId $ApplicationId -BodyParameter $params
Write-Host "Certificate has been added to the application"
Write-Host "Remember to upload the pfx to KeyVault and"
Write-Host "Update Function App Environment Variables to include the key to the certificate. "
