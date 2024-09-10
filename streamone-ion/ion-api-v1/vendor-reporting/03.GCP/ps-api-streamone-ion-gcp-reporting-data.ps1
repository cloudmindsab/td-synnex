### TD SYNNEX ION GOOGLE GCP Billing API Import to Azure SQL Database

### VARIABLES - START
# API Credentials
$Key = '' ## ION API Key
$Secret = '' ## ION API Secret
$pair = "$($Key):$($Secret)"

### SQL Credentials & Variables
$sqldbsrv = "partnerdb.database.windows.net" # Partner unique
$sqldb = "iondb" # Partner unique
$billingTable = '[dbo].[Partner_ION_GCP_Billing_Data]'
$sqluser = '<writeuser>'
$sqlpwd = '<Random-passw0rd>'

# IMPORT SQL MODULES
Import-Module SqlServer

## Truncate table
$truncate = "TRUNCATE TABLE $billingTable"
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $truncate

# DATE Management
$CurrentDate = Get-Date
$date = Get-Date -Format yyyy-MM-dd
$datestr = $date.ToString()
$month = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Month
$year = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Year
$billingMonth = (($CurrentDate).AddMonths(-1)).ToString('MMMM')
### VARIABLES - END

## Web Request Variables
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

### ION customers

$utf8 = [System.Text.Encoding]::GetEncoding(65001)
$iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
$curi = 'https://ses.techdata.com/api/v1/customers'
$cresponse = Invoke-WebRequest -Uri $curi -Headers $Headers #-UseBasicParsing
$responseObj = ConvertFrom-Json $cresponse.Content
$Customers = $responseObj.data.customer.id 

# GCP #
## GCP Billing API
foreach ($CustomerId in $Customers) {
    $uri1 = 'https://ses.techdata.com/api/v1/reports/billing/gcp'
    $params = "?filter[date_range]=m-$month-$year&filter[customer_id]=$CustomerId&filter[report_currency]=SEK"
    $uri = $uri1 + $params
    $utf8 = [System.Text.Encoding]::GetEncoding(65001)
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
    $wrong_string = Invoke-WebRequest -Uri $uri -Headers $Headers -ContentType  'application/json; charset=utf-8' -UseBasicParsing
    $wrong_bytes = $utf8.GetBytes($wrong_string.Content)
    $right_bytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $wrong_bytes) #Look carefully
    $response = $utf8.GetString($right_bytes) #Look carefully
    $responseObj = ConvertFrom-Json $response
    ### Level 0
    ## Definitions
    $customerID = $responseObj.data.entity.id
    $customerName = $responseObj.data.entity.company
    $contactName = $responseObj.data.entity.name
    $currency = 'local'
    $mwpUsage = '0'
    $fxRates = $responseObj.data.entity.conversion_rates
    foreach ($rate in $fxRates) {
        $fx = $rate.Split('SEK ')[1]
        $fxrate = ($fx).Split(' ')[0]
    }
    
    ### Set level 1
    $level1 = $responseObj.data.lines
    foreach ($line1 in $level1) {
        ### Set level 2
        $level2 = $line1.lines
        foreach ($line2 in $level2) {
            $resourceType = $line2.entity.id
            ### Set Level 3
            $level3 = $line2.lines
            foreach ($line3 in $level3) {
                ## Clearing values
                $cloudAccountLineId = ''
                $cloudAccountLineId = $line1.entity.id
                $cloudAccountLineType = $line1.entity.type
                if ($CloudAccountLineType -match 'gcp') {
                    $cloudType = 'GCP'
                }
                else {
                    $cloudType = 'GCP'
                }
                
                $category = ''
                $price = ''
                $cost = ''
                $profit = ''
                $gcpUsage = ''
                $cloudAccountId = $cloudAccountLineId
                $cloudAccountType = $cloudAccountLineType
                ##values from level 3
                $category = $line3.entity.id
                $price = $line3.data.price
                $cost = $line3.data.cost
                $gcpUsage = $line3.data.usage
                $profit = $price - $cost
                
                if ($profit -le 0) {
                    $markup = 0
                    $margin = 0
                }
                else {
                    $markup = ($profit / $cost)
                    $margin = ($profit / $price)
                }
                
                ### GCP Namings
                write-host "************ NEW ROW ************" -foregroundColor green
                write-host "Date : $datestr"
                write-host "Customer Name : $customerName"
                write-host "Customer ID : $customerID"
                write-host "Contact Name : $contactName"
                write-host "Billing Month : $billingMonth"
                Write-Host "FXRate : $fxRate"
                Write-Host "CloudType : $cloudType"
                write-host "CloudAccount ID : $cloudAccountId"
                Write-Host "CloudAccount Type : $cloudAccountType"
                write-host "ResourceType : $resourceType"
                write-host "Category : $category"
                write-host "Cloud Usage : $gcpUsage"
                write-host "MWP Usage : $mwpUsage"
                write-host "Cost : $cost"
                write-host "Price : $price"
                write-host "Profit : $profit"
                write-host "Markup : $markup"
                write-host "Margin : $margin"
                write-host "Currency : $currency"
                write-host "************ END ROW ************" -foregroundColor red
                
                $gcpSqlQuery = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$cloudAccountId','$cloudAccountType','$resourceType','$Category','$gcpUsage','$MWPUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $gcpSqlQuery
            }
        }
    }   
}

write-host "GCP - DATA Done Writing to table" -ForegroundColor GREEN