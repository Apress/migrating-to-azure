#
# SetLabRBAC.ps1
#
# PS Script used during lab creation job to trigger Automation runbook

param (
	$RunbookName,
	$AutomationResourceGroup,
	$AutomationAccount,
	$Lab,
	$LabRG,
	$TeamADGroup
)

$job = Start-AzureRmAutomationRunbook -Name $RunbookName -ResourceGroupName $AutomationResourceGroup -AutomationAccountName $AutomationAccount `
-Parameters @{TeamADGroup="$($TeamADGroup)";LabName=$Lab;ResourceGroupName=$LabRG}

while($job.EndTime -eq $null) {
	$job = Get-AzureRmAutomationJob -Id $job.JobId -ResourceGroupName $job.ResourceGroupName -AutomationAccountName $job.AutomationAccountName
	[System.Threading.Thread]::Sleep(1000);
}

if($job.Status -eq "Failed") { 
	Write-Error "Job $($job.JobId) encountered an issue:"
	throw $job.Exception 
} else {
	Write-Output "Job ID $($job.JobId) completed with status $($job.Status)."
	Write-Output $job.StatusDetails
}