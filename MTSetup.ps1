[CmdletBinding()]
param (
    [string]$BasePath = "C:\Trading\MTFramework",
    [switch]$SkipMT4,
    [switch]$SkipMT5,
    [string]$MT4BrokerName = "Default",
    [string]$MT5BrokerName = "Default",
    [string]$MT4Path = "",
    [string]$MT5Path = "",
    [switch]$SkipDocker,
    [string]$DevEnvironmentName,
    [string]$TestEnvironmentName,
    [Parameter(Mandatory=$true)][string]$StrategyName,
    [Parameter(Mandatory=$true)][string]$CollectionName,
    [switch]$Watch
)

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

# Helper Functions
function Write-Status { param ([string]$Message, [string]$Color = "Yellow") Write-Host $Message -ForegroundColor $Color }
function Create-Directory { param ([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -ItemType Directory -Force | Out-Null; Write-Status "Created: $Path" "Green" } }

function Create-Shortcut {
    param ([string]$TargetPath, [string]$ShortcutName, [string]$Arguments = "", [string]$BrokerName)
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    $brokerFolder = Join-Path -Path $desktopPath -ChildPath $BrokerName
    Create-Directory -Path $brokerFolder
    $shortcutFile = Join-Path -Path $brokerFolder -ChildPath "$ShortcutName.lnk"
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutFile)
    $Shortcut.TargetPath = $TargetPath
    if ($TargetPath -match "terminal(64)?\.exe$" -and -not $Arguments.Contains("/portable")) { $Arguments = "$Arguments /portable".Trim() }
    if ($Arguments) { $Shortcut.Arguments = $Arguments }
    $Shortcut.WorkingDirectory = Split-Path -Path $TargetPath -Parent
    $Shortcut.Save()
    Write-Status "Created shortcut: $ShortcutName in $BrokerName folder" "Green"
}

function Install-MetaTrader {
    param ([string]$Version, [string]$BrokerName, [string]$CollectionName, [string]$RootPath, [string]$ExplicitPath = "")
    $exe = if ($Version -eq "MT4") { "terminal.exe" } else { "terminal64.exe" }
    $brokerPath = Join-Path -Path $RootPath -ChildPath $BrokerName
    $collectionPath = Join-Path -Path $brokerPath -ChildPath $CollectionName
    $platformPath = Join-Path -Path $collectionPath -ChildPath $Version
    Create-Directory -Path $platformPath
    $terminalPath = Join-Path -Path $platformPath -ChildPath $exe

    if (Test-Path $terminalPath) { 
        Write-Status "$Version for $BrokerName (collection: $CollectionName) already exists at $platformPath" "Yellow"
        return @{ Version = $Version; BrokerName = $BrokerName; CollectionName = $CollectionName; Path = $platformPath; Terminal = $terminalPath }
    }
    
    $sourcePath = if ($ExplicitPath -and (Test-Path $ExplicitPath)) { $ExplicitPath } else {
        $paths = @("${env:ProgramFiles(x86)}\*$BrokerName*", "${env:ProgramFiles}\*$BrokerName*") | 
                 ForEach-Object { Get-ChildItem -Path $_ -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
        $paths | Where-Object { Test-Path (Join-Path -Path $_ -ChildPath $exe) } | Select-Object -First 1
    }
    
    if (-not $sourcePath) { 
        Write-Status "$Version for $BrokerName not found. Please install it first." "Red"
        return $null
    }
    
    robocopy "$sourcePath" "$platformPath" /E /XJ /R:2 /W:1 /NFL /NDL
    if (Test-Path $terminalPath) {
        Set-Content -Path (Join-Path -Path $platformPath -ChildPath "origin.ini") -Value "[Common]`r`nPortable=1"
        Write-Status "$Version containerized for $BrokerName (collection: $CollectionName) at $platformPath" "Green"
        return @{ Version = $Version; BrokerName = $BrokerName; CollectionName = $CollectionName; Path = $platformPath; Terminal = $terminalPath }
    }
    Write-Status "Failed to containerize $Version for $BrokerName (collection: $CollectionName)" "Red"
    return $null
}

function Setup-Strategy-Folders {
    param ([array]$Installations, [string]$StrategyName)
    if (-not $Installations -or $Installations.Count -eq 0) { 
        Write-Status "No valid installations provided for strategy setup" "Red"
        return
    }
    
    foreach ($inst in $Installations) {
        if ($inst -and $inst.Path) {
            $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
            Create-Directory -Path $mqlDir
            $rootDir = $inst.Path
            $templatesDir = Join-Path -Path $rootDir -ChildPath "Templates"
            Create-Directory -Path $templatesDir
            
            $mqlSubFolders = @("Experts", "Indicators", "Scripts", "Libraries", "Images", "Files", "Include")
            foreach ($folder in $mqlSubFolders) {
                $baseFolder = Join-Path -Path $mqlDir -ChildPath $folder
                $strategySubFolder = Join-Path -Path $baseFolder -ChildPath $StrategyName
                Create-Directory -Path $strategySubFolder
                
                if ($inst.Version -eq "MT4") {
                    switch ($folder) {
                        "Experts" { Set-Content -Path "$strategySubFolder\SampleStrategy.mq4" -Value "// MT4 Expert`nvoid OnTick() { Print('MT4 $StrategyName Running'); }" }
                        "Indicators" { Set-Content -Path "$strategySubFolder\SampleIndicator.mq4" -Value "// MT4 Indicator`n#property indicator_chart_window" }
                        "Scripts" { Set-Content -Path "$strategySubFolder\SampleScript.mq4" -Value "// MT4 Script`nvoid OnStart() { Alert('MT4 $StrategyName Script'); }" }
                        "Libraries" { Set-Content -Path "$strategySubFolder\SampleLibrary.mq4" -Value "// MT4 Library`nvoid SampleFunction() { }" }
                        "Include" { Set-Content -Path "$strategySubFolder\SampleInclude.mqh" -Value "// MT4 Include`n#define SAMPLE_CONSTANT 1" }
                        "Files" { Set-Content -Path "$strategySubFolder\SampleFile.txt" -Value "Sample file for $StrategyName" }
                        "Images" { Set-Content -Path "$strategySubFolder\SampleImage.txt" -Value "Placeholder for image" }
                    }
                }
                if ($inst.Version -eq "MT5") {
                    switch ($folder) {
                        "Experts" { Set-Content -Path "$strategySubFolder\SampleStrategy.mq5" -Value "// MT5 Expert`nvoid OnTick() { Print('MT5 $StrategyName Running'); }" }
                        "Indicators" { Set-Content -Path "$strategySubFolder\SampleIndicator.mq5" -Value "// MT5 Indicator`n#property indicator_chart_window" }
                        "Scripts" { Set-Content -Path "$strategySubFolder\SampleScript.mq5" -Value "// MT5 Script`nvoid OnStart() { Alert('MT5 $StrategyName Script'); }" }
                        "Libraries" { Set-Content -Path "$strategySubFolder\SampleLibrary.mq5" -Value "// MT5 Library`nvoid SampleFunction() { }" }
                        "Include" { Set-Content -Path "$strategySubFolder\SampleInclude.mqh" -Value "// MT5 Include`n#define SAMPLE_CONSTANT 1" }
                        "Files" { Set-Content -Path "$strategySubFolder\SampleFile.txt" -Value "Sample file for $StrategyName" }
                        "Images" { Set-Content -Path "$strategySubFolder\SampleImage.txt" -Value "Placeholder for image" }
                    }
                }
            }
            
            $templatesSubFolder = Join-Path -Path $templatesDir -ChildPath $StrategyName
            Create-Directory -Path $templatesSubFolder
            if ($inst.Version -eq "MT4" -or $inst.Version -eq "MT5") {
                Set-Content -Path "$templatesSubFolder\SampleTemplate.tpl" -Value "<template><name>$StrategyName Sample</name></template>"
            }
        }
    }
    Write-Status "Strategy folders created for '$StrategyName' with sample files" "Green"
    Write-Status "Note: In Basic mode, restart MT4/MT5 and compile files in MetaEditor to see Experts/Indicators/Scripts in Navigator. Templates are under Chart > Templates." "Yellow"
}

function Build-MQLFiles {
    param ([array]$Installations, [string]$StrategyName)
    
    Write-Status "Building MQL files..." "Yellow"
    
    foreach ($inst in $Installations) {
        if ($inst -and $inst.Path) {
            $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
            if (Test-Path $mqlDir) {
                Write-Status "Compiling MQL files for $inst.Version in $mqlDir\$StrategyName" "Yellow"
                
                $tempSrcDir = Join-Path -Path $PSScriptRoot -ChildPath "temp_src"
                $tempBuildDir = Join-Path -Path $PSScriptRoot -ChildPath "temp_build"
                Remove-Item -Path $tempSrcDir, $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue
                Create-Directory -Path $tempSrcDir
                Create-Directory -Path $tempBuildDir
                
                $subFolders = @("Experts", "Indicators", "Scripts")
                foreach ($folder in $subFolders) {
                    $sourceDir = Join-Path -Path $mqlDir -ChildPath "$folder\$StrategyName"
                    if (Test-Path $sourceDir) {
                        Copy-Item -Path "$sourceDir\*.mq*" -Destination $tempSrcDir -Force
                    }
                }
                $includeDir = Join-Path -Path $mqlDir -ChildPath "Include\$StrategyName"
                if (Test-Path $includeDir) {
                    Copy-Item -Path "$includeDir\*.mqh" -Destination $tempSrcDir -Force
                }
                
                $buildCommand = if ($inst.Version -eq "MT4") { "build_mt4" } else { "build_mt5" }
                $buildSubDir = if ($inst.Version -eq "MT4") { "mt4" } else { "mt5" }
                try {
                    Push-Location -Path $PSScriptRoot
                    docker-compose up -d
                    docker-compose exec -T mt_builder $buildCommand
                    
                    $compiledDir = Join-Path -Path $tempBuildDir -ChildPath $buildSubDir
                    if (Test-Path $compiledDir) {
                        foreach ($folder in $subFolders) {
                            $targetDir = Join-Path -Path $mqlDir -ChildPath "$folder\$StrategyName"
                            Create-Directory -Path $targetDir
                            Copy-Item -Path "$compiledDir\*.ex*" -Destination $targetDir -Force
                        }
                        $includeTargetDir = Join-Path -Path $mqlDir -ChildPath "Include\$StrategyName"
                        Create-Directory -Path $includeTargetDir
                        Copy-Item -Path "$compiledDir\include\*.mqh" -Destination $includeTargetDir -Force -ErrorAction SilentlyContinue
                    } else {
                        Write-Status "No compiled files found in $compiledDir" "Red"
                    }
                    
                    docker-compose down
                    Pop-Location
                    Write-Status "Successfully compiled MQL files for $inst.Version in $StrategyName" "Green"
                } catch {
                    Write-Status "Error compiling MQL files: $_" "Red"
                    Write-Status "Check Docker logs and build script output for details." "Yellow"
                    Pop-Location
                    docker-compose down
                    return
                } finally {
                    Remove-Item -Path $tempSrcDir, $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            } else {
                Write-Status "MQL directory not found at $mqlDir" "Red"
            }
        }
    }
}

function Setup-Docker {
    param ([array]$Installations, [string]$StrategyName)
    
    Write-Status "Docker setup initiated for advanced mode" "Yellow"
    
    try {
        $dockerVersion = docker --version
        Write-Status "Docker found: $dockerVersion" "Green"
    } catch {
        Write-Status "Docker is not installed. Please install Docker Desktop and restart this script." "Red"
        Write-Status "Download Docker: https://www.docker.com/products/docker-desktop/" "Yellow"
        return
    }
    try {
        $composeVersion = docker-compose --version
        Write-Status "Docker Compose found: $composeVersion" "Green"
    } catch {
        Write-Status "Docker Compose is not installed. Please install it and restart this script." "Red"
        Write-Status "See: https://docs.docker.com/compose/install/" "Yellow"
        return
    }
    
    $composeFile = Join-Path -Path $PSScriptRoot -ChildPath "docker-compose.yml"
    $dockerFile = Join-Path -Path $PSScriptRoot -ChildPath "Dockerfile"
    $buildMt4Script = Join-Path -Path $PSScriptRoot -ChildPath "scripts/build_mt4.sh"
    $buildMt5Script = Join-Path -Path $PSScriptRoot -ChildPath "scripts/build_mt5.sh"
    if (-not (Test-Path $composeFile) -or -not (Test-Path $dockerFile) -or -not (Test-Path $buildMt4Script) -or -not (Test-Path $buildMt5Script)) {
        Write-Status "Missing required files (docker-compose.yml, Dockerfile, or build scripts) in $PSScriptRoot" "Red"
        Write-Status "Please ensure all files are present." "Yellow"
        return
    }
    
    Write-Status "Building Docker image for mt_builder..." "Yellow"
    try {
        Push-Location -Path $PSScriptRoot
        docker-compose build
        Pop-Location
    } catch {
        Write-Status "Failed to build Docker image: $_" "Red"
        Pop-Location
        return
    }
    
    Build-MQLFiles -Installations $Installations -StrategyName $StrategyName
    
    Write-Status "Docker-based compilation complete. Restart MT4/MT5 to see compiled files in the Navigator." "Green"
}


function Sync-CompiledFiles {
    param (
        [string]$DevPath = "C:\Trading\MTFramework\Dev\test",
        [string]$MT4Path = "C:\Trading\MTFramework\MT4",
        [string]$MT5Path = "C:\Trading\MTFramework\MT5"
    )

    Write-Status "Syncing compiled files to $DevPath..." "Yellow"

    if (Test-Path $MT4Path) {
        Write-Status "Syncing MT4 files..." "Yellow"
        $mt4BuildDir = Join-Path -Path $DevPath -ChildPath "build\mt4"
        Create-Directory -Path $mt4BuildDir
        $foundFiles = $false

        Get-ChildItem -Path $MT4Path -Directory | ForEach-Object {
            $brokerDir = $_.FullName
            foreach ($folder in @("Experts", "Indicators", "Scripts")) {
                $sourceDir = Join-Path -Path $brokerDir -ChildPath "MQL4\$folder"
                if (Test-Path $sourceDir) {
                    Get-ChildItem -Path $sourceDir -Recurse -File -Filter "*.ex4" | ForEach-Object {
                        $fileName = $_.Name
                        Write-Host "Copying: $fileName from $($_.Directory.Name)"
                        try {
                            Copy-Item -Path $_.FullName -Destination $mt4BuildDir -Force
                            Write-Host " - Successfully copied $fileName" -ForegroundColor Green
                            $foundFiles = $true
                        } catch {
                            Write-Host " - Failed to copy $fileName : $_" -ForegroundColor Red
                        }
                    }
                }
            }
        }

        if (-not $foundFiles) {
            Write-Status "No compiled MT4 files found in Experts, Indicators, or Scripts." "Yellow"
        }
    } else {
        Write-Status "MT4 path not found: $MT4Path" "Red"
    }

    if (Test-Path $MT5Path) {
        Write-Status "Syncing MT5 files..." "Yellow"
        $mt5BuildDir = Join-Path -Path $DevPath -ChildPath "build\mt5"
        Create-Directory -Path $mt5BuildDir
        $foundFiles = $false

        Get-ChildItem -Path $MT5Path -Directory | ForEach-Object {
            $brokerDir = $_.FullName
            foreach ($folder in @("Experts", "Indicators", "Scripts")) {
                $sourceDir = Join-Path -Path $brokerDir -ChildPath "MQL5\$folder"
                if (Test-Path $sourceDir) {
                    Get-ChildItem -Path $sourceDir -Recurse -File -Filter "*.ex5" | ForEach-Object {
                        $fileName = $_.Name
                        Write-Host "Copying: $fileName from $($_.Directory.Name)"
                        try {
                            Copy-Item -Path $_.FullName -Destination $mt5BuildDir -Force
                            Write-Host " - Successfully copied $fileName" -ForegroundColor Green
                            $foundFiles = $true
                        } catch {
                            Write-Host " - Failed to copy $fileName : $_" -ForegroundColor Red
                        }
                    }
                }
            }
        }

        if (-not $foundFiles) {
            Write-Status "No compiled MT5 files found in Experts, Indicators, or Scripts." "Yellow"
        }
    } else {
        Write-Status "MT5 path not found: $MT5Path" "Red"
    }

    $mt4FilesExist = Test-Path "$mt4BuildDir\*.ex4"
    $mt5FilesExist = Test-Path "$mt5BuildDir\*.ex5"
    if ($mt4FilesExist) {
        Write-Status "MT4 compiled files were successfully synced to $mt4BuildDir." "Green"
    }
    if ($mt5FilesExist) {
        Write-Status "MT5 compiled files were successfully synced to $mt5BuildDir." "Green"
    }
    if (-not $mt4FilesExist -and -not $mt5FilesExist) {
        Write-Status "No compiled files were synced. Ensure:" "Yellow"
        Write-Host " 1. Strategies are compiled in MetaTrader (Basic mode) or via Docker (Advanced mode)."
        Write-Host " 2. Compiled files are in MT4/MT5 Experts, Indicators, or Scripts directories."
        Write-Host " 3. Paths are correct: $MT4Path and $MT5Path."
    }
}

function Start-CompiledFileWatcher {
    param (
        [array]$Installations,
        [string]$DevPath = "C:\Trading\MTFramework\Dev\test"
    )

    Write-Status "Starting file watcher for compiled files..." "Yellow"

    foreach ($inst in $Installations) {
        if ($inst -and $inst.Path) {
            $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
            $version = $inst.Version
            if (Test-Path $mqlDir) {
                Write-Status "Monitoring $version compiled files in $mqlDir" "Yellow"
                
                $watcher = New-Object System.IO.FileSystemWatcher
                $watcher.Path = $mqlDir
                $watcher.Filter = if ($version -eq "MT4") { "*.ex4" } else { "*.ex5" }
                $watcher.IncludeSubdirectories = $true
                $watcher.EnableRaisingEvents = $true

                $onChange = Register-ObjectEvent $watcher "Changed" -Action {
                    param ($source, $eventArgs)
                    Write-Host "Detected change in $($eventArgs.FullPath)" -ForegroundColor Cyan
                    Sync-CompiledFiles -DevPath $using:DevPath -MT4Path $using:MT4Path -MT5Path $using:MT5Path
                }

                Write-Status "Watcher started for $version. Press Ctrl+C to stop." "Green"
            } else {
                Write-Status "MQL directory not found for $version at $mqlDir" "Red"
            }
        }
    }

    Write-Status "File watchers active. Monitoring for compiled file changes..." "Green"
    while ($true) { Start-Sleep -Seconds 10 }
}

# Main Setup
Write-Status "Starting MT Trading Framework Setup" "Cyan"
Create-Directory -Path $BasePath

$Config = @{
    MT4RootPath = Join-Path -Path $BasePath -ChildPath "MT4"
    MT5RootPath = Join-Path -Path $BasePath -ChildPath "MT5"
    DevPath = Join-Path -Path $BasePath -ChildPath "Dev"
    TestPath = Join-Path -Path $BasePath -ChildPath "Test"
}

$installations = @()

if (-not $SkipMT4) {
    $mt4Inst = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -CollectionName $CollectionName -RootPath $Config.MT4RootPath -ExplicitPath $MT4Path
    if ($mt4Inst) {
        $installations += $mt4Inst
        Create-Shortcut -TargetPath $mt4Inst.Terminal -ShortcutName "MT4 - $MT4BrokerName [$CollectionName-$StrategyName]Strategy" -BrokerName $MT4BrokerName
    }
}
if (-not $SkipMT5) {
    $mt5Inst = Install-MetaTrader -Version "MT5" -BrokerName $MT5BrokerName -CollectionName $CollectionName -RootPath $Config.MT5RootPath -ExplicitPath $MT5Path
    if ($mt5Inst) {
        $installations += $mt5Inst
        Create-Shortcut -TargetPath $mt5Inst.Terminal -ShortcutName "MT5 - $MT5BrokerName [$CollectionName-$StrategyName]Strategy" -BrokerName $MT5BrokerName
    }
}

if ($installations.Count -eq 0) {
    Write-Status "No MetaTrader installations succeeded for collection '$CollectionName'. Setup aborted." "Red"
    exit 1
}

Setup-Strategy-Folders -Installations $installations -StrategyName $StrategyName

if (-not $SkipDocker) {
    Setup-Docker -Installations $installations -StrategyName $StrategyName
    Sync-CompiledFiles -DevPath $Config.DevPath -MT4Path $Config.MT4RootPath -MT5Path $Config.MT5RootPath
    if ($DevEnvironmentName) {
        Write-Status "Setting up dev environment '$DevEnvironmentName' with Docker (placeholder)" "Yellow"
    }
    if ($TestEnvironmentName) {
        Write-Status "Setting up test environment '$TestEnvironmentName' with Docker (placeholder)" "Yellow"
    }
    Write-Status "Advanced mode selected: Docker setup, compilation, and sync completed" "Green"
} else {
    Write-Status "Basic mode: Collection of $CollectionName strategies setup complete" "Yellow"
    Sync-CompiledFiles -DevPath $Config.DevPath -MT4Path $Config.MT4RootPath -MT5Path $Config.MT5RootPath
}

if ($Watch) {
    Start-CompiledFileWatcher -Installations $installations -DevPath $Config.DevPath
} else {
    Write-Status "Setup complete at $BasePath. Use -Watch to monitor compiled files." "Green"
}