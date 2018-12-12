#
# Script.ps1
#

choco sources add -n devops -s https://liazon.myget.org/F/devops/auth/0ba3178c-d4c8-4844-8185-ddee8193fbc3/api/v2
choco sources remove -n chocolatey

cinst vs2015remotetools vs2017remotetools -y

Write-Output "Remote debugging tools installed successfully."
