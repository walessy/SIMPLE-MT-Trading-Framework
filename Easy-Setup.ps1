# Easy-Setup.ps1
# User-friendly setup script for MT Trading Framework
# Run as administrator

[CmdletBinding()]
param (
    [string]$StrategyName = "",
    [ValidateSet("Basic", "Advanced")]
    [string]$UserLevel = "",
    [switch]$Help
)

# Show colorful welcome message
function Show-Welcome {
    Clear-Host
    Write-Host "╔═════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                             ║" -ForegroundColor Cyan
    Write-Host "║        MT Trading Framework Setup           ║" -ForegroundColor Cyan
    Write-Host "║                                             ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Display help screen
if ($Help) {
    Show-Welcome
    Write-Host "HELP - EASY SETUP" -ForegroundColor Yellow
    Write-Host "This script provides a simple way to set up the MT Trading Framework."
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\Easy-Setup.ps1 [options]"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -StrategyName   - Optional: Name of your trading strategy"
    Write-Host "  -UserLevel      - Optional: 'Basic' or 'Advanced'"
    Write-Host "                    Basic: Simple setup, no Docker required"
    Write-Host "                    Advanced: Full features with Docker compilation"
    Write-Host "  -Help           - Display this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\Easy-Setup.ps1"
    Write-Host "  .\Easy-Setup.ps1 -StrategyName ""My MACD Strategy"""
    Write-Host "  .\Easy-Setup.ps1 -UserLevel ""Basic"""
    Write-Host "  .\Easy-Setup.ps1 -StrategyName ""My MACD Strategy"" -UserLevel ""Advanced"""
    Write-Host ""
    exit
}

# Check if running as administrator
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $user
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Show welcome screen
Show-Welcome

# Get strategy name if not provided
if ([string]::IsNullOrEmpty($StrategyName)) {
    Write-Host "`nPlease enter a name for your trading strategy:" -ForegroundColor Yellow
    $StrategyName = Read-Host
    if ([string]::IsNullOrEmpty($StrategyName)) {
        $StrategyName = "MyStrategy"
        Write-Host "Using default name: $StrategyName" -ForegroundColor Yellow
    }
}

# Get user level if not provided
if ([string]::IsNullOrEmpty($UserLevel)) {
    Write-Host "`nSelect your user level:" -ForegroundColor Yellow
    Write-Host "1. Basic - Simple setup, no Docker required"
    Write-Host "2. Advanced - Full features with Docker compilation"
    $levelChoice = Read-Host "Enter your choice (1-2)"
    
    switch ($levelChoice) {
        "1" { $UserLevel = "Basic" }
        "2" { $UserLevel = "Advanced" }
        default { $UserLevel = "Basic" }
    }
}

Write-Host "`nSelected user level: $UserLevel" -ForegroundColor Green

# Check for required software based on user level
$prerequisites = @{
    "Git" = { 
        try { git --version | Out-Null; return $true } 
        catch { return $false } 
    }
}

if ($UserLevel -eq "Advanced") {
    $prerequisites["Docker"] = { 
        try { docker --version | Out-Null; return $true } 
        catch { return $false } 
    }
}

$missing = @()

Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
foreach ($prereq in $prerequisites.Keys) {
    $check = & $prerequisites[$prereq]
    if ($check) {
        Write-Host "✓ $prereq is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $prereq is missing" -ForegroundColor Red
        $missing += $prereq
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`nPlease install the following software before continuing:" -ForegroundColor Red
    foreach ($item in $missing) {
        if ($item -eq "Docker") {
            Write-Host "- Docker Desktop: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
            if ($UserLevel -eq "Basic") {
                Write-Host "  Note: You can switch to Basic mode to continue without Docker" -ForegroundColor Yellow
            }
        }
        if ($item -eq "Git") {
            Write-Host "- Git: https://git-scm.com/downloads" -ForegroundColor Yellow
        }
    }
    
    if ($UserLevel -eq "Advanced" -and $missing -contains "Docker") {
        Write-Host "`nWould you like to switch to Basic mode and continue without Docker? (Y/N)" -ForegroundColor Yellow
        $switchMode = Read-Host
        if ($switchMode -eq "Y" -or $switchMode -eq "y") {
            $UserLevel = "Basic"
            $missing = $missing | Where-Object { $_ -ne "Docker" }
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "`nAfter installing the required software, please run this script again." -ForegroundColor Yellow
        exit 1
    }
}

# Ask about MT4/MT5
Write-Host "`nWhich platform(s) do you want to set up?" -ForegroundColor Yellow
Write-Host "1. MetaTrader 4 only"
Write-Host "2. MetaTrader 5 only"
Write-Host "3. Both MT4 and MT5 (recommended)" -ForegroundColor Cyan
$platformChoice = Read-Host "Enter your choice (1-3)"

$setupMT4 = $false
$setupMT5 = $false

switch ($platformChoice) {
    "1" { $setupMT4 = $true }
    "2" { $setupMT5 = $true }
    default { $setupMT4 = $true; $setupMT5 = $true }
}

# Choose installation path
$defaultPath = "C:\Trading\MTFramework"
Write-Host "`nWhere would you like to install the MT Trading Framework?" -ForegroundColor Yellow
Write-Host "Default: $defaultPath"
$customPath = Read-Host "Press Enter for default or type a custom path"

if ([string]::IsNullOrEmpty($customPath)) {
    $installPath = $defaultPath
} else {
    $installPath = $customPath
}

# Confirm choices
Write-Host "`nPlease confirm your choices:" -ForegroundColor Yellow
Write-Host "Strategy name: $StrategyName"
Write-Host "User level: $UserLevel"
Write-Host "Installation path: $installPath"
Write-Host "Setup MT4: $setupMT4"
Write-Host "Setup MT5: $setupMT5"
Write-Host ""
$confirm = Read-Host "Is this correct? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Setup cancelled. Please run the script again." -ForegroundColor Red
    exit
}

# Build parameters for MTSetup.ps1
$parameters = @("-BasePath", "`"$installPath`"", "-DevEnvironmentName", "`"$StrategyName`"")
if (-not $setupMT4) { $parameters += "-SkipMT4" }
if (-not $setupMT5) { $parameters += "-SkipMT5" }
if ($UserLevel -eq "Basic") { $parameters += "-SkipDocker" }

# Run the main setup script
Write-Host "`nStarting installation..." -ForegroundColor Green
Write-Host "This might take a few minutes. Please be patient." -ForegroundColor Yellow

try {
    # Run the main setup script with our parameters
    & .\MTSetup.ps1 @parameters
    
    # Create additional files for Basic mode
    if ($UserLevel -eq "Basic") {
        Write-Host "`nCreating MetaTrader build script for Basic mode..." -ForegroundColor Yellow
        
        $buildScript = @"
@echo off
echo Simple Build Script for $StrategyName (Basic Mode)
echo ==============================================
echo.

set DEV_PATH=$installPath\Dev\$StrategyName
set MT4_PATH=$installPath\MT4
set MT5_PATH=$installPath\MT5

echo Building using MetaTrader compilers...
echo.

if exist "%MT4_PATH%" (
    echo Building MT4 files...
    for /r "%DEV_PATH%\src\strategies" %%f in (*.mq4) do (
        echo Compiling: %%~nxf
        mkdir "%DEV_PATH%\build\mt4" 2>nul
        copy "%%f" "%MT4_PATH%\*\MQL4\Experts\" > nul
        echo File copied to MetaTrader 4
    )
)

if exist "%MT5_PATH%" (
    echo Building MT5 files...
    for /r "%DEV_PATH%\src\strategies" %%f in (*.mq5) do (
        echo Compiling: %%~nxf
        mkdir "%DEV_PATH%\build\mt5" 2>nul
        copy "%%f" "%MT5_PATH%\*\MQL5\Experts\" > nul
        echo File copied to MetaTrader 5
    )
)

echo.
echo Files copied to MetaTrader folders.
echo.
echo IMPORTANT: 
echo To complete compilation, please open each MetaTrader terminal,
echo navigate to your strategy in the Navigator panel, and press F7 
echo or right-click and select "Compile".
echo.
echo After compilation, run the Sync script to copy the compiled files 
echo back to your development environment.
echo.
pause
"@
        
        $buildScriptPath = Join-Path -Path $installPath -ChildPath "Dev\$StrategyName\basic-build.bat"
        Set-Content -Path $buildScriptPath -Value $buildScript
        
        # Create desktop shortcut for basic build
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Build $StrategyName (Basic).lnk")
        $Shortcut.TargetPath = $buildScriptPath
        $Shortcut.Save()
    }
    
    # Create a simple welcome screen
    Write-Host "`n✓ Setup completed successfully!" -ForegroundColor Green
    Write-Host "`nYour MT Trading Framework is ready!" -ForegroundColor Cyan
    Write-Host "Shortcuts have been created on your desktop:" -ForegroundColor Yellow
    
    if ($UserLevel -eq "Basic") {
        Write-Host "- MetaTrader terminals: Use these to trade and test strategies"
        Write-Host "- Basic Build shortcut: Use this to copy and compile your trading strategies"
    } else {
        Write-Host "- MetaTrader terminals: Use these to trade and test strategies"
        Write-Host "- Docker Build shortcut: Use this to compile your trading strategies"
    }
    
    Write-Host "`nYour strategy files are located at:" -ForegroundColor Yellow
    Write-Host "$installPath\Dev\$StrategyName\src\strategies\"
    
    if ($UserLevel -eq "Basic") {
        Write-Host "`nIMPORTANT NOTE FOR BASIC USERS:" -ForegroundColor Magenta
        Write-Host "1. Use the 'Build $StrategyName (Basic)' shortcut to copy files to MetaTrader"
        Write-Host "2. Open MetaTrader and compile your strategies by pressing F7"
        Write-Host "3. Use the dashboard to sync compiled files back to your development environment"
    }
    
    Write-Host "`nHappy trading!" -ForegroundColor Cyan
} catch {
    Write-Host "An error occurred during setup:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Please try running the setup again or check the error message above." -ForegroundColor Yellow
}
