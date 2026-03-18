#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Get Products List
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
$pageSize = '1000'
$bearerAuthValue = "$tokenType $accessToken"
$headers = @{
    Authorization = $bearerAuthValue
}
### Request Products
$plresponse = Invoke-RestMethod "$baseurl/api/v3/accounts/$accountId/products?pageSize=$pageSize" -Method 'GET' -Headers $headers
$plresponse | ConvertTo-Json

$products = $plresponse.products
$trimcat = "accounts/$accountId/categories/"  ### Text to trim for categories
$trimname = "accounts/$accountId/products/"  ### Text to trim for product names
foreach ($p in $products) {

    $Name = $p.name
    $pName = $Name.TrimStart("$trimname") ### Remove additional information from string
    $pType = $p.type
    $pUpdate = $p.updateTime
    $Category = $p.categories
    $pCategory = $Category.TrimStart("$trimcat") ### Remove additional information from string
    $pCreated = $p.createTime
    $pUpdate = $p.updateTime
    $pPay = $p.definition.billingMode
    $pEtag = $p.etag
    $pPub = $p.hasPublishedVersions
    $pShared = $p.isSharedProduct
    $pCaption = $p.marketing.caption
    $pDescription = $p.marketing.description
    $pDisplayName = $p.marketing.displayName
    
    <#
    Write-Host "****** START ******"
    Write-Host "Name: $pName"
    Write-Host "Type: $pType"
    Write-Host "Updated: $pUpdate"
    Write-Host "Category: $pCategory"
    Write-Host "Created: $pCreated"
    Write-Host "Billing Mode: $pPay"
    Write-Host "Etag: $pEtag"
    Write-Host "Published: $pPub"
    Write-Host "Shared: $pShared"
    Write-Host "Caption: $pCaption"
    Write-Host "Description: $pDescription"
    Write-Host "DisplayName: $pDisplayName"
    Write-Host "****** END ******"
    #>

    ### Clear Values for each procut loop
    $Name = ''
    $pName = ''
    $pType = ''
    $pUpdate = ''
    $Category = ''
    $pCategory = ''
    $pCreated = ''
    $pUpdate = ''
    $pPay = ''
    $pEtag = ''
    $pPub = ''
    $pShared = ''
    $pCaption = ''
    $pDescription = ''
    $pDisplayName = ''
}

