$AppScopes = @("Directory.Read.All", "AppRoleAssignment.ReadWrite.All", "Application.ReadWrite.All", "RoleManagement.ReadWrite.Directory")
Connect-MgGraph -Scopes $AppScopes -NoWelcome
#Get-MgContext