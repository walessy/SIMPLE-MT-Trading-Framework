# Test-AdvancedMode.ps1
# Tests Advanced mode (Option 2) of MTSetup.ps1 with Docker

# Set up test environment
$testDir = "C:\TradingTest"
$strategyName = "TestStrategy"
$collectionName = "TestColl"
$mt4BrokerName = "TestBroker"
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Simulate MT4 installation
$mt4Source = Join-Path -Path $testDir -ChildPath "MT4Source"
New-Item -Path $mt4Source -ItemType Directory -Force | Out-Null
Set-Content -Path "$mt4Source\terminal.exe" -Value "Fake MT4 executable"

# Copy all required files to test directory
Copy-Item -Path ".\MTSetup.ps1" -Destination $testDir
Copy-Item -Path ".\Dockerfile" -Destination $testDir
Copy-Item -Path ".\docker-compose.yml" -Destination $testDir
New-Item -Path "$testDir\scripts" -ItemType Directory -Force | Out-Null
Copy-Item -Path ".\scripts\build_mt4.sh" -Destination "$testDir\scripts"
Copy-Item -Path ".\scripts\build_mt5.sh" -Destination "$testDir\scripts"

# Run MTSetup.ps1 in Advanced mode
Set-Location -Path $testDir
.\MTSetup.ps1 -BasePath "$testDir\MTFramework" -MT4BrokerName $mt4BrokerName -StrategyName $strategyName -CollectionName $collectionName -MT4Path $mt4Source

# Verification functions
function Test-DirectoryExists { param ([string]$Path) if (Test-Path $Path) { Write-Host "PASS: $Path exists" -ForegroundColor Green } else { Write-Host "FAIL: $Path missing" -ForegroundColor Red } }
function Test-FileExists { param ([string]$Path) if (Test-Path $Path) { Write-Host "PASS: $Path exists" -ForegroundColor Green } else { Write-Host "FAIL: $Path missing" -ForegroundColor Red } }
function Test-DockerRunning { param ([string]$Service) if (docker ps -q -f "name=$Service") { Write-Host "PASS: Docker service $Service running" -ForegroundColor Green } else { Write-Host "FAIL: Docker service $Service not running" -ForegroundColor Red } }

# Test directory structure, files, and compilation
$mt4Path = "$testDir\MTFramework\MT4\$mt4BrokerName\$collectionName\MT4"
Write-Host "Verifying Advanced Mode Setup..." -ForegroundColor Cyan
Test-DirectoryExists -Path $mt4Path
Test-FileExists -Path "$mt4Path\terminal.exe"
Test-DirectoryExists -Path "$mt4Path\MQL4\Experts\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Experts\$strategyName\SampleStrategy.mq4"
Test-FileExists -Path "$mt4Path\MQL4\Experts\$strategyName\SampleStrategy.ex4"
Test-DirectoryExists -Path "$mt4Path\MQL4\Indicators\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Indicators\$strategyName\SampleIndicator.mq4"
Test-FileExists -Path "$mt4Path\MQL4\Indicators\$strategyName\SampleIndicator.ex4"
Test-DirectoryExists -Path "$mt4Path\MQL4\Scripts\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Scripts\$strategyName\SampleScript.mq4"
Test-FileExists -Path "$mt4Path\MQL4\Scripts\$strategyName\SampleScript.ex4"
Test-DirectoryExists -Path "$mt4Path\MQL4\Libraries\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Libraries\$strategyName\SampleLibrary.mq4"
Test-DirectoryExists -Path "$mt4Path\MQL4\Include\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Include\$strategyName\SampleInclude.mqh"
Test-DirectoryExists -Path "$mt4Path\MQL4\Files\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Files\$strategyName\SampleFile.txt"
Test-DirectoryExists -Path "$mt4Path\MQL4\Images\$strategyName"
Test-FileExists -Path "$mt4Path\MQL4\Images\$strategyName\SampleImage.txt"
Test-DirectoryExists -Path "$mt4Path\Templates\$strategyName"
Test-FileExists -Path "$mt4Path\Templates\$strategyName\SampleTemplate.tpl"
Test-FileExists -Path "$mt4Path\origin.ini"
Test-FileExists -Path "$([System.Environment]::GetFolderPath('Desktop'))\$mt4BrokerName\MT4 - $mt4BrokerName [$collectionName-$strategyName]Strategy.lnk"

# Test Docker setup (image built, but container should be stopped after compilation)
$dockerImage = docker images -q mt_builder
if ($dockerImage) { Write-Host "PASS: Docker image mt_builder built" -ForegroundColor Green } else { Write-Host "FAIL: Docker image mt_builder not built" -ForegroundColor Red }

# Cleanup
Set-Location -Path $PSScriptRoot
docker-compose -f "$testDir\docker-compose.yml" down -v --rmi local 2>$null
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Advanced Mode Test Complete" -ForegroundColor Cyan