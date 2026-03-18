#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Get Customers from ION Portal
#### PS Version: 7.2
#### API Version: v3
#########################################################################################

### Get oAuth Token from ION Portal
$baseurl = 'https://ion.tdsynnex.com'
$refreshToken = "#####" ### GET First Refresh with TTL FROM PORTAL
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$baseurl/oauth/token" -Body $refreshTokenParams

$accessToken = $tokenResponse.access_token          ### USE FOR ALL REQUESTS
$tokenType = $tokenResponse.token_type              ### USE FOR ALL REQUESTS
$newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST
$newRefreshToken

## Initiate Request
$accountId = '#####'  ### ACCOUNT ID IS STATED IN ACCOUNT INFORMATION
$custimerId = '#####' ## CustomerID is stated in the ION portal

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "$tokenType $accessToken")
## {{host}}/api/v3/accounts/{{accountId}}/customers/{{customer.id}}
$response = Invoke-RestMethod "$baseurl/api/v3/accounts/$accountId/customers/$custimerId" -Method 'GET' -Headers $headers
$response | ConvertTo-Json

$response.customers        ### STEP INTO THE DATA
