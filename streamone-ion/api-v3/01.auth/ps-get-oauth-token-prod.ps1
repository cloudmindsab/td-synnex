#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Get oAuth Token from ION Portal
#### PS Version: 7.2
#########################################################################################

$baseurl = 'https://ion.tdsynnex.com'
$refreshToken = '#####' ### GET FIrst Refresh with TTL FROM PORTAL
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$baseurl/oauth/token" -Body $refreshTokenParams

$accessToken = $tokenResponse.access_token          ### USE FOR ALL REQUESTS
$tokenType = $tokenResponse.token_type              ### USE FOR ALL REQUESTS
$newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST

$accessToken
$tokenType
$newRefreshToken