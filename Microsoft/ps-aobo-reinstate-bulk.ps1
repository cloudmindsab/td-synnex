# ReInstate Microsoft AOBO for moved entitlements
## Import module
Import-Module Az
Connect-AzAccount  #Have to be a Global Admin account

## Variables and Subscription Array
$pacObjectId = '<PAC Object ID>'
$subscriptions = @(

    "<subscriptionId 1>"
    "<subscriptionId 1>"
    

)

## Looping through Subscription Array
for ($i = 0; $i -lt $subscriptions.Length; $i++) {
    $subid = $subscriptions[$i]
    
    <# TESTING
    Write-Host "*****************"
    Write-Host "Pac: $pacObjectId"
    Write-Host "Sub: $subid"
    Write-Host "*****************"
    #>
    
    New-AzRoleAssignment -ObjectID $pacObjectId -RoleDefinitionName "Owner" -Scope "/subscriptions/$subId" -ObjectType "ForeignGroup"
}