Write-Host "Welcome to the SIMPLE MT-Trading-Framework Setup Wizard" -ForegroundColor Cyan

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

$setupFile = Join-Path -Path $PSScriptRoot -ChildPath "setup.json"

# Check if setup.json exists
if (Test-Path $setupFile) {
    $useExisting = Read-Host "A setup.json file already exists at $setupFile.`nDo you want to use the existing setup.json to set up the environment? (y/n)"
    if ($useExisting -eq "y") {
        Write-Host "Using existing setup.json to set up the environment..." -ForegroundColor Green
        try {
            # Run MTSetup.ps1 and capture output/errors
            $result = powershell.exe -File .\MTSetup.ps1 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "MTSetup.ps1 failed: $result"
            }
            Write-Host "Setup completed using existing setup.json." -ForegroundColor Green
        } catch {
            Write-Host "Failed to run MTSetup.ps1 with existing setup: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Full error details: $result" -ForegroundColor Red
            exit
        }
        exit
    }
}

# Prompt for cleanup
$cleanupChoice = Read-Host "Would you like to clean up the existing setup before proceeding? (y/n)"
if ($cleanupChoice -eq "y") {
    Write-Host "Running cleanup..." -ForegroundColor Yellow
    $collectionName = Read-Host "Enter Collection Name for cleanup (default: coll1)"
    if (-not $collectionName) { $collectionName = "coll1" }
    $strategyName = Read-Host "Enter Strategy Name for cleanup (default: DefaultStrategy)"
    if (-not $strategyName) { $strategyName = "DefaultStrategy" }
    
    try {
        powershell.exe -File .\Cleanup.ps1 -CollectionName $collectionName -StrategyName $strategyName
    } catch {
        Write-Host "Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

# Generate new setup
Write-Host "Generating new setup..." -ForegroundColor Yellow
try {
    powershell.exe -File .\MTSetup.ps1 -GenerateSetup
    Write-Host "Setup process completed." -ForegroundColor Green
} catch {
    Write-Host "Failed to generate new setup: $($_.Exception.Message)" -ForegroundColor Red
    exit
}