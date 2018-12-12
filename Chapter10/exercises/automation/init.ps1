<#
PowerShell bootstrap script.
#>
param (
    [string]
    $Editor="vs",
    [string]
    $ScriptLanguage="ps"
)
./util/pacmgr.ps1
./ide/install.ps1 $Editor
./custom/custom.ps1