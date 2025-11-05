Param(
    [Parameter(mandatory = $true)]$DisplayName
)

$MgContext = Get-MgContext -ErrorAction SilentlyContinue
if($null -eq $MgContext){
    throw "Please connect using Graph PowerShell before continuing"
}

##Check for existing app reg with the same name
$AppReg = Get-MgApplication -ErrorAction SilentlyContinue -Filter "DisplayName eq '$($DisplayName)'"

##If the app reg already exists, do nothing
if ($AppReg) {
    Write-Warning "App already exists : $($DisplayName)"
}
else {

    Write-Host "Creating App Registration"
    $AppReg = New-MgApplication -DisplayName $DisplayName `
        -Web @{ RedirectUris = $RedirectUri; } `
        #-RequiredResourceAccess $RequiredResources.RequiredResourceAccess -ErrorAction Stop

    if ($AppReg) {
        Write-Host "Waiting for app to provision..."
        Start-Sleep -Seconds 20
    }

    Write-Host "Adding a Service Principal"

    $ServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($AppReg.AppId)'"
    if ($ServicePrincipal) {
        Write-Warning "A service principal already exits for app: '$($AppReg.AppId)'"
    }
    else {
        $ServicePrincipal = New-MgServicePrincipal -AppId $AppReg.AppId
    }
}
return $AppReg