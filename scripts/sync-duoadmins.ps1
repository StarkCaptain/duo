$apiKey = ''
$apiSecret = ''
$apiHost = 'api-454545.duosecurity.com'

#Define the name of the active directory duo role groups
$duoAdminGroups = 'APP-DUO_Administrator', 'APP-DUO_ApplicationManager', 'APP-DUO_Billing', 'APP-DUO_HelpDesk', 'APP-DUO_Readonly', 'APP-DUO_UserManager'

#Role Mapping, used to correlate ad group names to duo role name
$roles = @{Billing = 'Billing'; Administrator = 'Administrator'; HelpDesk = 'Help Desk'; UserManager = 'User Manager'; Readonly = 'Read-only';  ApplicationManager = 'Application Manager'}

#Define any users in Duo to exclude from the process
$excludedDuoUsers = 'duoadmins@yourdomain.com'

#Get a current list of administrators and assigned roles
$request = New-DuoRequest -apiHost $apiHost -apiKey $apiKey -apiSecret $apiSecret -apiEndpoint '/admin/v1/admins'
$currentDuoAdmins = Invoke-RestMethod @request

#Get a current list of users in the Active Directory Duo Groups, also map the duo role to ad group and return in the results
$currentADGroupMembers = $( $duoAdminGroups | Get-ADGroupMember -Recursive | Get-ADUser -Properties DisplayName, mail, memberOf, telephoneNumber | Where Enabled -eq True | Select DisplayName, mail, SamAccountName, telephoneNumber, @{Name="Role"; Expression = {$($_.MemberOf | Where {$_ -like '*APP-Duo*' -and $_ -notLike '*APP-Duo_Users*'}).split(',').split('_')[1]}})

#Update Role Name from AD to Duo Role Name
$currentADGroupMembers | % {$_.role = $roles.Item($_.role)}

#Get a list of users to create admin accounts for (These users exist in the AD group but not in Duo)
$usersToCreate = $currentADGroupMembers | Where Mail -NotIn $currentDuoAdmins.response.email

#Get a list of users to remove from duo as an admin (These users no longer exist in the AD Group). Exclude the duoadmin account
$usersToRemove = $currentDuoAdmins.response | Where email -NotIn $currentADGroupMembers.mail | Where email -NotLike $excludedDuoUsers

#Get a list of users whom role has changed
$usersRoleChange = @()
ForEach ($admin in $($currentDuoAdmins.response | Where email -NotLike $excludedDuoUsers)){

    $matchedAdmin = $currentADGroupMembers | Where mail -in $admin.email

    If ($matchedAdmin.Role -notlike $admin.Role){
        Write-Verbose ('Duo user object {0} {1} does not match role of AD user object {2} {3} ' -f $admin.email, $admin.Role, $matchedAdmin.mail, $matchedAdmin.Role) -Verbose
        $tempObject = @{
            admin_id = $admin.admin_id
            email = $admin.email
            role = $admin.Role
            newrole = $matchedAdmin.Role
        }
        $usersRoleChange += $tempObject
    }
}

#filter out any users that are getting removed
$usersRoleChange = $usersRoleChange | Where email -NotIn $usersToRemove.email

#Create new admin users
ForEach ($userToCreate in $usersToCreate){
    $Params = $null
  
    Write-Verbose ('Creating User: {0} with the {1} role' -f $userToCreate.mail, $userToCreate.Role) -Verbose

    If (!($userToCreate.telephoneNumber)){$userToCreate.telephoneNumber = '+1 (123) 456-7891'}

    #Create a password, this won't be used but is required for the user creation
    $pass = [System.Web.Security.Membership]::GeneratePassword(12,10)

    $Params = @{
        email = $userToCreate.mail 
        password = $pass
        name = $userToCreate.DisplayName
        phone = $userToCreate.telephoneNumber
        role = $userToCreate.role
        password_change_required = $false
    }

    $request = New-DuoRequest -apiHost $apiHost -apiKey $apiKey -apiSecret $apiSecret -apiEndpoint '/admin/v1/admins' -requestMethod POST -requestParams $Params
    Invoke-RestMethod @request
}

#Remove any users that are no longer valid
ForEach ($userToRemove in $usersToRemove){

    Write-Verbose ('Removing User: {0} with the {1} role' -f $userToRemove.email, $userToRemove.Role) -Verbose
    $request = New-DuoRequest -apiHost $apiHost -apiKey $apiKey -apiSecret $apiSecret -apiEndpoint ('/admin/v1/admins/{0}' -f $userToRemove.admin_id) -requestMethod DELETE
    Invoke-RestMethod @request
}

#Check for Role Based Assignment Changes
ForEach ($userRoleChange in $usersRoleChange){
    $Params = $null
    Write-Verbose ('Updating User: {0} from the {1} role to the {2} role' -f $userRoleChange.email, $userRoleChange.Role, $userRoleChange.newRole) -Verbose
    $Params = @{
        role = $userRoleChange.newRole
    }
    $request = New-DuoRequest -apiHost $apiHost -apiKey $apiKey -apiSecret $apiSecret -apiEndpoint ('/admin/v1/admins/{0}' -f $userRoleChange.admin_id) -requestParams $Params -requestMethod POST
    Invoke-RestMethod @request
}
