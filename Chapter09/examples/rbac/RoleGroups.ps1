<#
Bootstrap script to create example RBAC role groups
GG = global group
GC = Gamecorp
#>
#Requires -Modules AzureAD,AzureRM

$units = @("RO","MKT","CIT")
$apps = @("CSK","POR","IMS","RPT","MKT","PCR")
$types = @("Readers","Writers","Admins")
$envs = @("INT","UAT","Stage","Prod")
#Connect-AzureAD

foreach($unit in $units){
    foreach($app in $apps){
        foreach($env in $envs){
            foreach($type in $types){
                $name = [System.String]::Format("GG-GC-{0}-{1}-{2}-{3}",$unit,$app,$env,$type)
                New-AzureAdGroup -DisplayName $name -MailEnabled $false -SecurityEnabled $true -MailNickname none
            }
        }
    }
}