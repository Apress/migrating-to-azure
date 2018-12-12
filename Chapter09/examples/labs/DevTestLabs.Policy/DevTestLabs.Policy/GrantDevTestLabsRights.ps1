<#
GrantDevTestLabsRights.ps1

.DESCRIPTION
Runbook source for Azure Automation job that grants permissions to DTL
#>
param (
  [string]
  [parameter(Mandatory=$true)]
  $TeamADGroup,
  [string]
  [parameter(Mandatory=$true)]
  $LabName,
  [string]
  [parameter(Mandatory=$true)]
  $ResourceGroupName,
  [string]
  $SubscriptionName,
  [string]
  [parameter(Mandatory=$true,HelpMessage="The name of the Azure Automation credential to use when executing this script.")]
  $CredentialAssetName
)
	
#Get the credential with the above name from the Automation Asset store
$Cred = Get-AutomationPSCredential -Name $CredentialAssetName;
if (!$Cred) {
    Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
} 
#Connect to your Azure Account
Add-AzureRmAccount -Credential $Cred; 
Select-AzureRmSubscription -SubscriptionName "$($SubscriptionName)"
    
$group = Get-AzureRmADGroup -SearchString "$($TeamADGroup)"
New-AzureRmRoleAssignment -ObjectId $group.Id.Guid -RoleDefinitionName "DevTest Labs User" -ResourceName $LabName -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.DevTestLab/labs"
New-AzureRmRoleAssignment -ObjectId $group.Id.Guid -RoleDefinitionName "Virtual Machine Contributor" -ResourceName $LabName -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.DevTestLab/labs"