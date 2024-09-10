### TD SYNNEX ION Billing API Inventory
$currency = 'SEK'
$fxRate = "local $currency"

### - API - Credentials
$apikey = '< API V1 KEY>'
$apisecret = '< API V1 SECRET>'
$pair = "$($apikey):$($apisecret)"

### - API - Create Auth Header
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

### - SQL - Credentials & Variables
$sqldbsrv = "< azuresqlserver.database.windows.net >"
$sqldb = "< DBNAME >"
$billingTable = '< TABLE NAME >'
$sqluser = '< SQL ACCOUNT WRITER >'
$sqlpwd = '< SQL ACCOUNT PWD >'
Import-Module SqlServer

### - DATE - Management
$CurrentDate = Get-Date
$date = Get-Date -Format yyyy-MM-dd
$datestr = $date.ToString()
$month = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Month
$year = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Year
$billingMonth = (($CurrentDate).AddMonths(-1)).ToString('MMMM')
### - VARIABLES - END

#### - SQL - Truncate Table

## Truncate table
$truncate = "TRUNCATE TABLE $billingTable"
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $truncate

### - API - ION - Get customers
$curi = 'https://ion.tdsynnex.com/api/v1/customers'
$cresponse = Invoke-RestMethod -Uri $curi -Headers $Headers #-UseBasicParsing

$Customers = $cresponse.data.customer.id 
#$Customers = '' # Enter single End Customer ID from cresponse to test

### - MICROSOFT - CSP
$resourceType = ''

foreach ($CustomerId in $Customers) {
    $uri0 = 'https://ion.tdsynnex.com/api/v1/reports/billing/azureplan'
    $uriadd = "?filter[date_range]=m-$month-$year&filter[customer_id]=$CustomerId&filter[report_currency]=$currency"
    $uri = $uri0 + $uriadd
    $responseObj = Invoke-RestMethod -Uri $uri -Headers $Headers #-ContentType  'application/json; charset=utf-8' -UseBasicParsing

    ### Level 0
    ###Definitions
    $CustomerID = $responseObj.data.entity.id
    $CustomerName = $responseObj.data.entity.company
    $ContactName = $responseObj.data.entity.name
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
                $SubscriptionLineId = ''
                $SubscriptionLineId = $line1.entity.id
                $category = ''
                $price = ''
                $cost = ''
                $usage = ''
                $mwpUsage = ''
                $cloudUsage = ''
                $cloudType = ''
                $subscriptionId = $SubscriptionLineId
                ##values from level 3
                $cloudAccountType = ''
                $category = $line3.entity.id  
                $price = $line3.data.price
                $cost = $line3.data.cost
                $Usage = $line3.data.usage
                $profit = $price - $cost

                if ($profit -le 0) {
                    $markup = 0
                    $margin = 0
                }
                else {
                    $markup = ($profit / $cost)
                    $margin = ($profit / $price)
                }

                if ($resourceType -eq $category ) {
                    $cloudType = 'Microsoft NCE'
                    $mwpUsage = [math]::Round($usage)
                    $cloudAccountType = 'NCE License'
                    $cloudUsage = 0
                }
                else {
                    $cloudType = 'Microsoft Azure'
                    $cloudUsage = [math]::Round($usage, 4)
                    $cloudAccountType = 'Azure Plan'
                    $mwpUsage = 0
                }

                if ($resourceType -match "support" ) {
                    #$subscriptionId = 'Azure Support'
                    $subscriptionId = $SubscriptionLineId
                }
                else {
                    $subscriptionId = $SubscriptionLineId
                }
                $resourceGroup = 'NA'
                ### Microsoft Namings
                write-host "************ NEW ROW ************" -foregroundColor green
                write-host "Date : $datestr"
                Write-Host "Billing Month: $billingMonth"
                write-host "Customer ID : $CustomerID"
                write-host "Customer Name : $CustomerName"
                write-host "Contact Name : $ContactName"
                Write-Host "FXRate : $fxRate"
                write-host "Cloud Type : $cloudType"
                write-host "Subscription ID : $subscriptionId"
                write-host "Cloud Account Type : $cloudAccountType"
                write-host "Resourse Group: $resourceGroup"
                write-host "ResourceType : $resourceType"
                write-host "Category : $Category"
                write-host "Azure Usage : $cloudUsage"
                write-host "MWPUsage : $mwpUsage"
                write-host "Price : $price"
                write-host "Cost : $cost"
                write-host "Profit : $profit"
                write-host "Markup : $markup"
                write-host "Margin : $margin"
                write-host "Currency : $currency"
                write-host "************ END ROW ************" -foregroundColor red
                
                $Query = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceGroup,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$subscriptionId','$cloudAccountType','$resourceGroup','$resourceType','$category','$cloudUsage','$mwpUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $Query
            }
        }
    }   
}

Write-Host "Script Done !!!"