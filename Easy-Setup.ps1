# Easy-Setup.ps1
# Simple Setup Script for MT Trading Framework

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

Write-Host "Welcome to the MT Trading Framework Setup" -ForegroundColor Cyan
Write-Host "Please run this script as Administrator for full functionality.`n"

# Prompt for MetaTrader version
Write-Host "Select MetaTrader version to install:" -ForegroundColor Yellow
Write-Host "1. MT4 Only"
Write-Host "2. MT5 Only"
Write-Host "3. Both MT4 and MT5"
$versionChoice = Read-Host "Enter your choice (1-3)"

$skipMT4 = $false
$skipMT5 = $false
switch ($versionChoice) {
    "1" { $skipMT5 = $true }
    "2" { $skipMT4 = $true }
    "3" { } # Both MT4 and MT5
    default { Write-Host "Invalid choice. Defaulting to both MT4 and MT5." -ForegroundColor Red }
}

# Prompt for broker names
if (-not $skipMT4) {
    $mt4Broker = Read-Host "Enter MT4 broker name (e.g., AfterPrime)"
    if ([string]::IsNullOrWhiteSpace($mt4Broker)) { $mt4Broker = "Default" }
} else {
    $mt4Broker = "Default"
}

if (-not $skipMT5) {
    $mt5Broker = Read-Host "Enter MT5 broker name (e.g., AfterPrime)"
    if ([string]::IsNullOrWhiteSpace($mt5Broker)) { $mt5Broker = "Default" }
} else {
    $mt5Broker = "Default"
}

# Prompt for explicit paths (optional)
$mt4Path = Read-Host "Enter explicit MT4 installation path (optional, press Enter to auto-detect)"
$mt5Path = Read-Host "Enter explicit MT5 installation path (optional, press Enter to auto-detect)"

# Prompt for setup mode
Write-Host "`nSelect setup mode:" -ForegroundColor Yellow
Write-Host "1. Basic (Install MT4/MT5 only)"
Write-Host "2. Advanced (Include build environment with Docker)"
$modeChoice = Read-Host "Enter your choice (1-2)"
$skipDocker = $modeChoice -ne "2"

# Prompt for strategy name (used in both modes)
$strategyName = Read-Host "Enter strategy name (e.g., Amos)"
if ([string]::IsNullOrWhiteSpace($strategyName)) { $strategyName = "DefaultStrategy" }

# Construct parameters for MTSetup.ps1
$params = @{
    BasePath = "C:\Trading\MTFramework"
    SkipMT4 = $skipMT4
    SkipMT5 = $skipMT5
    MT4BrokerName = $mt4Broker
    MT5BrokerName = $mt5Broker
    MT4Path = $mt4Path
    MT5Path = $mt5Path
    SkipDocker = $skipDocker
    DevEnvironmentName = $strategyName
}
if (-not $skipDocker) {
    $params.TestEnvironmentName = "Test_$strategyName"
}

# Run MTSetup.ps1 using absolute path
$mtSetupPath = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
Write-Host "`nStarting setup..." -ForegroundColor Cyan
try {
    if (Test-Path $mtSetupPath) {
        & $mtSetupPath @params
    } else {
        throw "MTSetup.ps1 not found in $PSScriptRoot"
    }
} catch {
    Write-Host "Error during setup: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nSetup finished. Check your desktop for shortcuts and $params.BasePath for the framework." -ForegroundColor Green