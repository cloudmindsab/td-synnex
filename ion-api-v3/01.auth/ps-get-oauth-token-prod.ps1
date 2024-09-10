### Get oAuth Token from ION Portal
$authurl = 'https://platform.url'
$refreshToken = "R#E#F#R#E#S#H#T#O#K#E#N" ### GET FIrst Refresh with TTL FROM PORTAL
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$authurl/oauth/token" -Body $refreshTokenParams

$accessToken = $tokenResponse.access_token          ### SAVE FOR OTHER REQUESTS
$tokenType = $tokenResponse.token_type              ### SAVE FOR OTHER REQUESTS
$newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST
