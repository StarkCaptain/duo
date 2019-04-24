# Overview
This repo contains a collection of powershell scripts for interacting with the Duo Admin API. 
All of these scripts leverage the new-duoRequest function that crafts a proper HMAC SHA1 signed HTTP request which is required to properly 
authenticated to the Duo Admin API

# new-duoRequest.ps1
```powershell
  .EXAMPLE
  Get All Users
  $Request = New-DuoRequest -apiHost 'api-453454fg.duosecurity.com' -apiEndpoint '/admin/v1/users' -apiKey '456fghgf23s3' -apiSecret '4354354dfg211525' 
  Invoke-RestMethod @Request
  
  .EXAMPLE
  Get A user by username
  $Request = New-DuoRequest -apiHost 'api-453454fg.duosecurity.com' -apiEndpoint '/admin/v1/users' -apiKey '456fghgf23s3' -apiSecret '4354354dfg211525' -requestParams @{username = 'user@test.com'}
  Invoke-RestMethod @Request 
 ```
 
 # sync-duoAdmins.ps1

This script will sync active directory groups to Duo for admin access. There are few assumptions I take in the script that you will probably need to take into account and modify the script further to fit your needs. 

1. The script references active directory group names saved to the variable $duoAdminGroups. Each group name ends with the corresponding role that exists in Duo.
```
APP-DUO_Administrator maps to the Duo Administrator Role
APP-DUO_HelpDesk maps to the Duo Help Desk Role

$duoAdminGroups = 'APP-DUO_Administrator', 'APP-DUO_ApplicationManager', 'APP-DUO_Billing', 'APP-DUO_HelpDesk', 'APP-DUO_Readonly', 'APP-DUO_UserManager'
```
2. Based on the above group names I created a $roles variable to map the AD group name to the applicable Duo Role. You can easily modify this based on your needs. So for example the group ending withe HelpDesk maps to the actual role name 'Help Desk' in Duo, which will be required when making the API call
```
$roles = @{Billing = 'Billing'; Administrator = 'Administrator'; HelpDesk = 'Help Desk'; UserManager = 'User Manager'; Readonly = 'Read-only';  ApplicationManager = 'Application Manager'}
```
3. The $currentADGroupMembers variable gets the group membership of all the groups defined in the $duoAdminGroups variable. This function does a split operation based on the group naming convention I used for the $duoAdminGroups. The intent is get the Role name from the group name. You may need to update this if you use a different group naming convention. 
```
@{Name="Role"; Expression = {$($group.Name.split(',').split('_')[1])}
```
