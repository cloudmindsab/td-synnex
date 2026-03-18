#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Bulk Create CUstomers From CSV File
#### PS Version: 7.2
#### API Version: v3
#########################################################################################
### Get oAuth Token from ION Portal
$url = 'https://ion.tdsynnex.com'
$accountId = ''  ## 
$refreshToken = '' ### GET FIrst Refresh with TTL FROM PORTAL
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$url/oauth/token" -Body $refreshTokenParams

$accessToken = $tokenResponse.access_token          ### SAVE FOR OTHER REQUESTS
$tokenType = $tokenResponse.token_type              ### SAVE FOR OTHER REQUESTS
#$newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "$tokenType $accessToken")

$customers = Import-Csv -Path customers.csv -Encoding UTF8

foreach ($c in $customers) {
    $companyName = $c.OrganisationName
    $street = $c.StreetAddress 
    #$suite = "" 
    $city = $c.City 
    $state = $c.State
    $zip = $c.Zipcode 
    $country = $c.Country
    $name = $c.Name
    $email = $c.Email 
    $title = $c.Title 
    $phone = $c.Phone 
    ## Execute API Request
    $body = @"
        {
            `"customerOrganization`": `"$companyName`",
            `"customerAddress`": {
                `"street`": `"$street`",
                `"city`": `"$city`",
                `"state`": `"$state`",
                `"zip`": `"$zip`",
                `"country`": `"$country`"
            },
            `"customerName`": `"$name`",
            `"customerEmail`": `"$email`",
            `"customerTitle`": `"$title`",
            `"customerPhone`": `"$phone`",
            `"alternateEmail`": `"`",
            `"primaryContactFirstName`": `"`",
            `"primaryContactLastName`": `"`",
            `"languageCode`": `"SE`" 
        }
"@

    Invoke-RestMethod "$url/api/v3/accounts/$accountId/customers" -Method 'POST' -Headers $headers -Body $body  
}



#$response = Invoke-RestMethod "$url/api/v3/accounts/17017/customers?pageSize=1000" -Method 'GET' -Headers $headers
#$response | ConvertTo-Json
#$response | ConvertTo-Json
