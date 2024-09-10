### Get oAuth Token from ION Portal
$url = 'https://platform.url'
$refreshToken = "R#E#F#R#E#S#H#T#O#K#E#N" ### GET FIrst Refresh with TTL FROM PORTAL
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$url/oauth/token" -Body $refreshTokenParams

$accessToken = $tokenResponse.access_token          ### SAVE FOR OTHER REQUESTS
# $tokenType = $tokenResponse.token_type              ### SAVE FOR OTHER REQUESTS
# $newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST


## Get Subscriptions
$accountId = '17017'

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $accessToken")

$response = Invoke-RestMethod "$url/api/v3/accounts/$accountId/subscriptions" -Method 'GET' -Headers $headers
$response | ConvertTo-Json

#$subscriptions = $response.items

