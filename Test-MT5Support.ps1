# Test-MT5Support.ps1
# Tests MT5 support in Advanced mode of MTSetup.ps1

# Set up test environment
$testDir = "C:\TradingTest"
$strategyName = "TestStrategy"
$collectionName = "TestColl"
$mt5BrokerName = "TestBrokerMT5"
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Simulate MT5 installation
$mt5Source = Join-Path -Path $testDir -ChildPath "MT5Source"
New-Item -Path $mt5Source -ItemType Directory -Force | Out-Null
Set-Content -Path "$mt5Source\terminal64.exe" -Value "Fake MT5 executable"

# Copy all required files to test directory
Copy-Item -Path ".\MTSetup.ps1" -Destination $testDir
Copy-Item -Path ".\Dockerfile" -Destination $testDir
Copy-Item -Path ".\docker-compose.yml" -Destination $testDir
New-Item -Path "$testDir\scripts" -ItemType Directory -Force | Out-Null
Copy-Item -Path ".\scripts\build_mt4.sh" -Destination "$testDir\scripts"
Copy-Item -Path ".\scripts\build_mt5.sh" -Destination "$testDir\scripts"

# Run MTSetup.ps1 in Advanced mode for MT5
Set-Location -Path $testDir
.\MTSetup.ps1 -BasePath "$testDir\MTFramework" -MT5BrokerName $mt5BrokerName -StrategyName $strategyName -CollectionName $collectionName -SkipMT4 -MT5Path $mt5Source

# Verification functions
function Test-DirectoryExists { param ([string]$Path) if (Test-Path $Path) { Write-Host "PASS: $Path exists" -ForegroundColor Green } else { Write-Host "FAIL: $Path missing" -ForegroundColor Red } }
function Test-FileExists { param ([string]$Path) if (Test-Path $Path) { Write-Host "PASS: $Path exists" -ForegroundColor Green } else { Write-Host "FAIL: $Path missing" -ForegroundColor Red } }

# Test MT5 directory structure and files
$mt5Path = "$testDir\MTFramework\MT5\$mt5BrokerName\$collectionName\MT5"
Write-Host "Verifying MT5 Support in Advanced Mode..." -ForegroundColor Cyan
Test-DirectoryExists -Path $mt5Path
Test-FileExists -Path "$mt5Path\terminal64.exe"
Test-DirectoryExists -Path "$mt5Path\MQL5\Experts\$strategyName"
Test-FileExists -Path "$mt5Path\MQL5\Experts\$strategyName\SampleStrategy.mq5"
Test-FileExists -Path "$mt5Path\MQL5\Experts\$strategyName\SampleStrategy.ex5"
Test-DirectoryExists -Path "$mt5Path\MQL5\Indicators\$strategyName"
Test-FileExists -Path "$mt5Path\MQL5\Indicators\$strategyName\SampleIndicator.mq5"
Test-FileExists -Path "$mt5Path\MQL5\Indicators\$strategyName\SampleIndicator.ex5"
Test-DirectoryExists -Path "$mt5Path\MQL5\Scripts\$strategyName"
Test-FileExists -Path "$mt5Path\MQL5\Scripts\$strategyName\SampleScript.mq5"
Test-FileExists -Path "$mt5Path\MQL5\Scripts\$strategyName\SampleScript.ex5"
Test-DirectoryExists -Path "$mt5Path\MQL5\Include\$strategyName"
Test-FileExists -Path "$mt5Path\MQL5\Include\$strategyName\SampleInclude.mqh"
Test-FileExists -Path "$([System.Environment]::GetFolderPath('Desktop'))\$mt5BrokerName\MT5 - $mt5BrokerName [$collectionName-$strategyName]Strategy.lnk"

# Cleanup
Set-Location -Path $PSScriptRoot
docker-compose -f "$testDir\docker-compose.yml" down -v --rmi local 2>$null
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "MT5 Support Test Complete" -ForegroundColor Cyan