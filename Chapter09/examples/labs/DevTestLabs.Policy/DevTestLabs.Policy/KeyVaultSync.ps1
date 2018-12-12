<#
.DESCRIPTION
This function will synchronize key vault secrets with a source key vault.

.EXAMPLE
Sync-AzureKeyVaultSecrets "GC-RO-DTL-ENGINEERING-SHARED" "NA-RO-VAULT-01" "GC-RO-AZ-Team1"
#>
function Sync-AzureKeyVaultSecrets {
[CmdletBinding()]
param (
    [Parameter(position=0,Mandatory=$true)]
    [string]
    $KeyVaultResourceGroup,
    [Parameter(position=1,Mandatory=$true)]
    [string]
    $SourceKeyVaultName,
    [Parameter(position=2,Mandatory=$true)]
    [string]
    $AdminADGroup,
    [switch]
    [Parameter(HelpMessage="Use this flag only if you need to refresh all vaults.")]
    $Force
)

    $labVaults = Get-AzureRmKeyVault -ResourceGroupName "$($KeyVaultResourceGroup)"
    $secretsVault = Get-AzureRmKeyVault -VaultName "$($SourceKeyVaultName)"

    $secrets = Get-AzureKeyVaultSecret -VaultName $secretsVault.VaultName | where { $_.Name -like "*Password" }

    foreach($labVault in $labVaults) {
        $group = Get-AzureRmADGroup -SearchString "$($AdminADGroup)"
        $policy = $labVault.AccessPolicies.Where({ $_.ObjectId -eq $group.Id.Guid })
        # Check to see if the policy object exists already or that the policy count is only 1 (default of Dev Test Labs)
        if($policy -eq $null -or $labVault.AccessPolicies.Count -eq 1) {
            Write-Warning "Could not find access policy for $($group.DisplayName) in key vault $($labVault.VaultName).  Adding..."
            Set-AzureRmKeyVaultAccessPolicy -VaultName $labVault.VaultName -PermissionsToSecrets all -ObjectId $group.Id
        } else {
            Write-Output "Found access policy for $($group.DisplayName) in key vault $($labVault.VaultName)."
        }

        try {
        $testValue = Get-AzureKeyVaultSecret -VaultName $labVault.VaultName -Name WindowsAdminPassword
        if([string]::IsNullOrEmpty($testValue) -or $Force) {
            foreach ($secret in $secrets) {
                Write-Output "Updating $($secret.Name)..."
                $value = Get-AzureKeyVaultSecret -VaultName $secretsVault.VaultName -Name $secret.Name
                Set-AzureKeyVaultSecret -Name $secret.Name -VaultName $labVault.VaultName -SecretValue (ConvertTo-SecureString $value.SecretValueText -AsPlainText -Force)
            }
        } else {
            Write-Output "Value for WindowsAdminPassword found in KeyVault $($labVault.VaultName).  No further action required." -
        }
        } catch {
            Write-Error $Error[0].Exception
            exit -1
        }
    }
}

