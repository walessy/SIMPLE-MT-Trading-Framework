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
    [Parameter(Mandatory=$true)][string]$CollectionName
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
    $platformPath = Join-Path -Path $collectionPath -ChildPath $Version  # e.g., MT4 or MT5 folder
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
            $subFolders = @("Experts", "Indicators", "Scripts", "Libraries", "Images", "Files", "Include")
            foreach ($folder in $subFolders) {
                $baseFolder = Join-Path -Path $mqlDir -ChildPath $folder
                $strategySubFolder = Join-Path -Path $baseFolder -ChildPath $StrategyName
                Create-Directory -Path $strategySubFolder
                if ($inst.Version -eq "MT4") {
                    if ($folder -eq "Experts") { Set-Content -Path "$strategySubFolder\SampleStrategy.mq4" -Value "// MT4 Expert`nvoid OnTick() { Print('MT4 Running'); }" }
                    if ($folder -eq "Indicators") { Set-Content -Path "$strategySubFolder\SampleIndicator.mq4" -Value "// MT4 Indicator`n#property indicator_chart_window" }
                    if ($folder -eq "Scripts") { Set-Content -Path "$strategySubFolder\SampleScript.mq4" -Value "// MT4 Script`nvoid OnStart() { Alert('MT4 Script'); }" }
                }
                if ($inst.Version -eq "MT5") {
                    if ($folder -eq "Experts") { Set-Content -Path "$strategySubFolder\SampleStrategy.mq5" -Value "// MT5 Expert`nvoid OnTick() { Print('MT5 Running'); }" }
                    if ($folder -eq "Indicators") { Set-Content -Path "$strategySubFolder\SampleIndicator.mq5" -Value "// MT5 Indicator`n#property indicator_chart_window" }
                    if ($folder -eq "Scripts") { Set-Content -Path "$strategySubFolder\SampleScript.mq5" -Value "// MT5 Script`nvoid OnStart() { Alert('MT5 Script'); }" }
                }
            }
        }
    }
    Write-Status "Strategy folders created for '$StrategyName' with sample files" "Green"
}

function Setup-Docker {
    # Placeholder for Docker setup logic
    Write-Status "Docker setup initiated (not fully implemented yet)" "Yellow"
    # Future implementation: Docker container creation, linking MT installations, etc.
    Write-Status "Advanced mode with Docker will be fully implemented in a future update" "Yellow"
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

if (-not $SkipDocker) {
    Setup-Docker
    if ($DevEnvironmentName) {
        Write-Status "Setting up dev environment '$DevEnvironmentName' with Docker (placeholder)" "Yellow"
        # Future: Setup-Environment -Path $Config.DevPath -Name $DevEnvironmentName -Installations $installations -Type "Dev"
    }
    if ($TestEnvironmentName) {
        Write-Status "Setting up test environment '$TestEnvironmentName' with Docker (placeholder)" "Yellow"
        # Future: Setup-Environment -Path $Config.TestPath -Name $TestEnvironmentName -Installations $installations -Type "Test"
    }
    Write-Status "Advanced mode selected: Docker setup initiated (partial implementation)" "Yellow"
} else {
    Setup-Strategy-Folders -Installations $installations -StrategyName $StrategyName
    Write-Status "Basic mode: Collection of $CollectionName strategies setup complete" "Yellow"
}

Write-Status "Setup complete at $BasePath" "Green"