<#
Bootstrap script to create example RBAC resource groups
GC = Gamecorp

Convention is:
R-GC-{LOB}-{app}-{object}-{environment}-{type}
#>
#Requires -Modules AzureAD,AzureRM

$lobs = @("RO")
$apps = @("CSK","POR","IMS","RPT")
$envs = @("INT","UAT","Stage","Prod")
$types = @("Read","Write","Admin")
$objects = @("Server","File","Database")
# Connect to the tenant
Connect-AzureAD
# I am the literal worst for this level of foreach nesting
foreach($lob in $lobs){
    foreach($app in $apps){
        foreach($obj in $objects){
            foreach($env in $envs){
                foreach($type in $types){
                    $groupName = [System.String]::Format( "R-GC-{0}-{1}-{2}-{3}-{4}",$lob,$app,$obj,$env,$type)
                    New-AzureADGroup -DisplayName $groupName -MailEnabled $false -SecurityEnabled $true -MailNickname none
                }
            }
        }

    }
}