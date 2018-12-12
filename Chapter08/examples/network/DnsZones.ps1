[CmdletBinding()]
param (
    [string]
    $DomainName,
    [string]
    $ResourceGroupName,
    [System.Boolean]
    $Test=$false
)
function New-AzureDnsZone ($DomainName,$ResourceGroupName,$UseWhatIf) {
    if($UseWhatIf){
        New-AzureRmDnsZone -Name $DomainName -ResourceGroupName $ResourceGroupName -WhatIf -Verbose
    } else {
        New-AzureRmDnsZone -Name $DomainName -ResourceGroupName $ResourceGroupName -Verbose
    }
}

New-AzureDnsZone -DomainName $DomainName -ResourceGroupName $ResourceGroupName -UseWhatIf $Test