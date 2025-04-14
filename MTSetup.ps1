[CmdletBinding()]
param (
    [switch]$GenerateSetup
)

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

# Helper Functions
function Write-Status { param ([string]$Message, [string]$Color = "Yellow") Write-Host $Message -ForegroundColor $Color }
function Create-Directory { param ([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -ItemType Directory -Force | Out-Null; Write-Status "Created: $Path" "Green" } }
function Create-Shortcut {
    param ([string]$TargetPath, [string]$ShortcutPath, [string]$Description)
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Description = $Description
        $shortcut.Save()
        Write-Status "Created shortcut: $ShortcutPath" "Green"
    } catch {
        Write-Status "Failed to create shortcut at $ShortcutPath. Error: $($_.Exception.Message)" "Red"
    }
}
function Install-MetaTrader {
    param ([string]$Version, [string]$BrokerName, [string]$CollectionName, [string]$EnvironmentName, [string]$ExplicitPath, [string]$StrategyName)
    try {
        $basePath = "C:\Trading\MTFramework"
        $installPath = Join-Path -Path $basePath -ChildPath "$Version\$BrokerName\$CollectionName\$EnvironmentName\$Version"
        Create-Directory -Path $installPath
        $terminalName = if ($Version -eq "MT4") { "terminal.exe" } else { "terminal64.exe" }
        $sourceFolder = if ($ExplicitPath) {
            Split-Path -Path $ExplicitPath -Parent
        } else {
            $progFiles = if ([Environment]::Is64BitOperatingSystem) { "C:\Program Files (x86)" } else { "C:\Program Files" }
            $brokerFolder = Get-ChildItem -Path $progFiles -Directory | Where-Object { $_.Name -like "*$BrokerName*" } | Select-Object -First 1
            if ($brokerFolder) {
                $brokerFolder.FullName
            } else {
                Join-Path -Path $progFiles -ChildPath $BrokerName
            }
        }
        if (Test-Path $sourceFolder) {
            Copy-Item -Path "$sourceFolder\*" -Destination $installPath -Recurse -Force
            $terminalPath = Join-Path -Path $installPath -ChildPath $terminalName
            if (Test-Path $terminalPath) {
                Write-Status "Installed $Version for $BrokerName in $EnvironmentName at $installPath" "Green"
            } else {
                Write-Status "Warning: $terminalName not found in $sourceFolder" "Yellow"
            }
        } else {
            Write-Status "$Version installation not found at $sourceFolder. Please install MetaTrader or specify an explicit path." "Yellow"
        }
        $desktopPath = [System.Environment]::GetFolderPath("Desktop")
        $brokerFolder = Join-Path -Path $desktopPath -ChildPath $BrokerName
        Create-Directory -Path $brokerFolder
        $shortcutPath = Join-Path -Path $brokerFolder -ChildPath "$Version - $BrokerName [$CollectionName-$StrategyName] $EnvironmentName.lnk"
        $targetShortcutPath = Join-Path -Path $installPath -ChildPath $terminalName
        Create-Shortcut -TargetPath $targetShortcutPath -ShortcutPath $shortcutPath -Description "$Version $EnvironmentName"
        return @{ Version = $Version; BrokerName = $BrokerName; CollectionName = $CollectionName; EnvironmentName = $EnvironmentName; Path = $installPath; Terminal = $targetShortcutPath }
    } catch {
        Write-Status "Failed to install $Version for $BrokerName in $EnvironmentName. Error: $($_.Exception.Message)" "Red"
        throw
    }
}
function Setup-Strategy-Folders {
    param ([string]$InstallPath, [string]$Version, [string]$StrategyName)
    try {
        $mqlFolder = Join-Path -Path $InstallPath -ChildPath "MQL$($Version[-1])"
        Create-Directory -Path $mqlFolder
        $folders = @("Experts", "Indicators", "Scripts", "Include", "Libraries")
        foreach ($folder in $folders) {
            $path = Join-Path -Path $mqlFolder -ChildPath "$folder\$StrategyName"
            Create-Directory -Path $path
            if ($folder -eq "Experts") {
                $ext = if ($Version -eq "MT4") { "mq4" } else { "mq5" }
                $filePath = Join-Path -Path $path -ChildPath "SampleStrategy.$ext"
                "#property copyright 'xAI'\nvoid OnTick() { Print('Hello from $StrategyName'); }" | Set-Content -Path $filePath
                Write-Status "Created: $filePath" "Green"
            }
        }
    } catch {
        Write-Status "Failed to setup strategy folders for $Version at $InstallPath. Error: $($_.Exception.Message)" "Red"
        throw
    }
}
function Sync-CompiledFiles {
    param (
        [string]$MT4DevPath, [string]$MT4TestPath, [string]$MT4DeployPath, [string]$MT4PackagePath,
        [string]$MT5DevPath, [string]$MT5TestPath, [string]$MT5DeployPath, [string]$MT5PackagePath,
        [string]$CollectionName, [string]$StrategyName
    )
    try {
        $types = @("Experts", "Indicators", "Scripts")
        foreach ($type in $types) {
            if ($MT4DevPath) {
                $sourceMT4 = Join-Path -Path $MT4DevPath -ChildPath "MT4\MQL4"
                $mt4Files = Get-ChildItem -Path "$sourceMT4\$type\$StrategyName\*.ex4" -ErrorAction SilentlyContinue
                foreach ($file in $mt4Files) {
                    Write-Status "Copying $type file: $($file.Name) to environments" "Green"
                    Copy-Item -Path $file.FullName -Destination "$MT4DevPath\MQL4\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT4TestPath\MQL4\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT4DeployPath\MQL4\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT4PackagePath\$type" -Force
                }
            }
            if ($MT5DevPath) {
                $sourceMT5 = Join-Path -Path $MT5DevPath -ChildPath "MT5\MQL5"
                $mt5Files = Get-ChildItem -Path "$sourceMT5\$type\$StrategyName\*.ex5" -ErrorAction SilentlyContinue
                foreach ($file in $mt5Files) {
                    Write-Status "Copying $type file: $($file.Name) to environments" "Green"
                    Copy-Item -Path $file.FullName -Destination "$MT5DevPath\MQL5\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT5TestPath\MQL5\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT5DeployPath\MQL5\$type\$StrategyName" -Force
                    Copy-Item -Path $file.FullName -Destination "$MT5PackagePath\$type" -Force
                }
            }
        }
    } catch {
        Write-Status "Failed to sync compiled files. Error: $($_.Exception.Message)" "Red"
        throw
    }
}
function Update-BuildFile {
    param ([array]$Installations, [string]$CollectionName, [string]$StrategyName, [boolean]$SkipDocker)
    try {
        $buildFile = "C:\Trading\MTFramework\build.json"
        $buildConfig = if (Test-Path $buildFile) { Get-Content $buildFile -Raw | ConvertFrom-Json } else { @{ BasePath = "C:\Trading\MTFramework"; StrategyCollections = @() } }
        $mt4Paths = @{
            DevPath = "C:\Trading\MTFramework\MT4\afterprime\coll1\Dev"
            TestPath = "C:\Trading\MTFramework\MT4\afterprime\coll1\Test"
            DeployPath = "C:\Trading\MTFramework\MT4\afterprime\coll1\Deploy"
            PackagePath = "C:\Trading\MTFramework\MT4\afterprime\coll1\Package"
        }
        $mt5Paths = @{
            DevPath = "C:\Trading\MTFramework\MT5\afterprime\coll1\Dev"
            TestPath = "C:\Trading\MTFramework\MT5\afterprime\coll1\Test"
            DeployPath = "C:\Trading\MTFramework\MT5\afterprime\coll1\Deploy"
            PackagePath = "C:\Trading\MTFramework\MT5\afterprime\coll1\Package"
        }
        $newCollection = @{
            CollectionName = $CollectionName
            StrategyName = $StrategyName
            SkipDocker = $SkipDocker
            Installations = $Installations
            Config = @{
                MT4RootPath = "C:\Trading\MTFramework\MT4"
                MT5RootPath = "C:\Trading\MTFramework\MT5"
                MT4Paths = $mt4Paths
                MT5Paths = $mt5Paths
            }
        }
        $buildConfig.StrategyCollections = @($buildConfig.StrategyCollections | Where-Object { $_.CollectionName -ne $CollectionName -or $_.StrategyName -ne $StrategyName }) + $newCollection
        $buildConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $buildFile
        Write-Status "Updated build file: $buildFile" "Green"
    } catch {
        Write-Status "Failed to update build file. Error: $($_.Exception.Message)" "Red"
        throw
    }
}
function Start-Setup {
    param ([string]$CollectionName, [string]$StrategyName)
    try {
        $setupFile = Join-Path -Path $PSScriptRoot -ChildPath "setup.json"
        $setupConfig = Get-Content $setupFile -Raw | ConvertFrom-Json
        $sc = $setupConfig.StrategyCollections | Where-Object { $_.CollectionName -eq $CollectionName -and $_.StrategyName -eq $StrategyName }
        if (-not $sc) {
            Write-Status "Strategy collection $CollectionName-$StrategyName not found in $setupFile" "Red"
            throw "Configuration not found"
        }
        $installations = @()
        foreach ($platform in $sc.Platforms) {
            foreach ($env in $platform.Environments) {
                $install = Install-MetaTrader -Version $platform.Platform -BrokerName $platform.BrokerName -CollectionName $CollectionName -EnvironmentName $env -ExplicitPath $platform.ExplicitPath -StrategyName $StrategyName
                $installations += $install
                Setup-Strategy-Folders -InstallPath $install.Path -Version $platform.Platform -StrategyName $StrategyName
            }
        }
        Update-BuildFile -Installations $installations -CollectionName $CollectionName -StrategyName $StrategyName -SkipDocker $sc.SkipDocker
    } catch {
        Write-Status "Failed to start setup for $CollectionName-$StrategyName. Error: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main execution logic
function Main {
    try {
        $setupFile = Join-Path -Path $PSScriptRoot -ChildPath "setup.json"
        if ($GenerateSetup) {
            $basePath = "C:\Trading\MTFramework"
            $collectionName = "coll1"
            $strategyName = "DefaultStrategy"
            $platforms = @()
            
            Write-Host "Select the platform(s) to set up:"
            Write-Host "1. MT4 Only"
            Write-Host "2. MT5 Only"
            Write-Host "3. Both MT4 and MT5"
            $platformChoice = Read-Host "Enter your choice (1-3)"
            
            if ($platformChoice -notin @("1", "2", "3")) {
                Write-Status "Invalid choice. Please select 1, 2, or 3." "Red"
                exit
            }
            
            $mt4BrokerName = Read-Host "Enter MT4 Broker Name (default: afterprime)"
            if (-not $mt4BrokerName) { $mt4BrokerName = "afterprime" }
            
            $mt5BrokerName = Read-Host "Enter MT5 Broker Name (default: afterprime)"
            if (-not $mt5BrokerName) { $mt5BrokerName = "afterprime" }
            
            $mt4Path = Read-Host "Enter explicit MT4 installation path (leave blank to auto-detect)"
            $mt5Path = Read-Host "Enter explicit MT5 installation path (leave blank to auto-detect)"
            
            $dockerChoice = Read-Host "Use Docker for advanced compilation? (1 for Yes, 0 for No)"
            $skipDocker = $dockerChoice -eq "0"
            
            if ($platformChoice -eq "1" -or $platformChoice -eq "3") {
                $platforms += @{ Platform = "MT4"; BrokerName = $mt4BrokerName; ExplicitPath = $mt4Path; Environments = @("Dev", "Test", "Deploy") }
            }
            if ($platformChoice -eq "2" -or $platformChoice -eq "3") {
                $platforms += @{ Platform = "MT5"; BrokerName = $mt5BrokerName; ExplicitPath = $mt5Path; Environments = @("Dev", "Test", "Deploy") }
            }
            
            $newSetup = @{
                BasePath = $basePath
                StrategyCollections = @(
                    @{
                        CollectionName = $collectionName
                        StrategyName = $strategyName
                        Platforms = $platforms
                        SkipDocker = $skipDocker
                    }
                )
            }
            
            $newSetup | ConvertTo-Json -Depth 10 | Set-Content -Path $setupFile
            Write-Status "Generated new setup file at $setupFile" "Green"
        }

        if (-not (Test-Path $setupFile)) {
            Write-Status "Setup file not found at $setupFile" "Red"
            exit
        }
        $setupConfig = Get-Content $setupFile -Raw | ConvertFrom-Json
        if (-not $setupConfig.StrategyCollections) {
            Write-Status "No StrategyCollections found in $setupFile" "Red"
            exit
        }
        foreach ($sc in $setupConfig.StrategyCollections) {
            Start-Setup -CollectionName $sc.CollectionName -StrategyName $sc.StrategyName
        }
    } catch {
        Write-Status "Main setup failed. Error: $($_.Exception.Message)" "Red"
        exit
    }
}

# Only execute Main if the script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}