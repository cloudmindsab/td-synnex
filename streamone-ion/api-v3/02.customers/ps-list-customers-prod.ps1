#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: List Customers from ION Portal
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
$pageSize = 1000

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "$tokenType $accessToken")

$response = Invoke-RestMethod "$baseurl/api/v3/accounts/$accountId/customers?pageSize=$pageSize" -Method 'GET' -Headers $headers
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
    $ciresponse = Invoke-RestMethod "$baseurl/api/v3/accounts/$accountId/customers/$cid" -Method 'GET' -Headers $headers
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
