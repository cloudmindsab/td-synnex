#########################################################################################
#### Author: Nicklas Karlsson - NordEast Platform Manager
#### Company: TDSynnex
#### Purpose: Bulk Create CUstomers From CSV File
#### PS Version: 7.2
#### API Version: v1
#########################################################################################

$uri = 'https://ion.tdsynnex.com/api/v1'
$Key = '' ## V1 Key From ION Portal
$Secret = '' ## V1 Secret From ION Portal

## Web Request Variables
$pair = "$($Key):$($Secret)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$headers = @{
    Authorization = $basicAuthValue
}

$customers = Import-Csv -Path customers.csv -Encoding UTF8

foreach ($c in $customers) {
    $companyName = $c.OrganisationName
    $street = $c.StreetAddress 
    $suite = "" 
    $city = $c.City 
    $state = $c.State
    $zip = $c.Zipcode 
    $country = $c.Country
    $name = $c.Name
    $email = $c.Email
    $title = $c.Title
    $phone = $c.Phone
    ## Execute API Request

    $body = @{
        
        "email"          = "$email"
        "name"           = "$name"
        "title"          = "$title"
        "company"        = "$companyName"
        "phone"          = "$phone"
        "addressStreet"  = "$street"
        "addressSuite"   = "$suite"
        "addressCity"    = "$city"
        "addressState"   = "$state"
        "addressZip"     = "$zip"
        "addressCountry" = "$country"
    }

    Invoke-RestMethod "$uri/customers" -Method 'POST' -Headers $headers -Body $body
}


### GET ALL CUSTOMERS
#$Response = Invoke-RestMethod -Method GET -Uri "$uri/customers" -Headers $headers

#($Response.data.customer).Count













