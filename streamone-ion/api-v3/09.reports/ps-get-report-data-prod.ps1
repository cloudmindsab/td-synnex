#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Get Report Data
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
$accountId = 'XXXXXX'    ### ACCOUNT ID IS STATED IN ACCOUNT INFORMATION
$reportId = 'XXXXXX'     ### REPORT ID IS STATED IN ION PORTAL
$method = 'POST'

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "$tokenType $accessToken")

$response = Invoke-RestMethod "$baseurl/api/v3/accounts/$accountId/reports/$reportId/data" -Method $method -Headers $headers
$response | ConvertTo-Json

$response.reports