# Sync-MTEnvironment.ps1
# Synchronizes files between MetaTrader and the development environment
# Created: April 3, 2025

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DevEnvironmentName,
    [ValidateSet("MT4", "MT5", "Both")]
    [string]$Platform = "Both",
    [ValidateSet("TwoWay", "DevToMT", "MTToDev")]
    [string]$SyncDirection = "TwoWay",
    [switch]$WatchMode,
    [switch]$Force,
    [switch]$Help
)

# Display help if requested
if ($Help) {
    Write-Host "MT Trading Framework - Environment Synchronization Script" -ForegroundColor Cyan
    Write-Host "Usage: .\Sync-MTEnvironment.ps1 -DevEnvironmentName <name> [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Required Parameters:" -ForegroundColor Yellow
    Write-Host "  -DevEnvironmentName     Name of the development environment to sync" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Platform <MT4|MT5|Both>   Platform to sync (default: Both)" -ForegroundColor White
    Write-Host "  -SyncDirection <TwoWay|DevToMT|MTToDev>  Direction of sync (default: TwoWay)" -ForegroundColor White
    Write-Host "  -WatchMode              Continuously monitor and sync files" -ForegroundColor White
    Write-Host "  -Force                  Overwrite files without prompting" -ForegroundColor White
    Write-Host "  -Help                   Display this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\Sync-MTEnvironment.ps1 -DevEnvironmentName MyStrategy" -ForegroundColor White
    Write-Host "  .\Sync-MTEnvironment.ps1 -DevEnvironmentName MyStrategy -Platform MT4 -SyncDirection DevToMT" -ForegroundColor White
    Write-Host "  .\Sync-MTEnvironment.ps1 -DevEnvironmentName MyStrategy -WatchMode" -ForegroundColor White
    
    exit 0
}

# Configuration
$BasePath = "C:\Trading\MTFramework"
$DevPath = Join-Path -Path $BasePath -ChildPath "Dev\$DevEnvironmentName"
$MT4Path = Join-Path -Path $BasePath -ChildPath "MT4\AfterPrime"
$MT5Path = Join-Path -Path $BasePath -ChildPath "MT5\AfterPrime"

# Validate the development environment exists
if (-not (Test-Path -Path $DevPath)) {
    Write-Host "Development environment not found: $DevPath" -ForegroundColor Red
    exit 1
}

# Find MetaTrader paths dynamically if not found at default locations
if (-not (Test-Path -Path $MT4Path) -and ($Platform -eq "MT4" -or $Platform -eq "Both")) {
    # Try to find MT4 installations
    $potentialMT4Paths = Get-ChildItem -Path (Join-Path -Path $BasePath -ChildPath "MT4") -Directory
    if ($potentialMT4Paths.Count -gt 0) {
        $MT4Path = $potentialMT4Paths[0].FullName
        Write-Host "Found MT4 at: $MT4Path" -ForegroundColor Yellow
    } else {
        Write-Host "MT4 installation not found" -ForegroundColor Red
        if ($Platform -eq "MT4") {
            exit 1
        }
    }
}

if (-not (Test-Path -Path $MT5Path) -and ($Platform -eq "MT5" -or $Platform -eq "Both")) {
    # Try to find MT5 installations
    $potentialMT5Paths = Get-ChildItem -Path (Join-Path -Path $BasePath -ChildPath "MT5") -Directory
    if ($potentialMT5Paths.Count -gt 0) {
        $MT5Path = $potentialMT5Paths[0].FullName
        Write-Host "Found MT5 at: $MT5Path" -ForegroundColor Yellow
    } else {
        Write-Host "MT5 installation not found" -ForegroundColor Red
        if ($Platform -eq "MT5") {
            exit 1
        }
    }
}

# Function to show section headers
function Show-Header {
    param ([string]$Title)
    Write-Host "`n=========================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
}

# Sync files (source to destination)
function Sync-Files {
    param (
        [string]$SourceDir,
        [string]$DestDir,
        [string]$Filter,
        [string]$Description
    )
    
    if (-not (Test-Path -Path $SourceDir)) {
        Write-Host "Source directory not found: $SourceDir" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path -Path $DestDir)) {
        New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
        Write-Host "Created destination directory: $DestDir" -ForegroundColor Green
    }
    
    $files = Get-ChildItem -Path $SourceDir -Filter $Filter -File -Recurse
    
    $fileCount = 0
    
    foreach ($file in $files) {
        # Keep the same relative path
        $relativePath = $file.FullName.Substring($SourceDir.Length)
        $destFile = Join-Path -Path $DestDir -ChildPath $relativePath
        $destDir = Split-Path -Path $destFile -Parent
        
        # Make sure the destination directory exists
        if (-not (Test-Path -Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        # Check if file exists and is different
        $shouldCopy = $true
        if (Test-Path -Path $destFile) {
            if (-not $Force) {
                $sourceHash = Get-FileHash -Path $file.FullName
                $destHash = Get-FileHash -Path $destFile
                
                if ($sourceHash.Hash -eq $destHash.Hash) {
                    # Files are identical, skip
                    $shouldCopy = $false
                } else {
                    # Ask for confirmation
                    $fileName = Split-Path -Path $file.FullName -Leaf
                    $confirm = Read-Host "File '$fileName' is different. Overwrite? (y/n)"
                    if ($confirm -ne "y") {
                        $shouldCopy = $false
                    }
                }
            }
        }
        
        if ($shouldCopy) {
            Copy-Item -Path $file.FullName -Destination $destFile -Force
            Write-Host "Copied: $($file.FullName) -> $destFile" -ForegroundColor Green
            $fileCount++
        }
    }
    
    if ($fileCount -eq 0) {
        Write-Host "No $Description files were copied." -ForegroundColor Yellow
    } else {
        Write-Host "Copied $fileCount $Description files." -ForegroundColor Green
    }
    
    return $true
}

# Sync MT4 files
function Sync-MT4 {
    param (
        [string]$Direction
    )
    
    # Define directories
    $devSrcDir = Join-Path -Path $DevPath -ChildPath "src"
    $devBuildDir = Join-Path -Path $DevPath -ChildPath "build\mt4"
    $mt4MqlDir = Join-Path -Path $MT4Path -ChildPath "MQL4"
    
    # Define experts directories
    $devStrategiesDir = Join-Path -Path $devSrcDir -ChildPath "strategies"
    $mt4ExpertsDir = Join-Path -Path $mt4MqlDir -ChildPath "Experts"
    
    # Define indicators directories
    $devIndicatorsDir = Join-Path -Path $devSrcDir -ChildPath "indicators"
    $mt4IndicatorsDir = Join-Path -Path $mt4MqlDir -ChildPath "Indicators"
    
    # Define include directories
    $devIncludeDir = Join-Path -Path $devSrcDir -ChildPath "include"
    $mt4IncludeDir = Join-Path -Path $mt4MqlDir -ChildPath "Include"
    
    # Define scripts directories
    $devScriptsDir = Join-Path -Path $devSrcDir -ChildPath "scripts"
    $mt4ScriptsDir = Join-Path -Path $mt4MqlDir -ChildPath "Scripts"
    
    # Define libraries directories
    $devLibrariesDir = Join-Path -Path $devSrcDir -ChildPath "libraries"
    $mt4LibrariesDir = Join-Path -Path $mt4MqlDir -ChildPath "Libraries"
    
    # Sync from development to MetaTrader
    if ($Direction -eq "TwoWay" -or $Direction -eq "DevToMT") {
        Show-Header "Syncing MT4: Development -> MetaTrader"
        
        # Sync source files
        Sync-Files -SourceDir $devStrategiesDir -DestDir $mt4ExpertsDir -Filter "*.mq4" -Description "strategy source"
        Sync-Files -SourceDir $devIndicatorsDir -DestDir $mt4IndicatorsDir -Filter "*.mq4" -Description "indicator source"
        Sync-Files -SourceDir $devIncludeDir -DestDir $mt4IncludeDir -Filter "*.mqh" -Description "include"
        Sync-Files -SourceDir $devScriptsDir -DestDir $mt4ScriptsDir -Filter "*.mq4" -Description "script source"
        Sync-Files -SourceDir $devLibrariesDir -DestDir $mt4LibrariesDir -Filter "*.mq4" -Description "library source"
        
        # Sync compiled files
        if (Test-Path -Path $devBuildDir) {
            Sync-Files -SourceDir $devBuildDir -DestDir $mt4ExpertsDir -Filter "*.ex4" -Description "compiled expert"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "indicators") -DestDir $mt4IndicatorsDir -Filter "*.ex4" -Description "compiled indicator" 
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "scripts") -DestDir $mt4ScriptsDir -Filter "*.ex4" -Description "compiled script"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "libraries") -DestDir $mt4LibrariesDir -Filter "*.ex4" -Description "compiled library"
        }
    }
    
    # Sync from MetaTrader to development
    if ($Direction -eq "TwoWay" -or $Direction -eq "MTToDev") {
        Show-Header "Syncing MT4: MetaTrader -> Development"
        
        # Sync source files
        Sync-Files -SourceDir $mt4ExpertsDir -DestDir $devStrategiesDir -Filter "*.mq4" -Description "strategy source"
        Sync-Files -SourceDir $mt4IndicatorsDir -DestDir $devIndicatorsDir -Filter "*.mq4" -Description "indicator source"
        Sync-Files -SourceDir $mt4IncludeDir -DestDir $devIncludeDir -Filter "*.mqh" -Description "include"
        Sync-Files -SourceDir $mt4ScriptsDir -DestDir $devScriptsDir -Filter "*.mq4" -Description "script source"
        Sync-Files -SourceDir $mt4LibrariesDir -DestDir $devLibrariesDir -Filter "*.mq4" -Description "library source"
    }
}

# Sync MT5 files
function Sync-MT5 {
    param (
        [string]$Direction
    )
    
    # Define directories
    $devSrcDir = Join-Path -Path $DevPath -ChildPath "src"
    $devBuildDir = Join-Path -Path $DevPath -ChildPath "build\mt5"
    $mt5MqlDir = Join-Path -Path $MT5Path -ChildPath "MQL5"
    
    # Define experts directories
    $devStrategiesDir = Join-Path -Path $devSrcDir -ChildPath "strategies"
    $mt5ExpertsDir = Join-Path -Path $mt5MqlDir -ChildPath "Experts"
    
    # Define indicators directories
    $devIndicatorsDir = Join-Path -Path $devSrcDir -ChildPath "indicators"
    $mt5IndicatorsDir = Join-Path -Path $mt5MqlDir -ChildPath "Indicators"
    
    # Define include directories
    $devIncludeDir = Join-Path -Path $devSrcDir -ChildPath "include"
    $mt5IncludeDir = Join-Path -Path $mt5MqlDir -ChildPath "Include"
    
    # Define scripts directories
    $devScriptsDir = Join-Path -Path $devSrcDir -ChildPath "scripts"
    $mt5ScriptsDir = Join-Path -Path $mt5MqlDir -ChildPath "Scripts"
    
    # Define libraries directories
    $devLibrariesDir = Join-Path -Path $devSrcDir -ChildPath "libraries"
    $mt5LibrariesDir = Join-Path -Path $mt5MqlDir -ChildPath "Libraries"
    
    # Sync from development to MetaTrader
    if ($Direction -eq "TwoWay" -or $Direction -eq "DevToMT") {
        Show-Header "Syncing MT5: Development -> MetaTrader"
        
        # Sync source files
        Sync-Files -SourceDir $devStrategiesDir -DestDir $mt5ExpertsDir -Filter "*.mq5" -Description "strategy source"
        Sync-Files -SourceDir $devIndicatorsDir -DestDir $mt5IndicatorsDir -Filter "*.mq5" -Description "indicator source"
        Sync-Files -SourceDir $devIncludeDir -DestDir $mt5IncludeDir -Filter "*.mqh" -Description "include"
        Sync-Files -SourceDir $devScriptsDir -DestDir $mt5ScriptsDir -Filter "*.mq5" -Description "script source"
        Sync-Files -SourceDir $devLibrariesDir -DestDir $mt5LibrariesDir -Filter "*.mq5" -Description "library source"
        
        # Sync compiled files
        if (Test-Path -Path $devBuildDir) {
            Sync-Files -SourceDir $devBuildDir -DestDir $mt5ExpertsDir -Filter "*.ex5" -Description "compiled expert"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "indicators") -DestDir $mt5IndicatorsDir -Filter "*.ex5" -Description "compiled indicator" 
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "scripts") -DestDir $mt5ScriptsDir -Filter "*.ex5" -Description "compiled script"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDir -ChildPath "libraries") -DestDir $mt5LibrariesDir -Filter "*.ex5" -Description "compiled library"
        }
    }
    
    # Sync from MetaTrader to development
    if ($Direction -eq "TwoWay" -or $Direction -eq "MTToDev") {
        Show-Header "Syncing MT5: MetaTrader -> Development"
        
        # Sync source files
        Sync-Files -SourceDir $mt5ExpertsDir -DestDir $devStrategiesDir -Filter "*.mq5" -Description "strategy source"
        Sync-Files -SourceDir $mt5IndicatorsDir -DestDir $devIndicatorsDir -Filter "*.mq5" -Description "indicator source"
        Sync-Files -SourceDir $mt5IncludeDir -DestDir $devIncludeDir -Filter "*.mqh" -Description "include"
        Sync-Files -SourceDir $mt5ScriptsDir -DestDir $devScriptsDir -Filter "*.mq5" -Description "script source"
        Sync-Files -SourceDir $mt5LibrariesDir -DestDir $devLibrariesDir -Filter "*.mq5" -Description "library source"
    }
}

# Function to sync to global build directory
function Sync-GlobalBuild {
    # Define directories
    $devBuildDirMT4 = Join-Path -Path $DevPath -ChildPath "build\mt4"
    $devBuildDirMT5 = Join-Path -Path $DevPath -ChildPath "build\mt5"
    $globalBuildDirMT4 = Join-Path -Path $BasePath -ChildPath "build\mt4"
    $globalBuildDirMT5 = Join-Path -Path $BasePath -ChildPath "build\mt5"
    
    Show-Header "Syncing to Global Build Directory"
    
    # Sync MT4 build files
    if ($Platform -eq "MT4" -or $Platform -eq "Both") {
        if (Test-Path -Path $devBuildDirMT4) {
            Sync-Files -SourceDir $devBuildDirMT4 -DestDir $globalBuildDirMT4 -Filter "*.ex4" -Description "MT4 build"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDirMT4 -ChildPath "include") -DestDir (Join-Path -Path $globalBuildDirMT4 -ChildPath "include") -Filter "*.mqh" -Description "MT4 include"
        }
    }
    
    # Sync MT5 build files
    if ($Platform -eq "MT5" -or $Platform -eq "Both") {
        if (Test-Path -Path $devBuildDirMT5) {
            Sync-Files -SourceDir $devBuildDirMT5 -DestDir $globalBuildDirMT5 -Filter "*.ex5" -Description "MT5 build"
            Sync-Files -SourceDir (Join-Path -Path $devBuildDirMT5 -ChildPath "include") -DestDir (Join-Path -Path $globalBuildDirMT5 -ChildPath "include") -Filter "*.mqh" -Description "MT5 include"
        }
    }
}

# Main sync function
function Do-Sync {
    # Sync MT4 files
    if ($Platform -eq "MT4" -or $Platform -eq "Both") {
        if (Test-Path -Path $MT4Path) {
            Sync-MT4 -Direction $SyncDirection
        } else {
            Write-Host "MT4 not found at $MT4Path - skipping MT4 sync" -ForegroundColor Yellow
        }
    }
    
    # Sync MT5 files
    if ($Platform -eq "MT5" -or $Platform -eq "Both") {
        if (Test-Path -Path $MT5Path) {
            Sync-MT5 -Direction $SyncDirection
        } else {
            Write-Host "MT5 not found at $MT5Path - skipping MT5 sync" -ForegroundColor Yellow
        }
    }
    
    # Sync to global build directory
    Sync-GlobalBuild
}

# Start synchronization
if ($WatchMode) {
    Show-Header "Starting File Watch Mode"
    Write-Host "Watching for file changes. Press Ctrl+C to stop." -ForegroundColor Yellow
    
    # Initial sync
    Do-Sync
    
    # Watch for file changes
    try {
        while ($true) {
            Start-Sleep -Seconds 10
            Do-Sync
        }
    }
    catch {
        Write-Host "`nWatch mode stopped." -ForegroundColor Red
    }
} else {
    # One-time sync
    Do-Sync
}

Write-Host "`nSynchronization complete!" -ForegroundColor Green
