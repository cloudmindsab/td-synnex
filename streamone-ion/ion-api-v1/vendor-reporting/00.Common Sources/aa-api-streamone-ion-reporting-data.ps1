### TD SYNNEX Billing API Inventory
### VARIABLES - START
# API Credentials
$Key = Get-AutomationVariable -Name 'ION-API-V1-KEY'
$Secret = Get-AutomationVariable -Name 'ION-API-V1-SEC'
$pair = "$($Key):$($Secret)"

### SQL Credentials & Variables
$sqldbsrv = Get-AutomationVariable -Name 'ION-SQL-SRV-01'
$sqldb = Get-AutomationVariable -Name 'ION-SQL-DB-01'
$billingTable = Get-AutomationVariable -Name 'ION-SQL-Table-BILLING'
$sqlcred = Get-AutomationPSCredential -Name 'ION-SQL-Cred-Admin'

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
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Credential $sqlcred -OutputSqlErrors $True -Query $truncate

### ION - Get customers
## Web Request Variables
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}
$utf8 = [System.Text.Encoding]::GetEncoding(65001)
$iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
$curi = 'https://ion.tdsynnex.com/api/v1/customers'
$cresponse = Invoke-WebRequest -Uri $curi -Headers $Headers #-UseBasicParsing
$responseObj = ConvertFrom-Json $cresponse.Content
$Customers = $responseObj.data.customer.id

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
                <#
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
                #>
                
                $awsSqlQuery = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceGroup,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$cloudAccountId','$cloudAccountType','$resourceGroup','$resourceType','$Category','$awsUsage','$MWPUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Credential $sqlcred -OutputSqlErrors $True -Query $awsSqlQuery
            }
        }
    }   
}

#  MICROSOFT #
## Microsoft 365 NCE
$fxRate = '0'
$resourceType = ''
foreach ($CustomerId in $Customers) {
    $uri0 = 'https://ion.tdsynnex.com/api/v1/reports/billing/azureplan'
    $uriadd = "?filter[date_range]=m-$month-$year&filter[customer_id]=$CustomerId&filter[report_currency]=SEK"
    $uri = $uri0 + $uriadd
    $utf8 = [System.Text.Encoding]::GetEncoding(65001)
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
    $wrong_string = Invoke-WebRequest -Uri $uri -Headers $Headers -ContentType  'application/json; charset=utf-8' -UseBasicParsing
    $wrong_bytes = $utf8.GetBytes($wrong_string.Content)
    $right_bytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $wrong_bytes) #Look carefully
    $response = $utf8.GetString($right_bytes) #Look carefully
    $responseObj = ConvertFrom-Json $response
    ### Level 0
    ###Definitions
    $CustomerID = $responseObj.data.entity.id
    $CustomerName = $responseObj.data.entity.company
    $ContactName = $responseObj.data.entity.name
    $currency = 'local' #$responseObj.data.lines.entity.cost_currency[0]
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
                    $cloudType = 'Microsoft MWP'
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
                    $subscriptionId = 'Azure Support'
                }
                else {
                    $subscriptionId = $SubscriptionLineId
                }
                $resourceGroup = 'NA'
                <#
                ### Microsoft Namings
                write-host "************ NEW ROW ************" -foregroundColor green
                write-host "Date : $datestr"
                write-host "Customer ID : $CustomerID"
                write-host "Customer Name : $CustomerName"
                write-host "Contact Name : $ContactName"
                Write-Host "FXRate : $fxRate"
                write-host "Billing Month : $MonthName"
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
                #>
                
                $msSqlQuery = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceGroup,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$subscriptionId','$cloudAccountType','$resourceGroup','$resourceType','$category','$cloudUsage','$mwpUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Credential $sqlcred -OutputSqlErrors $True -Query $msSqlQuery
            }
        }
    }   
}

# GCP #
## GCP Billing API
foreach ($CustomerId in $Customers) {
    $uri1 = 'https://ion.tdsynnex.com/api/v1/reports/billing/gcp'
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
    $cloudType = 'Google - GCP'
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
            $resourceGroup = $line2.entity.id
            ### Set Level 3
            $level3 = $line2.lines
            foreach ($line3 in $level3) {
                
                $category = $line3.entity.id
                ### Set Level 4
                $level4 = $line3.lines## Clearing values

                foreach ($line4 in $level4) {

                    $resourceType = $line4.entity.id
                    $cost = $line4.data.cost
                    $price = $line4.data.price
                    $gcpUsage = $line4.data.usage
                    $profit = $price - $cost
                    if ($profit -le 0) {
                        $markup = 0
                        $margin = 0
                    }
                    else {
                        $markup = ($profit / $cost)
                        $margin = ($profit / $price)
                    }
                    <#
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
                    write-host "** GCP Resource Group: $resourceGroup" -ForegroundColor Yellow
                    write-host "** GCP ResourceType : $resourceType" -ForegroundColor Yellow
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
                    #>
                    $gcpSqlQuery = "INSERT INTO $billingTable (date,customerName,customerId,contactName,billingMonth,fxRate,cloudType,cloudAccountId,cloudAccountType,resourceGroup,resourceType,category,cloudUsage,mwpUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerName','$CustomerID','$ContactName','$billingMonth','$fxRate','$cloudType','$cloudAccountId','$cloudAccountType','$resourceGroup','$resourceType','$Category','$gcpUsage','$MWPUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                    Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Credential $sqlcred -OutputSqlErrors $True -Query $gcpSqlQuery
                }
            }
        }
    }   
}
<#
Clear-host 
write-host "GCP - DATA Done Writing to table" -ForegroundColor GREEN
Start-Sleep -S 10
write-host "Script DONE - refresh report" -ForegroundColor GREEN
#>