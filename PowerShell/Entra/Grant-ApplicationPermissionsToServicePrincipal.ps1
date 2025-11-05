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
        Info "Granting $($Perm)"
        $AppRole = $ResourceServicePrincipal.AppRoles | Where-Object { $_.Value -eq $Perm }
        if (!$AppRole) {
            Warn "$($Perm) not available for $($ResourceServicePrincipalName)"
        }
        else {
            if ($AssignedAppRoleIds -contains $AppRole.Id) {
                Warn "$($AppRole.DisplayName) is already assigned."
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