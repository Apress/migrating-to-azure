<#
Package management setup
1. Install chocolatey, if windows
2. Install package(s), if windows
#>
if($env:OS -eq "Windows_NT") {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))  
} else {
    .$PWD/util/pacmgr.sh
}
