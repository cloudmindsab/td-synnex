# ReInstate Microsoft AOBO for moved entitlements
## Import module
Import-Module Az
Connect-AzAccount  #Have to be a Global Admin account

## PAC ID and Subscription ID
$pacObjectId = '<PAC Object ID>'
$subId = '<SUBSCRIPTION ID>'

New-AzRoleAssignment -ObjectID $pacObjectId -RoleDefinitionName "Owner" -Scope "/subscriptions/$subId" -ObjectType "ForeignGroup"
