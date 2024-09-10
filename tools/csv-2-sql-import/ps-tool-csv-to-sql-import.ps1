### - SQL - Credentials & Variables
$sqldbsrv = "servername.database.windows.net"
$sqldb = "db_name"
$csvtable = 'table_name'
$sqluser = 'write_user'
$sqlpwd = 'random-password'

Import-Module SqlServer

### - DATE - Management
$date = Get-Date -Format yyyy-MM-dd
$datestr = $date.ToString()

## Import CSV File for Subscriptions
# $path = 'C:\scripts\csvs\subsd.csv'  ## PATH ON PC
$csvpath = "./subs/csvfile-s.csv"  ## PATH ON MAC
$csvdata = Import-Csv -Path $csvpath -Encoding utf8

# Truncate table
$truncate = "TRUNCATE TABLE $csvtable"
Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $truncate

## Select CSV Column names and loop through data and write to table
foreach ($csv in $csvdata) {
    $productName = $csv."PRODUCT NAME"
    $mfpn = $csv."MFG PART NUMBER"
    $subId = $csv."SUBSCRIPTION ID"
    $customerName = $csv."CUSTOMER NAME"
    $partnerName = $csv."PARTNER NAME"
    $cloudProviders = $csv."CLOUD PROVIDERS"
    $status = $csv."STATUS"
    $licenses = $csv."LICENCES"
    $autoRenew = $csv."AUTO RENEW"
    $purchasedOn = $csv."PURCHASED ON"
    $endDate = $csv."END DATE"

    $import = "INSERT INTO $csvtable (
        date,
        productName,
        mfgPartNumber,
        subscriptionId,
        customerName,
        partnerName,
        cloudProviders,
        status,
        licenses,
        autoRenew,
        purchasedOn,
        endDate
        ) 
            VALUES (
        '$datestr',
        '$productName',
        '$mfpn',
        '$subId',
        '$customerName',
        '$partnerName',
        '$cloudProviders',
        '$status',
        '$licenses',
        '$autorenew',
        '$purchasedOn',
        '$endDate'
        )"

    Invoke-Sqlcmd -Database $sqldb -ServerInstance $sqldbsrv -Username $sqluser -Password $sqlpwd -OutputSqlErrors $True -Query $import
    
}
write-host "csv imported to SQL Table !!!"