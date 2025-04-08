# TestCmdletBinding.ps1
[CmdletBinding()]
param (
    [string]$TestParam = "Hello"
)
Write-Host "TestParam is: $TestParam"