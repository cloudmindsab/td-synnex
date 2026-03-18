#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Bulk Update Custom Fields for Customers in ION Portal From CSV File
#### PS Version: 7.2
#### API Version: v1
#########################################################################################

### Get oAuth Token from ION Portal
$baseurl = 'https://ion.tdsynnex.com'

## API FOR VERSION 1
$cFId = '#####' ## ID of the Custom Field that should be updated
$key = '#####' ## RESELLER ACCOUNT API-KEY
$secret = '#####' ## RESELLER ACCOUNT API-SECRET

$pair = "$($Key):$($Secret)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$headers = @{
    Authorization = $basicAuthValue
}
######################## CUSTOM FIELDS ########################
## Import CSV File for Subscriptions
$csvpath = "./customers.csv"  
$csvdata = Import-Csv -Path $csvpath # -Encoding utf8

## Select CSV Column names and loop through data and write to table
foreach ($csv in $csvdata) {
    $customerId = ''
    $customField = ''
    $customerId = $csv."customerId"
    $customField = $csv."customfield"
    #write-host "Customer ID: $customerId"
    #write-host "Office: $customField"

    $body = @{
        customFieldsValues = @(
            @{
                fieldId = $cFId
                value   = $customField
            }
        )
    } | ConvertTo-Json -Depth 10

    $uri = "$baseurl/api/v1/customers/$customerId" ## API URI FOR Customers Endpoint
    
    Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body -ContentType 'application/json' -ErrorAction Stop -ErrorVariable err
    
    if ($err) {
        Write-Host "Error: $($err.Exception.Message)"
    }
    else {
        Write-Host "Custom field updated successfully for customer ID: $customerId"
    }

}
