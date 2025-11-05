param(
    [Parameter(Mandatory = $true)]$AppId, 
    [Parameter(Mandatory = $true)]$ServicePrincipalName, 
    [Parameter(Mandatory = $true)][String[]]$Permissions
)

<#
Example
Add-ApplicationPermissionsToAppServicePrincipal -AppId $AppReg.AppId -ServicePrincipalName "Microsoft Graph" -Permissions @(
    "User.Read.All",
    "MailboxSettings.Read",
    "MailboxItem.Read.All",
    "MailboxFolder.Read.All",
    "Sites.Read.All"
)
#>
function Add-ApplicationPermissions {
    param(
        [Parameter(Mandatory = $true)]$ClientServicePrincipalId, 
        [Parameter(Mandatory = $true)]$ResourceServicePrincipalName, 
        [Parameter(Mandatory = $true)][String[]]$Permissions
    )
    
    #Service for which permission is needed e.g. Microsoft.Graph
    $ResourceServicePrincipal = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceServicePrincipalName)'"

    #Get Currently assigned roles to the ClientServicePrincipal
    $CurrentRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ClientServicePrincipalId
    #Obj $CurrentRoleAssignments
    $AssignedAppRoleIds = $CurrentRoleAssignments.AppRoleId


    foreach ($Perm in $Permissions) {
        Write-Host "Granting $($Perm) for '$($ResourceServicePrincipalName)'"
        $AppRole = $ResourceServicePrincipal.AppRoles | Where-Object { $_.Value -eq $Perm }
        if (!$AppRole) {
            Write-Warning "$($Perm) not available for '$($ResourceServicePrincipalName)'"
        }
        else {
            if ($AssignedAppRoleIds -contains $AppRole.Id) {
                Write-Warning "$($AppRole.DisplayName) is already assigned."
            }
            else {
                $params = @{
                    principalId = $ClientServicePrincipalId
                    resourceId  = $ResourceServicePrincipal.Id
                    appRoleId   = $AppRole.Id
                }

                New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $ClientServicePrincipalId -BodyParameter $params
            }
        }
    }
}
    
$MgContext = Get-MgContext -ErrorAction SilentlyContinue
if($null -eq $MgContext){
    throw "Please connect using Graph PowerShell before continuing"
}

#Service principal associated with the Azure App
$ClientServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($AppId)'"
Add-ApplicationPermissions -ClientServicePrincipalId $ClientServicePrincipal.Id `
    -ResourceServicePrincipalName $ServicePrincipalName `
    -Permissions $Permissions
  

