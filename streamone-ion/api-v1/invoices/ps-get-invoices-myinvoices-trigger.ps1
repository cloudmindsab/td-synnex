### GET USERS FROM RESELLER ACCOUNT
$currentDate = GET-DATE -Hour 0 -Minute 0 -Second 0
$MonthAgo = $currentDate.AddMonths(-1) ## -1 FOR PREVIOUS MONTH
$billingStartdate = GET-DATE $MonthAgo -Day 1
$billingEndDate = GET-DATE $billingStartdate.AddMonths(1).AddSeconds(-1)

$start = $billingStartdate.ToString("yyyy-MM-dd")
$end = $billingEndDate.ToString("yyyy-MM-dd")

### CLear Values
$response = ''
$trigger = ''

## VARIABLES FOR RESELLER 
$url = 'https://platform.url'
$key = '<API KEY>' ## RESELLER ACCOUNT API-KEY
$secret = '<API SECRET>' ## RESELLER ACCOUNT API-SECRET

## Create authentication for API Request
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
$uri = "$url/api/v1/invoices/myinvoices"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers #-UseBasicParsing
$trigger = $response.data.invoice | Where-Object { $_.billingStartDate -eq "$start" }
if ($null -ne $trigger.number) {
    Write-host "Invoice for Period $start to $end - invoice with number $($trigger.number) is available"
}
else {
    Write-Host "Invoice for Period $start to $end not found"
}
