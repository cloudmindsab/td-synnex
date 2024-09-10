### Get oAuth Token from ION Portal
$url = 'https://api-platform.url'
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


## Initiate Request
$accountId = 'XXXXXXXX'  ### ACCOUNT ID IS STATED IN ACCOUNT INFORMATION
$pageSize = 1000

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $accessToken")

$response = Invoke-RestMethod "$url/api/v3/accounts/$accountId/customers?pageSize=$pageSize" -Method 'GET' -Headers $headers
$response | ConvertTo-Json

$customers = $response.customers       ### STEP INTO THE DATA

$trim = "accounts/$accountId/customers/"  ### Text to trim to collect customer ID's
$customerIds = @()  ### Create array to store customer ID's 
foreach ($customer in $customers) {
    $cName = $customer.name
    $newCname = $cName.TrimStart("$trim") ### Remove additional information from string
    # Write-Host "$newCname"  ## Debug to show customer ID
    $customerIds += $newCname ### Add customer ID to array
}

$customerIds ## Array of customer ID's

## Interact with the data
foreach ($cid in $customerIds) {
    $ciresponse = Invoke-RestMethod "$url/api/v3/accounts/$accountId/customers/$cid" -Method 'GET' -Headers $headers
    $ciresponse | ConvertTo-Json

    $created = $ciresponse.createTime
    $organization = $ciresponse.customerOrganization
    $customerName = $ciresponse.customerName
    $customerEmail = $ciresponse.customerEmail
    $addressCity = $ciresponse.customerAddress.city
    $addressCountry = $ciresponse.customerAddress.country
    $addressState = $ciresponse.customerAddress.state
    $addressStreet = $ciresponse.customerAddress.street
    $addressZip = $ciresponse.customerAddress.zip
    $status = $ciresponse.customerStatus
    $uid = $ciresponse.uid
    $updated = $ciresponse.updateTime
    
    Write-Host "****** START ******"
    Write-Host "Status: $status"
    Write-Host "Created: $created"
    Write-Host "Updated: $updated"
    Write-Host "Org: $organization"
    Write-Host "Customer Name: $customerName"
    Write-Host "Customer Email: $customerEmail"
    Write-Host "Country: $addressCountry"
    Write-Host "City: $addressCity"
    Write-Host "State: $addressState"
    Write-Host "Street: $addressStreet"
    Write-Host "Zip: $addressZip"
    Write-Host "Uid: $uid"
    Write-Host "****** END ******"

    ## Write data to database table for useful data storage or push to other platforms
    
}
