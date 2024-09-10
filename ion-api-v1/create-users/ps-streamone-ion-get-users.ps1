### GET USERS FROM RESELLER ACCOUNT

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

### Get all Users
$uri = "$url/api/v2/accounts/$accountId/users"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers #-UseBasicParsing
$response | ConvertTo-Json
$users = $response.users

### Work With The data
$trim = "accounts/$accountId/users/"
foreach ($u in $users) {
    $name = $u.name
    $trimedName = $name.trim($trim)
    $userName = $u.userName
    $email = $u.email
    $userType = $u.userType
    $userStatus = $u.userStatus
    $createdTime = $u.createTime
    $updateTime = $u.updateTime
    
    Write-Host "********** USER START **********"
    Write-Host "Name: $trimedName"
    Write-Host "User Name: $userName"
    Write-Host "Email: $email"
    Write-Host "User Type: $userType"
    Write-Host "User Status: $userStatus"
    Write-Host "Created: $createdTime"
    Write-Host "Updated: $updateTime"
    Write-Host "********** USER END **********"
    
}
