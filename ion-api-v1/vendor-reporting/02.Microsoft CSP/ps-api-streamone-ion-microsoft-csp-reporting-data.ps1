### TD SYNNEX ION Microsoft CSP Billing API V1 Import to Azure SQL Database

### VARIABLES - START
# V1 API Credentials
$Key = '' ## ION API Key
$Secret = '' ## ION API Secret
$pair = "$($Key):$($Secret)"


# SQL Credentials & Variables
$sqldbsrv = "azsqldbsrv.database.windows.net"
$sqldb = "iondb"
$msCspTbl = '[dbo].[Partner_ION_MicrosoftCSP_Billing]'
$sqluser = '<writeuser>'
$sqlpwd = '<Random-passw0rd>'

# IMPORT MODULES
Import-Module SqlServer

## Truncate table
$truncate = "TRUNCATE TABLE $msCspTbl"
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $truncate

# DATES
$CurrentDate = Get-Date
$date = Get-Date -Format yyyy-MM-dd
$datestr = $date.ToString()
$month = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Month
$year = (($CurrentDate).AddMonths(-1)).ToUniversalTime().Year
$MonthName = (($CurrentDate).AddMonths(-1)).ToString('MMMM')
### VARIABLES - END

## Web Request Variables
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

### Get all customers
$utf8 = [System.Text.Encoding]::GetEncoding(65001)
$iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
$uricustomerid = 'https://ion.tdsynnex.com/api/v1/customers'
$responsecustomer = Invoke-WebRequest -Uri $uricustomerid -Headers $Headers #-UseBasicParsing
$responseObj = ConvertFrom-Json $responsecustomer.Content
$Customers = $responseObj.data.customer.id 


## Microsoft 365 NCE
foreach ($CustomerId in $Customers) {
    $uri0 = 'https://ion.tdsynnex.com/api/v1/reports/billing/azureplan' #Azureplan is Microsoft CSP in total, both consumption and licenses
    $uriadd = "?filter[date_range]=m-$month-$year&filter[customer_id]=$CustomerId&filter[report_currency]=SEK"
    $uri = $uri0 + $uriadd
    $utf8 = [System.Text.Encoding]::GetEncoding(65001)
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
    $wrong_string = Invoke-WebRequest -Uri $uri -Headers $Headers -ContentType  'application/json; charset=utf-8' -UseBasicParsing
    $wrong_bytes = $utf8.GetBytes($wrong_string.Content)
    $right_bytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $wrong_bytes) #Look carefully
    $response = $utf8.GetString($right_bytes) #Look carefully
    $responseObj = ConvertFrom-Json $response

    ###Definitions
    $CustomerID = $responseObj.data.entity.id
    $CustomerName = $responseObj.data.entity.company
    $ContactName = $responseObj.data.entity.name
    $currency = 'local'#$responseObj.data.lines.entity.cost_currency[0]
    ### Set level 1
    $level1 = $responseObj.data.lines
    foreach ($line1 in $level1) {
        #$SubscriptionLineId = ''
        #$SubscriptionLineId = $line1.entity.id
        
        ### Set level 2
        $level2 = $line1.lines
        foreach ($line2 in $level2) {
            #$SubscriptionLineId = ''
            #$SubscriptionLineId = $line1.entity.id
            $entityid = $line2.entity.id
            $SKU = ''
            ### Set Level 3
            $level3 = $line2.lines
            foreach ($line3 in $level3) {
                ## Clearing values
                $SubscriptionLineId = ''
                $SubscriptionLineId = $line1.entity.id
                
                $SKUtype = ''
                $category = ''
                $price = ''
                $cost = ''
                $usage = ''
                $MWPUsage = ''
                $AZUsage = ''
                $subscriptionId = $SubscriptionLineId
                ##values from level 3
                
                $SKUtype = $line3.entity.type
                $category = $line3.entity.id
                #$resourceT = $line3.lines      
                $price = $line3.data.price
                $cost = $line3.data.cost
                $usage = $line3.data.usage
                $profit = $price - $cost
                

                if ($profit -le 0) {
                    $markup = 0
                    $margin = 0
                }
                else {
                    $markup = ($profit / $cost)
                    $margin = ($profit / $price)
                }

                if ($entityid -eq $category ) {
                    $CSP = 'Modern Work Place'
                    $MWPUsage = [math]::Round($usage)
                }
                else {
                    $CSP = 'Azure'
                    $AZUsage = [math]::Round($usage, 4)
                }

                if ($entityid -match "support" ) {
                    $subscriptionId = 'NA'
                }
                else {
                    $subscriptionId = $SubscriptionLineId
                }
                
                write-host "************ NEW ROW ************" -foregroundColor green
                write-host "Date : $datestr"
                write-host "Customer ID : $CustomerID"
                write-host "Customer Name : $CustomerName"
                write-host "Contact Name : $ContactName"
                write-host "Billing Month : $MonthName"
                write-host "CSP : $CSP"
                write-host "Subscription ID : $subscriptionId"
                write-host "ResourceType : $entityid"
                write-host "SKU : $SKU"
                write-host "SKU TYPE : $SKUtype"
                write-host "Category : $Category"
                write-host "AZUsage : $AZUsage"
                write-host "MWPUsage : $MWPUsage"
                write-host "Price : $price"
                write-host "Cost : $cost"
                write-host "Profit : $profit"
                write-host "Markup : $markup"
                write-host "Margin : $margin"
                write-host "Currency : $currency"
                write-host "************ END ROW ************" -foregroundColor red
                
                $import = "INSERT INTO $msCspTbl (date,customerID,customerName,contactName,billingMonth,CSP,subscriptionID,resourceType,SKU,SKUType,category,AZUsage,MWPUsage,cost,price,profit,markup,margin,currency) VALUES ('$datestr','$CustomerID','$CustomerName','$ContactName','$MonthName','$CSP','$subscriptionid','$entityid','$SKU','$SKUType','$Category','$AZUsage','$MWPUsage','$cost','$price','$profit','$markup','$margin','$currency')"
                Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $import
            }
        }
    }   
}

write-host "Script DONE" -ForegroundColor GREEN