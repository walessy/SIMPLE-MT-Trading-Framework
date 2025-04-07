# Easy-Setup.ps1
# User-friendly parameter collector for MT Trading Framework
# Run as administrator

[CmdletBinding()]
param (
    [switch]$Help
)

# Change to the script's directory
Set-Location -Path $PSScriptRoot

# Show colorful welcome message
function Show-Welcome {
    Clear-Host
    Write-Host "╔═════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        MT Trading Framework Setup           ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Display help screen
if ($Help) {
    Show-Welcome
    Write-Host "HELP - EASY SETUP" -ForegroundColor Yellow
    Write-Host "This script collects parameters to set up the MT Trading Framework."
    Write-Host "Usage: .\Easy-Setup.ps1 [-Help]"
    Write-Host ""
    Write-Host "The script will prompt for:"
    Write-Host "  - Strategy name"
    Write-Host "  - User level (Basic/Advanced)"
    Write-Host "  - Platform choice (MT4/MT5/Both)"
    Write-Host "  - Installation path"
    exit
}

Show-Welcome

# Collect parameters
$parameters = @{}

# Strategy Name
Write-Host "Please enter a name for your trading strategy:" -ForegroundColor Yellow
$parameters["DevEnvironmentName"] = Read-Host
if ([string]::IsNullOrEmpty($parameters["DevEnvironmentName"])) {
    $parameters["DevEnvironmentName"] = "MyStrategy"
    Write-Host "Using default name: $($parameters["DevEnvironmentName"])" -ForegroundColor Yellow
}
$parameters["TestEnvironmentName"] = "Test_$($parameters["DevEnvironmentName"])"

# User Level
Write-Host "`nSelect your user level:" -ForegroundColor Yellow
Write-Host "1. Basic - Simple setup, no Docker required"
Write-Host "2. Advanced - Full features with Docker compilation"
$levelChoice = Read-Host "Enter your choice (1-2)"
$parameters["SkipDocker"] = ($levelChoice -ne "2")
Write-Host "Selected user level: $(if ($parameters["SkipDocker"]) { "Basic" } else { "Advanced" })" -ForegroundColor Green

# Platform Choice
Write-Host "`nWhich platform(s) do you want to use?" -ForegroundColor Yellow
Write-Host "1. MetaTrader 4 only"
Write-Host "2. MetaTrader 5 only"
Write-Host "3. Both MT4 and MT5"
$platformChoice = Read-Host "Enter your choice (1-3)"
$parameters["SkipMT4"] = ($platformChoice -eq "2")
$parameters["SkipMT5"] = ($platformChoice -eq "1")

# Broker Names and Paths
if (-not $parameters["SkipMT4"]) {
    Write-Host "`nEnter a name for your MT4 broker (e.g., 'ICMarkets'):" -ForegroundColor Yellow
    $parameters["MT4BrokerName"] = Read-Host
    if ([string]::IsNullOrEmpty($parameters["MT4BrokerName"])) {
        $parameters["MT4BrokerName"] = "Default"
        Write-Host "Using default MT4 broker name: $($parameters["MT4BrokerName"])" -ForegroundColor Yellow
    }
    $parameters["MT4Path"] = Read-Host "Enter MT4 installation path (leave empty to auto-detect)"
}

if (-not $parameters["SkipMT5"]) {
    Write-Host "`nEnter a name for your MT5 broker (e.g., 'ICMarkets'):" -ForegroundColor Yellow
    $parameters["MT5BrokerName"] = Read-Host
    if ([string]::IsNullOrEmpty($parameters["MT5BrokerName"])) {
        $parameters["MT5BrokerName"] = "Default"
        Write-Host "Using default MT5 broker name: $($parameters["MT5BrokerName"])" -ForegroundColor Yellow
    }
    $parameters["MT5Path"] = Read-Host "Enter MT5 installation path (leave empty to auto-detect)"
}

# Installation Path
$defaultPath = "C:\Trading\MTFramework"
Write-Host "`nWhere would you like to install the MT Trading Framework?" -ForegroundColor Yellow
Write-Host "Default: $defaultPath"
$customPath = Read-Host "Press Enter for default or type a custom path"
$parameters["BasePath"] = if ([string]::IsNullOrEmpty($customPath)) { $defaultPath } else { $customPath }

# Confirm
Write-Host "`nPlease confirm your choices:" -ForegroundColor Yellow
foreach ($key in $parameters.Keys) {
    Write-Host "$key : $($parameters[$key])"
}
$confirm = Read-Host "Is this correct? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit
}

# Call MTSetup.ps1
Write-Host "`nStarting setup..." -ForegroundColor Green
try {
    & .\MTSetup.ps1 @parameters
    Write-Host "`nSetup completed successfully! Check your desktop for shortcuts." -ForegroundColor Green
    Write-Host "For Advanced users: Use 'Build' shortcuts to compile with Docker." -ForegroundColor Yellow
} catch {
    Write-Host "Error during setup: $_" -ForegroundColor Red
}