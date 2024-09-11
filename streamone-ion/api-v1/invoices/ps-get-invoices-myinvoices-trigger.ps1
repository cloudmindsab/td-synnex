# GET INVOICES GO OR NO-GO
#### Author: Nicklas Karlsson - Nordic Platform Manager

## Variables for resellers 
$key = '< API KEY >' ## RESELLER ACCOUNT API-KEY
$secret = '< API SECRET >' ## RESELLER ACCOUNT API-SECRET


## URI for BASE V1 API endpoint
$baseUrl = 'https://ion.tdsynnex.com/api/v1/'
$apiInvoices = 'invoices/myinvoices'
$uri = "$($baseUrl)$($apiInvoices)"

#### Date Configuration (-1) is for previous month
$currentDate = GET-DATE -Hour 0 -Minute 0 -Second 0
$MonthAgo = $currentDate.AddMonths(-2)
$billingStartdate = GET-DATE $MonthAgo -Day 1
$billingEndDate = GET-DATE $billingStartdate.AddMonths(1).AddSeconds(-1)
$start = $billingStartdate.ToString("yyyy-MM-dd")
$end = $billingEndDate.ToString("yyyy-MM-dd")
$month = $billingStartdate.ToString("MMMM")

### Clear Values
$response = ''
$invoices = ''
$uniqueProvider = ''

## Create authentication for Version 1 API Request
$pair = "$($Key):$($Secret)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept-Charset", "utf-8")
$headers.Add("Content-Type", "application/json")
$Headers = @{
    Authorization = $basicAuthValue
}

### Get invoices
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers #-UseBasicParsing
$invoices = $response.data.invoice | Where-Object { $_.billingStartDate -eq "$start" }

foreach ($invoice in $invoices) {
    ## Condition, IS INVOICE AVAILABLE
    $uniqueProvider = $invoice.lines.cloudProviderId | Select-Object -Unique
    foreach ($provider in $uniqueProvider) {
        if ($uniqueProvider -eq '30') {
            Write-Host "**************************************"
            Write-Host "Microsoft CSP - Invoice is available!"
            Write-Host "Invoice $($invoice.number) for month: "$($month) "-" Period $start to $end ""
            write-host "Invoice Total: $($invoice.total) $"
            write-host "FX Rates: $($invoice.currencyRates) "
            Write-Host "**************************************"
            <# Function to Get Data From Vendor Specific Report #>
        }
        elseif ($uniqueProvider -eq '1') {
            Write-Host "**************************************"
            Write-Host "AWS - Invoice is available!"
            Write-Host "Invoice $($invoice.number) for month: "$($month) "-" Period $start to $end ""
            write-host "Invoice Total: $($invoice.total) $"
            write-host "FX Rates: $($invoice.currencyRates) "
            Write-Host "**************************************"
            <# Function to Get Data From Vendor Specific Report #>
        }
        else {
            Write-Host "CloudProvider Is: UNKNOWN"
            <# Function to Get Data From Vendor Specific Report #>
        }
    }
}
