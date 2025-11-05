    param(
        [Parameter(Mandatory = $true)]$AppId, 
        [Parameter(Mandatory = $true)]$ServicePrincipalName, 
        [Parameter(Mandatory = $true)][String[]]$Permissions
    )
    
    #e.g. -AppId <Entra App Registration Client Id> -ServicePrincipalName <Microsoft.Graph> -Permisssiosn @("Sites.ReadWrite.All")
    #Service principal associated with the Azure App
    $ClientServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($AppId)'"
    ./Grant-ApplicationPermissionsToServicePrincipal -ClientServicePrincipalId $ClientServicePrincipal.Id `
        -ResourceServicePrincipalName $ServicePrincipalName `
        -Permissions $Permissions