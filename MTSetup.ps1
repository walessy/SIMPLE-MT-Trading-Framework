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
    [string]$StrategyName,
    [string]$CollectionName
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
    param ([string]$Version, [string]$BrokerName, [string]$CollectionName, [string]$RootPath, [string]$EnvironmentName, [string]$ExplicitPath = "")
    $exe = if ($Version -eq "MT4") { "terminal.exe" } else { "terminal64.exe" }
    $brokerPath = Join-Path -Path $RootPath -ChildPath $BrokerName
    $collectionPath = Join-Path -Path $brokerPath -ChildPath $CollectionName
    $envPath = Join-Path -Path $collectionPath -ChildPath $EnvironmentName
    $platformPath = Join-Path -Path $envPath -ChildPath $Version
    Create-Directory -Path $platformPath
    $terminalPath = Join-Path -Path $platformPath -ChildPath $exe

    if (Test-Path $terminalPath) { 
        Write-Status "$Version for $BrokerName (collection: $CollectionName, env: $EnvironmentName) already exists at $platformPath" "Yellow"
        return @{ Version = $Version; BrokerName = $BrokerName; CollectionName = $CollectionName; EnvironmentName = $EnvironmentName; Path = $platformPath; Terminal = $terminalPath }
    }
    
    $sourcePath = if ($ExplicitPath -and (Test-Path $ExplicitPath)) { $ExplicitPath } else {
        $paths = @("${env:ProgramFiles(x86)}\*$BrokerName*", "${env:ProgramFiles}\*$BrokerName*") | 
                 ForEach-Object { Get-ChildItem -Path $_ -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
        $paths | Where-Object { Test-Path (Join-Path -Path $_ -ChildPath $exe) } | Select-Object -First 1
    }
    
    if (-not $sourcePath) { 
        Write-Status "$Version for $BrokerName not found. Please install it first or provide an explicit path." "Red"
        return $null
    }
    
    robocopy "$sourcePath" "$platformPath" /E /XJ /R:2 /W:1 /NFL /NDL
    if (Test-Path $terminalPath) {
        Set-Content -Path (Join-Path -Path $platformPath -ChildPath "origin.ini") -Value "[Common]`r`nPortable=1"
        Write-Status "$Version containerized for $BrokerName (collection: $CollectionName, env: $EnvironmentName) at $platformPath" "Green"
        return @{ Version = $Version; BrokerName = $BrokerName; CollectionName = $CollectionName; EnvironmentName = $EnvironmentName; Path = $platformPath; Terminal = $terminalPath }
    }
    Write-Status "Failed to containerize $Version for $BrokerName (collection: $CollectionName, env: $EnvironmentName)" "Red"
    return $null
}

function Setup-Strategy-Folders {
    param ([array]$Installations, [string]$StrategyName)
    if (-not $Installations -or $Installations.Count -eq 0) { 
        Write-Status "No valid installations provided for strategy setup" "Yellow"
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
        [string]$DevPath,
        [string]$TestPath,
        [string]$DeployPath,
        [string]$PackagePath,
        [string]$MT4Path,
        [string]$MT5Path,
        [string]$CollectionName,
        [string]$StrategyName
    )

    Write-Status "Syncing compiled files to environments..." "Yellow"
    $foundFiles = $false

    if (Test-Path $MT4Path) {
        Write-Status "Syncing MT4 files from $MT4Path..." "Yellow"
        $mt4DevBuildDir = Join-Path -Path $DevPath -ChildPath "MT4"
        $mt4TestBuildDir = Join-Path -Path $TestPath -ChildPath "MT4"
        $mt4DeployDir = Join-Path -Path $DeployPath -ChildPath "MT4"
        $mt4PackageDir = Join-Path -Path $PackagePath -ChildPath "MT4\$CollectionName\$StrategyName"

        Create-Directory -Path $mt4DevBuildDir
        Create-Directory -Path $mt4TestBuildDir
        Create-Directory -Path $mt4DeployDir
        Create-Directory -Path $mt4PackageDir

        Get-ChildItem -Path $MT4Path -Directory | ForEach-Object {
            $brokerDir = $_.FullName
            $mql4Dir = Join-Path -Path $brokerDir -ChildPath "MQL4"
            if (Test-Path $mql4Dir) {
                Write-Status "Checking MQL4 directory: $mql4Dir" "Cyan"
                foreach ($folder in @("Experts", "Indicators", "Scripts")) {
                    $sourceDir = Join-Path -Path $mql4Dir -ChildPath "$folder\$StrategyName"
                    Write-Status "Looking for compiled files in $sourceDir..." "Cyan"
                    if (Test-Path $sourceDir) {
                        $compiledFiles = Get-ChildItem -Path $sourceDir -File -Filter "*.ex4" -ErrorAction SilentlyContinue
                        if ($compiledFiles) {
                            foreach ($file in $compiledFiles) {
                                Write-Status "Copying MT4 $folder file: $($file.Name) from $sourceDir" "Green"
                                $targetDevDir = Join-Path -Path $mt4DevBuildDir -ChildPath "MQL4\$folder\$StrategyName"
                                $targetTestDir = Join-Path -Path $mt4TestBuildDir -ChildPath "MQL4\$folder\$StrategyName"
                                $targetDeployDir = Join-Path -Path $mt4DeployDir -ChildPath "MQL4\$folder\$StrategyName"
                                Create-Directory -Path $targetDevDir
                                Create-Directory -Path $targetTestDir
                                Create-Directory -Path $targetDeployDir
                                Copy-Item -Path $file.FullName -Destination $targetDevDir -Force
                                Copy-Item -Path $file.FullName -Destination $targetTestDir -Force
                                Copy-Item -Path $file.FullName -Destination $targetDeployDir -Force
                                Copy-Item -Path $file.FullName -Destination (Join-Path -Path $mt4PackageDir -ChildPath "$folder") -Force
                                $foundFiles = $true
                            }
                        } else {
                            Write-Status "No compiled .ex4 files found in $sourceDir" "Yellow"
                        }
                    } else {
                        Write-Status "Directory $sourceDir does not exist" "Red"
                    }
                }

                $includeDir = Join-Path -Path $mql4Dir -ChildPath "Include\$StrategyName"
                if (Test-Path $includeDir) {
                    $includeFiles = Get-ChildItem -Path $includeDir -File -Filter "*.mqh" -ErrorAction SilentlyContinue
                    if ($includeFiles) {
                        $includeDevDir = Join-Path -Path $mt4DevBuildDir -ChildPath "MQL4\Include\$StrategyName"
                        $includeTestDir = Join-Path -Path $mt4TestBuildDir -ChildPath "MQL4\Include\$StrategyName"
                        $includeDeployDir = Join-Path -Path $mt4DeployDir -ChildPath "MQL4\Include\$StrategyName"
                        $includePackageDir = Join-Path -Path $mt4PackageDir -ChildPath "include"
                        Create-Directory -Path $includeDevDir
                        Create-Directory -Path $includeTestDir
                        Create-Directory -Path $includeDeployDir
                        Create-Directory -Path $includePackageDir
                        foreach ($file in $includeFiles) {
                            Write-Status "Copying MT4 dependency: $($file.Name)" "Cyan"
                            Copy-Item -Path $file.FullName -Destination $includeDevDir -Force
                            Copy-Item -Path $file.FullName -Destination $includeTestDir -Force
                            Copy-Item -Path $file.FullName -Destination $includeDeployDir -Force
                            Copy-Item -Path $file.FullName -Destination $includePackageDir -Force
                        }
                    }
                }

                $resources = @("Files", "Images")
                foreach ($folder in $resources) {
                    $resourceDir = Join-Path -Path $mql4Dir -ChildPath "$folder\$StrategyName"
                    if (Test-Path $resourceDir) {
                        $resourceFiles = Get-ChildItem -Path $resourceDir -File -ErrorAction SilentlyContinue
                        if ($resourceFiles) {
                            $resourcePackageDir = Join-Path -Path $mt4PackageDir -ChildPath "resources\$folder"
                            Create-Directory -Path $resourcePackageDir
                            foreach ($file in $resourceFiles) {
                                Write-Status "Copying MT4 resource: $($file.Name)" "Cyan"
                                Copy-Item -Path $file.FullName -Destination $resourcePackageDir -Force
                            }
                        }
                    }
                }
            } else {
                Write-Status "MQL4 directory not found at $mql4Dir" "Red"
            }
        }

        if ($foundFiles) {
            Write-Status "MT4 compiled files, dependencies, and resources synced to Dev, Test, Deploy, and Package environments." "Green"
        } else {
            Write-Status "No compiled MT4 files found in Experts, Indicators, or Scripts for $StrategyName." "Yellow"
        }
    } else {
        Write-Status "MT4 path not found: $MT4Path" "Red"
    }

    if (Test-Path $MT5Path) {
        Write-Status "Syncing MT5 files from $MT5Path..." "Yellow"
        $mt5DevBuildDir = Join-Path -Path $DevPath -ChildPath "MT5"
        $mt5TestBuildDir = Join-Path -Path $TestPath -ChildPath "MT5"
        $mt5DeployDir = Join-Path -Path $DeployPath -ChildPath "MT5"
        $mt5PackageDir = Join-Path -Path $PackagePath -ChildPath "MT5\$CollectionName\$StrategyName"

        Create-Directory -Path $mt5DevBuildDir
        Create-Directory -Path $mt5TestBuildDir
        Create-Directory -Path $mt5DeployDir
        Create-Directory -Path $mt5PackageDir

        Get-ChildItem -Path $MT5Path -Directory | ForEach-Object {
            $brokerDir = $_.FullName
            $mql5Dir = Join-Path -Path $brokerDir -ChildPath "MQL5"
            if (Test-Path $mql5Dir) {
                Write-Status "Checking MQL5 directory: $mql5Dir" "Cyan"
                foreach ($folder in @("Experts", "Indicators", "Scripts")) {
                    $sourceDir = Join-Path -Path $mql5Dir -ChildPath "$folder\$StrategyName"
                    Write-Status "Looking for compiled files in $sourceDir..." "Cyan"
                    if (Test-Path $sourceDir) {
                        $compiledFiles = Get-ChildItem -Path $sourceDir -File -Filter "*.ex5" -ErrorAction SilentlyContinue
                        if ($compiledFiles) {
                            foreach ($file in $compiledFiles) {
                                Write-Status "Copying MT5 $folder file: $($file.Name) from $sourceDir" "Green"
                                $targetDevDir = Join-Path -Path $mt5DevBuildDir -ChildPath "MQL5\$folder\$StrategyName"
                                $targetTestDir = Join-Path -Path $mt5TestBuildDir -ChildPath "MQL5\$folder\$StrategyName"
                                $targetDeployDir = Join-Path -Path $mt5DeployDir -ChildPath "MQL5\$folder\$StrategyName"
                                Create-Directory -Path $targetDevDir
                                Create-Directory -Path $targetTestDir
                                Create-Directory -Path $targetDeployDir
                                Copy-Item -Path $file.FullName -Destination $targetDevDir -Force
                                Copy-Item -Path $file.FullName -Destination $targetTestDir -Force
                                Copy-Item -Path $file.FullName -Destination $targetDeployDir -Force
                                Copy-Item -Path $file.FullName -Destination (Join-Path -Path $mt5PackageDir -ChildPath "$folder") -Force
                                $foundFiles = $true
                            }
                        } else {
                            Write-Status "No compiled .ex5 files found in $sourceDir" "Yellow"
                        }
                    } else {
                        Write-Status "Directory $sourceDir does not exist" "Red"
                    }
                }

                $includeDir = Join-Path -Path $mql5Dir -ChildPath "Include\$StrategyName"
                if (Test-Path $includeDir) {
                    $includeFiles = Get-ChildItem -Path $includeDir -File -Filter "*.mqh" -ErrorAction SilentlyContinue
                    if ($includeFiles) {
                        $includeDevDir = Join-Path -Path $mt5DevBuildDir -ChildPath "MQL5\Include\$StrategyName"
                        $includeTestDir = Join-Path -Path $mt5TestBuildDir -ChildPath "MQL5\Include\$StrategyName"
                        $includeDeployDir = Join-Path -Path $mt5DeployDir -ChildPath "MQL5\Include\$StrategyName"
                        $includePackageDir = Join-Path -Path $mt5PackageDir -ChildPath "include"
                        Create-Directory -Path $includeDevDir
                        Create-Directory -Path $includeTestDir
                        Create-Directory -Path $includeDeployDir
                        Create-Directory -Path $includePackageDir
                        foreach ($file in $includeFiles) {
                            Write-Status "Copying MT5 dependency: $($file.Name)" "Cyan"
                            Copy-Item -Path $file.FullName -Destination $includeDevDir -Force
                            Copy-Item -Path $file.FullName -Destination $includeTestDir -Force
                            Copy-Item -Path $file.FullName -Destination $includeDeployDir -Force
                            Copy-Item -Path $file.FullName -Destination $includePackageDir -Force
                        }
                    }
                }

                $resources = @("Files", "Images")
                foreach ($folder in $resources) {
                    $resourceDir = Join-Path -Path $mql5Dir -ChildPath "$folder\$StrategyName"
                    if (Test-Path $resourceDir) {
                        $resourceFiles = Get-ChildItem -Path $resourceDir -File -ErrorAction SilentlyContinue
                        if ($resourceFiles) {
                            $resourcePackageDir = Join-Path -Path $mt5PackageDir -ChildPath "resources\$folder"
                            Create-Directory -Path $resourcePackageDir
                            foreach ($file in $resourceFiles) {
                                Write-Status "Copying MT5 resource: $($file.Name)" "Cyan"
                                Copy-Item -Path $file.FullName -Destination $resourcePackageDir -Force
                            }
                        }
                    }
                }
            } else {
                Write-Status "MQL5 directory not found at $mql5Dir" "Red"
            }
        }

        if ($foundFiles) {
            Write-Status "MT5 compiled files, dependencies, and resources synced to Dev, Test, Deploy, and Package environments." "Green"
        } else {
            Write-Status "No compiled MT5 files found in Experts, Indicators, or Scripts for $StrategyName." "Yellow"
        }
    } else {
        Write-Status "MT5 path not found: $MT5Path" "Red"
    }

    if (-not $foundFiles) {
        Write-Status "No compiled files were synced. Ensure strategies are compiled in MetaTrader or via Docker." "Yellow"
    }
}

function Update-ConfigFile {
    param (
        [array]$Installations,
        [string]$BasePath,
        [string]$StrategyName,
        [string]$CollectionName,
        [switch]$SkipDocker
    )
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
    $config = if (Test-Path $configFile) { 
        $jsonContent = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($jsonContent -is [array]) { $jsonContent } else { @($jsonContent) }
    } else { 
        @() 
    }

    $newInstance = [PSCustomObject]@{
        BasePath = $BasePath
        StrategyName = $StrategyName
        CollectionName = $CollectionName
        SkipDocker = [bool]$SkipDocker
        Installations = $Installations
        Config = @{
            MT4RootPath = Join-Path -Path $BasePath -ChildPath "MT4"
            MT5RootPath = Join-Path -Path $BasePath -ChildPath "MT5"
            DevPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Dev"
            TestPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Test"
            DeployPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Deploy"
            PackagePath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Package"
        }
    }

    $config = @($config | Where-Object { -not ($_.BasePath -eq $BasePath -and $_.StrategyName -eq $StrategyName -and $_.CollectionName -eq $CollectionName) })
    $config += $newInstance

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile
    Write-Status "Updated config file with new setup: $configFile" "Green"
}

function Start-Setup {
    param (
        [string]$BasePath,
        [switch]$SkipMT4,
        [switch]$SkipMT5,
        [string]$MT4BrokerName,
        [string]$MT5BrokerName,
        [string]$MT4Path,
        [string]$MT5Path,
        [switch]$SkipDocker,
        [string]$StrategyName,
        [string]$CollectionName
    )

    Write-Status "Starting MT Trading Framework Setup" "Cyan"
    Create-Directory -Path $BasePath

    $Config = @{
        MT4RootPath = Join-Path -Path $BasePath -ChildPath "MT4"
        MT5RootPath = Join-Path -Path $BasePath -ChildPath "MT5"
        DevPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Dev"
        TestPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Test"
        DeployPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Deploy"
        PackagePath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName\Package"
    }

    $Installations = @()
    if (-not $SkipMT4) {
        # Main MT4 environment under coll1
        $mt4Inst = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -CollectionName $CollectionName -RootPath $Config.MT4RootPath -EnvironmentName "MT4" -ExplicitPath $MT4Path
        if ($mt4Inst) { 
            $Installations += $mt4Inst
            Create-Shortcut -TargetPath $mt4Inst.Terminal -ShortcutName "MT4 - $MT4BrokerName [$CollectionName-$StrategyName] Main" -BrokerName $MT4BrokerName 
        }

        # Deploy MT4 environment
        $mt4DeployInst = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -CollectionName $CollectionName -RootPath $Config.MT4RootPath -EnvironmentName "Deploy" -ExplicitPath $MT4Path
        if ($mt4DeployInst) { 
            $Installations += $mt4DeployInst
            Create-Shortcut -TargetPath $mt4DeployInst.Terminal -ShortcutName "MT4 - $MT4BrokerName [$CollectionName-$StrategyName] Deploy" -BrokerName $MT4BrokerName 
        }

        # Test MT4 environment
        $mt4TestInst = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -CollectionName $CollectionName -RootPath $Config.MT4RootPath -EnvironmentName "Test" -ExplicitPath $MT4Path
        if ($mt4TestInst) { 
            $Installations += $mt4TestInst
            Create-Shortcut -TargetPath $mt4TestInst.Terminal -ShortcutName "MT4 - $MT4BrokerName [$CollectionName-$StrategyName] Test" -BrokerName $MT4BrokerName 
        }
    }
    if (-not $SkipMT5) {
        $mt5Inst = Install-MetaTrader -Version "MT5" -BrokerName $MT5BrokerName -CollectionName $CollectionName -RootPath $Config.MT5RootPath -EnvironmentName "MT5" -ExplicitPath $MT5Path
        if ($mt5Inst) { 
            $Installations += $mt5Inst
            Create-Shortcut -TargetPath $mt5Inst.Terminal -ShortcutName "MT5 - $MT5BrokerName [$CollectionName-$StrategyName] Main" -BrokerName $MT5BrokerName 
        }
    }

    Setup-Strategy-Folders -Installations $Installations -StrategyName $StrategyName
    if (-not $SkipDocker) { Setup-Docker -Installations $Installations -StrategyName $StrategyName }

    if ($Installations.Count -gt 0) {
        Update-ConfigFile -Installations $Installations -BasePath $BasePath -StrategyName $StrategyName -CollectionName $CollectionName -SkipDocker:$SkipDocker
    }

    Write-Status "Setup complete at $BasePath. Run BuildManager.ps1 to launch the build manager GUI." "Green"
}

# Execute setup only if parameters are provided
if ($PSBoundParameters.Count -gt 0) {
    Start-Setup -BasePath $BasePath -SkipMT4:$SkipMT4 -SkipMT5:$SkipMT5 -MT4BrokerName $MT4BrokerName -MT5BrokerName $MT5BrokerName `
                -MT4Path $MT4Path -MT5Path $MT5Path -SkipDocker:$SkipDocker -StrategyName $StrategyName -CollectionName $CollectionName
}