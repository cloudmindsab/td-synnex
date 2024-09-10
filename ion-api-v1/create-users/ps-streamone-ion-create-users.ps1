### CREATE USERS FOR RESELLER ACCOUNT WITH CSV

<# 
** Roles **
OWNER = Account Admin
SALES = Sales
OPS = Ops
#>

## VARIABLES FOR RESELLER 
$url = 'https://platform.url'
$accountId = '#####' ## RESELLER ACCOUNT ID
$key = '######' ## RESELLER ACCOUNT API-KEY
$secret = '#####' ## RESELLER ACCOUNT API-SECRET

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

## Import CSV File for Users
# $path = 'C:\DevOps\csvusers\users.csv'  ## PATH ON PC
$path = "./csvusers/users.csv"  ## PATH ON MAC
$users = Import-Csv -Path $path

## LOOP THROUGH DATA AND CREATE USERS

foreach ($user in $users) {
    $name = $user.userName
    $email = $user.email
    $type = $user.userType
    $status = $user.userStatus
    $password = $user.password

    $body = @"
    {
    "userName": "$name",
    "email": "$email",
    "userType": "$type",
    "userStatus": "$status",
    "password": "$password"
    }
"@

    $response = Invoke-RestMethod "$url/api/v2/accounts/$accountId/users" -Method 'POST' -Headers $headers -Body $body
    $response | ConvertTo-Json
}
