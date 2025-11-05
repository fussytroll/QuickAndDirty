
Param(
    [Parameter(Mandatory = $true)]$CertificateCommonName,
    [Parameter(Mandatory = $true)]$ValidForYears,
    [Parameter(Mandatory = $true)][SecureString]$CertificatePassword,
    [Parameter(Mandatory = $true)]$ExportToFolderPath
)

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
Write-Host $PFXFile
Write-Host $CERFile
Write-Host $OutFile