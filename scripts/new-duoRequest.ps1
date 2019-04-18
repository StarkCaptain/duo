<#
  .SYNOPSIS
  Creates a properly formated http request for the DUO Admin API

  .DESCRIPTION
  This function will output a psobject that can be used with Invoke-RestMethod or Invoke-WebRequest. The function properly creates a sign
  HMAC SHA1 request for the DUO Admin API

  .PARAMATER apiHost
  Specify the api hostname for your duo admin endpoint. (api-3dsf9329.duosecurity.com)

  .PARAMATER apiEndpoint
  Specify the apiEndpoint you are using in your request. ('/admin/v1/admins'). Ensure to include the proper backslashes in the string

  .PARAMETER apiKey
  Specify the api Key, also known as the Integration key for the DUO Admin API application

  .PARAMATER apiSecret
  Specify the api secret key

  .PARAMATER requestMethod
  Specify the http request method (PUT, GET, POST, etc..) defaults to GET. This parameter is not required

  .PARAMATER requestParams
  Specify any additional parameters that need to be included in the body of the http request. Needs to formated as a hashtable @{username = 'user@test.com'; alias=user@test.com}
  (The URL-encoded list of key=value pairs, lexicographically sorted by key. If the request does not have any parameters one must still include a blank line in the string that is signed)

  .EXAMPLE
  Get All Users
  $Request = New-DuoRequest -apiHost 'api-453454fg.duosecurity.com' -apiEndpoint '/admin/v1/users' -apiKey '456fghgf23s3' -apiSecret '4354354dfg211525' 
  Invoke-RestMethod @Request 

  .EXAMPLE
  Get A user by username
  $Request = New-DuoRequest -apiHost 'api-453454fg.duosecurity.com' -apiEndpoint '/admin/v1/users' -apiKey '456fghgf23s3' -apiSecret '4354354dfg211525' -requestParams @{username = 'user@test.com'}
  Invoke-RestMethod @Request 

#>
function New-duoRequest(){
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            $apiHost,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            $apiEndpoint,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            $apiKey,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            $apiSecret,
        
        [Parameter(Mandatory=$false,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            $requestMethod = 'GET',
        
        [Parameter(Mandatory=$false,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [ValidateNotNull()]
            [System.Collections.Hashtable]$requestParams
    )

    $date = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000")

    $formattedParams = ($requestParams.Keys | Sort-Object | ForEach-Object {$_ + "=" + [uri]::EscapeDataString($requestParams.$_)}) -join "&"
    
    #DUO Params formatted and stored as bytes with StringAPIParams
    $requestToSign = (@(
        $Date.Trim(),
        $requestMethod.ToUpper().Trim(),
        $apiHost.ToLower().Trim(),
        $apiEndpoint.Trim(),
        $formattedParams
    ).trim() -join "`n").ToCharArray().ToByte([System.IFormatProvider]$UTF8)

    #Hash out some secrets 
    $hmacsha1 = [System.Security.Cryptography.HMACSHA1]::new($apiSecret.ToCharArray().ToByte([System.IFormatProvider]$UTF8))
    $hmacsha1.ComputeHash($requestToSign) | Out-Null
    $authSignature = [System.BitConverter]::ToString($hmacsha1.Hash).Replace("-", "").ToLower()

    #Create the Authorization Header
    $authHeader = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $apiKey, $authSignature)))

    #Create our Parameters for the webrequest - Easy @Splatting!
    $httpRequest = @{
        URI         = ('https://{0}{1}' -f $apiHost, $apiEndpoint)
        Headers     = @{
            "X-Duo-Date"    = $Date
            "Authorization" = "Basic: $authHeader"
        }
        Body = $requestParams
        Method      = $requestMethod
        ContentType = 'application/x-www-form-urlencoded'
    }
    
    $httpRequest
}
