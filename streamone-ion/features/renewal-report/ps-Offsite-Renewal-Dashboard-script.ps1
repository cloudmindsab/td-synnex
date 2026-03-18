#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Bulk Update Custom Fields for Customers in ION Portal From CSV File
#### PS Version: 7.2
#### API Version: v1 & v3
#########################################################################################

## API FOR VERSION 1
$key = '#####' ## RESELLER ACCOUNT API-KEY
$secret = '#####' ## RESELLER ACCOUNT API-SECRET
## API FOR VERSION 3
$refreshToken = '#####'
## ACCOUNT INFO
$ionAccount = '#####' ## RESELLER ACCOUNT ID

## DATE - Variables
#$importDate = Get-Date.ToString("yyyy-MM-dd")
$importDate = Get-Date
$date = $importDate.ToString("yyyy-MM-dd")

## SQL SERVER VARIABLES
Import-Module SqlServer
$server = 'sqlservername.database.windows.net'
$db = 'database'
$user = 'db-owner account'
$pswd = 'password'
$substable = '[dbo].[TABLENAME_SUBS]'
$subsHisttable = '[dbo].[TABLENAME_SUBS_HISTORY]'
$customerstable = '[dbo].[TABLENAME_ECIT_CUSTOMERS]'

#####################################
### V3 API CALL FOR SUBSCRIPTIONS ###
#####################################

## API URI's
$v3uri = 'https://ion.tdsynnex.com/'

## API - Get oAuth RefreshToken from ION Portal
$refreshTokenParams = @{ 
    grant_type    = "refresh_token"
    redirect_url  = 'https://localhost/'
    refresh_token = $refreshToken
}

## API - Request For AccessToken
$tokenResponse = Invoke-RestMethod -Method POST -Uri "$v3uri/oauth/token" -Body $refreshTokenParams

$newAccessToken = $tokenResponse.access_token       ### USE FOR ALL REQUESTS 
$tokenType = $tokenResponse.token_type              ### USE FOR ALL REQUESTS
$newRefreshToken = $tokenResponse.refresh_token     ### SAVE FOR NEXT OATH REQUEST
Write-Output "AT : $newaccessToken"
Write-Output "TT : $tokenType"
Write-Output "RT : $newRefreshToken"

# Truncate SUBS Table
$substruncate = "TRUNCATE TABLE $substable"
Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $substruncate
#$subshisttruncate = "TRUNCATE TABLE $subsHisttable"
#Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $subshisttruncate
$customerstruncate = "TRUNCATE TABLE $customerstable"
Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $customerstruncate

## API Header
$accessToken = $newAccessToken
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "$tokenType $accessToken")

## V3 Subscription API CALL
## License Status Array
$statusArray = @(
    "Active"
    "Cancelled"
    "Complete"
    "Deleted"
    "Enabled"
    "Expired"
    "In Progress"
    "Initiated"
    "Suspended"
    "Paused"
    "Pending"
    "Working"
)

foreach ($status in $statusArray) {
    $v3apiSubsOffset = "$($v3uri)api/v3/accounts/$ionAccount/subscriptions?pagination.limit=5000&subscriptionStatus=$status"
    $subResponseOff = Invoke-RestMethod -Uri "$v3apiSubsOffset" -Method 'Get' -Headers $headers
    $subResponseOff | ConvertTo-Json

    ## LOOP THROUGH RESPONSE
    foreach ($row in $subResponseOff.items) {
        ## Clear Values
        $subscriptionId = ''
        $subscriptionName = ''
        $subscriptionProductId = ''
        $subscriptionTotalLicenses = ''
        $subscriptionBillingType = ''
        $subscriptionBillingCycle = ''
        $subscriptionBillingTerm = ''
        $subscriptionRenewStatus = ''
        $customerPO = ''
        $isTrial = ''
        $autoRenew = ''
        $customerId = ''
        $customerName = ''
        $partnerName = ''
        $lastUpdatedDate = ''
        $price = ''
        $cost = ''
        $currency = ''
        $total = ''
        $msrp = ''
        $renewalDate = ''
        $mfgPartNumber = ''

        ## Create New Values
        $subscriptionId = $row.subscriptionId.ToLower()
        $subscriptionName = $row.subscriptionName
        $subscriptionProductId = $row.subscriptionProductId
        $subscriptionTotalLicenses = $row.subscriptionTotalLicenses
        $subscriptionBillingType = $row.subscriptionBillingType
        $subscriptionBillingCycle = $row.subscriptionBillingCycle
        $subscriptionBillingTerm = $row.subscriptionBillingTerm
        $subscriptionRenewStatus = $row.subscriptionRenewStatus
        $customerPO = $row.customerPO
        $isTrial = $row.isTrial
        $autoRenew = $row.autoRenew
        $customerId = $row.customerId
        $customerName = $row.customerName
        $partnerName = $row.partnerName
        $lastUpdatedDate = $row.lastUpdatedDate
        $price = $row.price
        $cost = $row.cost
        $currency = $row.currency
        $total = $row.total
        $msrp = $row.msrp
        $renewalDate = $row.renewalDate
        $mfgPartNumber = $row.mfgPartNumber


        ### SQL Insert data to SUBS table
        $SubsQuery = "INSERT INTO $substable (importDate,subscriptionId,subscriptionName,subscriptionProductId,subscriptionTotalLicenses,subscriptionBillingType,subscriptionBillingCycle,subscriptionBillingTerm,subscriptionRenewStatus,customerPO,isTrial,autoRenew,customerId,customerName,partnerName,lastUpdatedDate,price,cost,currency,total,msrp,renewalDate,mfgPartNumber) VALUES ('$date','$subscriptionId','$subscriptionName','$subscriptionProductId','$subscriptionTotalLicenses','$subscriptionBillingType','$subscriptionBillingCycle','$subscriptionBillingTerm','$subscriptionRenewStatus','$customerPO','$isTrial','$autoRenew','$customerId','$customerName','$partnerName','$lastUpdatedDate','$price','$cost','$currency','$total','$msrp','$renewalDate','$mfgPartNumber')"
        Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $SubsQuery

        ### SQL Insert data to SUBS History table
        $SubsHistQuery = "INSERT INTO $subsHisttable (importDate,subscriptionId,subscriptionName,subscriptionProductId,subscriptionTotalLicenses,subscriptionBillingType,subscriptionBillingCycle,subscriptionBillingTerm,subscriptionRenewStatus,customerPO,isTrial,autoRenew,customerId,customerName,partnerName,lastUpdatedDate,price,cost,currency,total,msrp,renewalDate,mfgPartNumber) VALUES ('$date','$subscriptionId','$subscriptionName','$subscriptionProductId','$subscriptionTotalLicenses','$subscriptionBillingType','$subscriptionBillingCycle','$subscriptionBillingTerm','$subscriptionRenewStatus','$customerPO','$isTrial','$autoRenew','$customerId','$customerName','$partnerName','$lastUpdatedDate','$price','$cost','$currency','$total','$msrp','$renewalDate','$mfgPartNumber')"
        Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $SubsHistQuery
    }
}

######################## CUSTOM FIELDS ########################
$customersuri = 'https://ion.tdsynnex.com/api/v1/customers?limit=5000' ## API URI FOR CUstomers
$pair = "$($Key):$($Secret)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$v1Headers = @{
    Authorization = $basicAuthValue
}
$v1response = ''
$v1response = Invoke-RestMethod -Uri $customersuri -Headers $v1Headers -Method GET
$v1response | ConvertTo-Json -Depth 10
$customers = $v1response.data.customer.id

foreach ($customerId in $customers) {
    
    ## V1 API CALL FOR CUSTOMERS
    $customuri = "https://ion.tdsynnex.com/api/v1/customers/$customerId" ## API URI FOR Customers
    $customfields = Invoke-RestMethod -Uri $customuri -Headers $v1Headers -Method GET
    $customfields  | ConvertTo-Json -Depth 10
    ## Clear Values
    $customerId = ''
    $customerName = ''
    $contactName = ''
    $contactEmail = ''
    $contactPhone = ''
    $companyStreet = ''
    $companyCity = ''
    $companyState = ''
    $companyZip = ''
    $companyCountry = '' 
    $customFieldsValue = ''
    ## Populate Values
    $customerId = $customfields.data.customer.id
    $customerName = $customfields.data.customer.company
    $contactName = $customfields.data.customer.name
    $contactEmail = $customfields.data.customer.email
    $contactPhone = $customfields.data.customer.phone
    $companyStreet = $customfields.data.customer.addressStreet
    $companyCity = $customfields.data.customer.addressCity
    $companyState = $customfields.data.customer.addressState
    $companyZip = $customfields.data.customer.addressZip
    $companyCountry = $customfields.data.customer.addressCountry
    $customFieldsValue = $customfields.data.customer.customFieldsValues.value

    ## SQL QUERY TO INJECT DATA TO CUSTOMERS TABLE
    $customersQuery = "INSERT INTO $customerstable (importDate,customerId,customerName,contactName,contactEmail,contactPhone,companyStreet,companyCity,companyState,companyZip,companyCountry,customFieldsValue) VALUES ('$date','$customerId','$customerName','$contactName','$contactEmail','$contactPhone','$companyStreet','$companyCity','$companyState','$companyZip','$companyCountry','$customFieldsValue')"
    Invoke-Sqlcmd -Database $db -ServerInstance $server -Username $user -Password $pswd -OutputSqlErrors $True -Query $customersQuery
}
