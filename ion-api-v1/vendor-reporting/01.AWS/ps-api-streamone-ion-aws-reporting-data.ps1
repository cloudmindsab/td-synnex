### TD SYNNEX ION Billing API V1 Inventory
### VARIABLES - START
# API Credentials
$apikey = '< API V1 KEY >'
$apisecret = '< API V1 SECRET >'
$pair = "$($apikey):$($apisecret)"

### SQL Credentials & Variables
$sqldbsrv = "azsqldbsrv.database.windows.net"
$sqldb = "iondb"
$billingTable = '[dbo].[Partner_ION_API_Billing_Data]'
$sqluser = 'writeuser'
$sqlpwd = 'Random-Password'
### VARIABLES - END

## DATE Management
$CurrentDate = Get-Date
$date = Get-Date -Format yyyy-MM-dd
$datestr = $date.ToString()
$month = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Month
$year = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Year
$billingMonth = (($CurrentDate).AddMonths(-1)).ToString('MMMM')

## SQL Service
# IMPORT SQL MODULES
Import-Module SqlServer
## Truncate table
$truncate = "TRUNCATE TABLE $billingTable"
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $truncate

### ION - Get customers
## Web Request Variables
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

$curi = 'https://ion.tdsynnex.com/api/v1/customers'
$cresponse = Invoke-RestMethod -Uri $curi -Headers $Headers #-UseBasicParsing

$Customers = $cresponse.data.customer.id

# AWS #
## AWS Billing API
foreach ($CustomerId in $Customers) {
    $uri1 = 'https://ion.tdsynnex.com/api/v1/reports/billing/aws'
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
                if ($CloudAccountLineType -match 'aws') {
                    $cloudType = 'AWS'
                }
                else {
                    $cloudType = 'NA'
                }
                
                $category = ''
                $price = ''
                $cost = ''
                $profit = ''
                $awsUsage = ''
                $cloudAccountId = $cloudAccountLineId
                $cloudAccountType = $cloudAccountLineType
                ##values from level 3
                $category = $line3.entity.id
                $price = $line3.data.price
                $cost = $line3.data.cost
                $awsUsage = $line3.data.usage
                $profit = $price - $cost
                
                if ($profit -le 0) {
                    $markup = 0
                    $margin = 0
                }
                else {
                    $markup = ($profit / $cost)
                    $margin = ($profit / $price)
                }
                $resourceGroup = 'NA'
                ### AWS Namings
                write-host "************ NEW ROW ************" -foregroundColor green
                write-host "Date : $datestr"
                write-host "Customer ID : $customerID"
                write-host "Customer Name : $customerName"
                write-host "Contact Name : $contactName"
                Write-Host "FXRate : $fxRate"
                write-host "Billing Month : $billingMonth"
                Write-Host "CloudType : $cloudType"
                write-host "CloudAccount ID : $cloudAccountId"
                Write-Host "CloudAccount Type : $cloudAccountType"
                write-host "Resourse Group: $resourceGroup"
                write-host "ResourceType : $resourceType"
                write-host "Category : $category"
                write-host "Usage : $awsUsage"
                write-host "Cost : $cost"
                write-host "SalesPrice : $price"
                write-host "Profit : $profit"
                write-host "Markup : $markup"
                write-host "Margin : $margin"
                write-host "Currency : $currency"
                write-host "************ END ROW ************" -foregroundColor red
                
                $awsSqlQuery = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceGroup,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$cloudAccountId','$cloudAccountType','$resourceGroup','$resourceType','$Category','$awsUsage','$MWPUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $awsSqlQuery
            }
        }
    }   
}

write-host "AWS - DATA Done Writing to table" -ForegroundColor GREEN
write-host "Script DONE - refresh report" -ForegroundColor GREEN