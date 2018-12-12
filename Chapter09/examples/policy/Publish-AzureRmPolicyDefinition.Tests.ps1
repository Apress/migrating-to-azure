$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Publish-AzureRmPolicyDefinition" {
    $PolicyName = [string]::Format("{0}-Test", [System.Guid]::NewGuid())
    $PolicyPath = "./vm/AuditVmSku"
    #Mock Publish-AzureRmPolicyDefinition { @{PolicyName="$($PolicyName)";PolicyPath="./vm/AuditVmSku"} }
    It "outputs a policy object" {
        $policy = Publish-AzureRmPolicyDefinition -PolicyName $PolicyName -PolicyPath $PolicyPath -Test
        $policy | Should Not Be $null
    }
}