# Overview
This repo contains a collection of powershell scripts for interacting with the Duo Admin API. 
All of these scripts leverage the new-duoRequest.ps1 function that crafts a proper HMAC SHA1 signed HTTP request which is required to properly 
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
