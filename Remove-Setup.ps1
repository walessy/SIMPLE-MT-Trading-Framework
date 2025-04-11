[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$BasePath,
    [Parameter(Mandatory=$true)]
    [string]$StrategyName,
    [Parameter(Mandatory=$true)]
    [string]$CollectionName
)

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

function Write-Status { param ([string]$Message, [string]$Color = "Yellow") Write-Host $Message -ForegroundColor $Color }

# Remove from config file
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
if (-not (Test-Path $configFile)) {
    Write-Status "Config file not found at $configFile. Nothing to remove." "Red"
    exit 1
}

$config = Get-Content $configFile -Raw | ConvertFrom-Json
$updatedConfig = $config | Where-Object { -not ($_.BasePath -eq $BasePath -and $_.StrategyName -eq $StrategyName -and $_.CollectionName -eq $CollectionName) }

if ($updatedConfig.Count -eq $config.Count) {
    Write-Status "Setup with BasePath=$BasePath, StrategyName=$StrategyName, CollectionName=$CollectionName not found in config." "Red"
    exit 1
}

$updatedConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile
Write-Status "Removed setup from config file: $configFile" "Green"

# Remove files
$mt4Path = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName"
$mt5Path = Join-Path -Path $BasePath -ChildPath "MT5\$MT5BrokerName\$CollectionName"
if (Test-Path $mt4Path) { Remove-Item -Path $mt4Path -Recurse -Force; Write-Status "Removed MT4 setup at $mt4Path" "Green" }
if (Test-Path $mt5Path) { Remove-Item -Path $mt5Path -Recurse -Force; Write-Status "Removed MT5 setup at $mt5Path" "Green" }

Write-Status "Setup removal complete." "Green"