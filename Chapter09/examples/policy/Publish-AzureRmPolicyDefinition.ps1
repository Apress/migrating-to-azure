<#
.NAME
PublishPolicy.ps1

.DESCRIPTION
This script will publish a policy to Azure based on the source file provided along with the
name of the target policy.
#>


[CmdletBinding()]
param (
    [string]
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = "The name of the policy to add or update.")]
    $PolicyName,
    [string]
    [Parameter(Position = 1, Mandatory = $true, HelpMessage = "The path to the policy source file.")]
    $PolicyPath,
    [switch]
    $Test
)
    
try {
    $policy = Get-AzureRmPolicyDefinition -Name "$($PolicyName)" -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Policy Definition '$($PolicyName)' could not be found."
}
    
    
if ($policy -eq $null) {
    $policy = New-AzureRmPolicyDefinition -Name "$($PolicyName)" -Policy "$($PolicyPath)\azurepolicy.json" `
        -Parameter "$($PolicyPath)\azurepolicy.parameters.json"
}
else {
    $policy = Set-AzureRmPolicyDefinition -Name "$($PolicyName)" -Policy "$($PolicyPath)\azurepolicy.json" `
        -Parameter "$($PolicyPath)\azurepolicy.parameters.json"
}
    
if ($Test) {
    $policy = Remove-AzureRmPolicyDefinition -Name "$($PolicyName)"
}

return $policy;
    
