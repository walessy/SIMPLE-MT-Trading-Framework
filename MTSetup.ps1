# MTSetup.ps1
# Revised MetaTrader Trading Framework Setup
# Created: April 4, 2025

[CmdletBinding()]
param (
    [string]$BasePath = "C:\Trading\MTFramework",
    [switch]$SkipMT4,
    [switch]$SkipMT5,
    [string]$MT4BrokerName = "Default",
    [string]$MT5BrokerName = "Default",
    [switch]$SkipGit,
    [switch]$SkipDocker,
    [string]$DevEnvironmentName,
    [switch]$Help
)

#region Configuration
$Config = @{
    BasePath = $BasePath
    BrokerPackagesPath = Join-Path -Path $BasePath -ChildPath "BrokerPackages"
    MT4Path = Join-Path -Path $BasePath -ChildPath "MT4"
    MT5Path = Join-Path -Path $BasePath -ChildPath "MT5"
    DevPath = Join-Path -Path $BasePath -ChildPath "Dev"
    TestPath = Join-Path -Path $BasePath -ChildPath "Test"
}
#endregion
#region Helper Functions
function Show-Header {
    param ([string]$Title)
    Write-Host "`n=========================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
}

function Create-Directory {
    param ([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Directory already exists: $Path" -ForegroundColor Yellow
        return $false
    }
}

function Create-Shortcut {
    param (
        [string]$TargetPath,
        [string]$ShortcutName,
        [string]$Arguments = ""
    )
    
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    $shortcutFile = Join-Path -Path $desktopPath -ChildPath "$ShortcutName.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutFile)
    $Shortcut.TargetPath = $TargetPath
    
    # Always add /portable switch for MetaTrader terminals if it's not already in the arguments
    if ($TargetPath -match "terminal(64)?\.exe$" -and -not $Arguments.Contains("/portable")) {
        if ([string]::IsNullOrEmpty($Arguments)) {
            $Arguments = "/portable"
        } else {
            $Arguments = "$Arguments /portable"
        }
    }
    
    if (-not [string]::IsNullOrEmpty($Arguments)) {
        $Shortcut.Arguments = $Arguments
    }
    
    $Shortcut.WorkingDirectory = Split-Path -Path $TargetPath -Parent
    $Shortcut.Description = $ShortcutName
    $Shortcut.IconLocation = $TargetPath
    $Shortcut.Save()
    
    Write-Host "Created shortcut: $shortcutFile" -ForegroundColor Green
}
function Install-MetaTrader {
    param (
        [string]$Version,
        [string]$BrokerName,
        [string]$DestinationPath
    )
    
    $brokerFolderPath = Join-Path -Path $DestinationPath -ChildPath $BrokerName
    
    # Check if already containerized
    $terminalExe = if ($Version -eq "MT4") { "terminal.exe" } else { "terminal64.exe" }
    $terminalPath = Join-Path -Path $brokerFolderPath -ChildPath $terminalExe
    
    if (Test-Path -Path $terminalPath) {
        Write-Host "$Version for $BrokerName is already containerized" -ForegroundColor Yellow
        return @{
            Version = $Version
            BrokerName = $BrokerName
            Path = $brokerFolderPath
            Terminal = $terminalPath
        }
    }
    
    # Find default installation path
    $defaultInstallPath = $null
    if ($Version -eq "MT4") {
        # Common MT4 paths
        $possiblePaths = @(
            "${env:ProgramFiles(x86)}\MetaTrader 4",
            "${env:ProgramFiles}\MetaTrader 4",
            "${env:LOCALAPPDATA}\Programs\MetaTrader 4"
        )
        
        # Check if broker-specific path exists
        $brokerPaths = @(
            "${env:ProgramFiles(x86)}\$BrokerName",
            "${env:ProgramFiles}\$BrokerName",
            "${env:LOCALAPPDATA}\Programs\$BrokerName"
        )
        
        $possiblePaths += $brokerPaths
    } else {
        # Common MT5 paths
        $possiblePaths = @(
            "${env:ProgramFiles(x86)}\MetaTrader 5",
            "${env:ProgramFiles}\MetaTrader 5",
            "${env:LOCALAPPDATA}\Programs\MetaTrader 5"
        )
        
        # Check if broker-specific path exists
        $brokerPaths = @(
            "${env:ProgramFiles(x86)}\$BrokerName",
            "${env:ProgramFiles}\$BrokerName",
            "${env:LOCALAPPDATA}\Programs\$BrokerName"
        )
        
        $possiblePaths += $brokerPaths
    }
    
    # Try to find the installation
    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path) {
            $defaultInstallPath = $path
            break
        }
    }
    
    # If not found automatically, ask user
    if (-not $defaultInstallPath) {
        Write-Host "$Version for $BrokerName not found in default locations." -ForegroundColor Yellow
        Write-Host "Please specify where $Version is installed:" -ForegroundColor Yellow
        $defaultInstallPath = Read-Host
        
        if ([string]::IsNullOrEmpty($defaultInstallPath) -or -not (Test-Path -Path $defaultInstallPath)) {
            Write-Host "Invalid path or MT installation not found." -ForegroundColor Red
            Write-Host "Please install $Version using the default installation process first." -ForegroundColor Red
            Write-Host "You can download from: https://www.metatrader4.com/en/download" -ForegroundColor Yellow
            return $null
        }
    }
    
    # Create broker folder
    Create-Directory -Path $brokerFolderPath
    
    # Copy files from installation to container folder
    Write-Host "Copying $Version files from $defaultInstallPath to container folder..." -ForegroundColor Yellow
    try {
        # Use robocopy for better performance and error handling
        $robocopyArgs = @(
            """$defaultInstallPath""",
            """$brokerFolderPath""",
            "/E",         # Copy subdirectories, including empty ones
            "/XJ",        # Exclude junction points
            "/R:2",       # Number of retries
            "/W:1",       # Wait time between retries
            "/NFL",       # No file list
            "/NDL"        # No directory list
        )
        
        Start-Process "robocopy" -ArgumentList $robocopyArgs -Wait -NoNewWindow
        
        # Verify copy
        if (Test-Path -Path $terminalPath) {
            Write-Host "$Version containerization for $BrokerName completed successfully!" -ForegroundColor Green
            
            # Set up portable configuration
            $configFile = Join-Path -Path $brokerFolderPath -ChildPath "origin.ini"
            if (-not (Test-Path -Path $configFile)) {
                Set-Content -Path $configFile -Value "[Common]`r`nPortable=1"
                Write-Host "Set portable mode configuration" -ForegroundColor Green
            }
            
            return @{
                Version = $Version
                BrokerName = $BrokerName
                Path = $brokerFolderPath
                Terminal = $terminalPath
            }
        } else {
            # Try alternative terminal name
            $altTerminalExe = if ($Version -eq "MT4") { "terminal64.exe" } else { "terminal.exe" }
            $altTerminalPath = Join-Path -Path $brokerFolderPath -ChildPath $altTerminalExe
            
            if (Test-Path -Path $altTerminalPath) {
                Write-Host "$Version containerization for $BrokerName completed successfully!" -ForegroundColor Green
                
                # Set up portable configuration
                $configFile = Join-Path -Path $brokerFolderPath -ChildPath "origin.ini"
                if (-not (Test-Path -Path $configFile)) {
                    Set-Content -Path $configFile -Value "[Common]`r`nPortable=1"
                    Write-Host "Set portable mode configuration" -ForegroundColor Green
                }
                
                return @{
                    Version = $Version
                    BrokerName = $BrokerName
                    Path = $brokerFolderPath
                    Terminal = $altTerminalPath
                }
            } else {
                Write-Host "Containerization failed - terminal executable not found" -ForegroundColor Red
                return $null
            }
        }
    } catch {
        Write-Host "Error copying files: $_" -ForegroundColor Red
        return $null
    }
}
function Setup-Git {
    param ([string]$BasePath)
    
    # Check if Git is installed
    try {
        $gitVersion = git --version
        Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
    } catch {
        Write-Host "Git is not installed. Please install Git first." -ForegroundColor Red
        Write-Host "Download from: https://git-scm.com/downloads" -ForegroundColor Yellow
        return $false
    }
    
    # Check if repository already exists
    $gitDir = Join-Path -Path $BasePath -ChildPath ".git"
    if (Test-Path -Path $gitDir) {
        Write-Host "Git repository already exists at: $BasePath" -ForegroundColor Yellow
        return $true
    }
    
    # Move to base path
    Push-Location $BasePath
    
    try {
        # Initialize repository
        Write-Host "Initializing Git repository..." -ForegroundColor Yellow
        git init
        
        # Create .gitignore
        $gitignoreContent = @"
# Compiled MetaTrader files
*.ex4
*.ex5

# Backtest results
*.htm
*.html
*.gif
*.png
*.jpg
*.jpeg
*.tester*

# Log files
*.log

# MetaTrader data
**/MQL**/Files/**
**/MQL**/Logs/**
**/profiles/**
**/tester/**
**/history/**
terminal.ini
origin.ini

# Broker installers
BrokerPackages/*.exe
"@
        Set-Content -Path (Join-Path -Path $BasePath -ChildPath ".gitignore") -Value $gitignoreContent
        
        # Create initial commit
        git add .gitignore
        git commit -m "Initial commit"
        
        # Create develop branch
        git checkout -b develop
        
        Write-Host "Git repository set up successfully!" -ForegroundColor Green
        return $true
    } finally {
        Pop-Location
    }
}
function Setup-Docker {
    param ([string]$BasePath)
    
    # Check if Docker is installed
    try {
        $dockerVersion = docker --version
        Write-Host "Docker is installed: $dockerVersion" -ForegroundColor Green
    } catch {
        Write-Host "Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
        Write-Host "Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
        return $false
    }
    
    # Create scripts directory
    $scriptsDir = Join-Path -Path $BasePath -ChildPath "scripts"
    Create-Directory -Path $scriptsDir
    
    # Create Dockerfile
    $dockerfilePath = Join-Path -Path $BasePath -ChildPath "Dockerfile"
    if (-not (Test-Path -Path $dockerfilePath)) {
        $dockerfileContent = @"
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WINEDEBUG=-all
ENV WINEPREFIX=/root/.wine

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    software-properties-common \
    winbind \
    cabextract \
    xvfb \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Wine
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends wine wine32 wine64 libwine libwine:i386 && \
    rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Setup Wine environment
RUN mkdir -p /root/.cache/wine
RUN wine wineboot --init

# Install MetaEditor for MT4
RUN wget http://web.archive.org/web/20220512025614/https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/metaeditor4setup.exe -O /tmp/metaeditor4setup.exe && \
    xvfb-run wine /tmp/metaeditor4setup.exe /S && \
    rm /tmp/metaeditor4setup.exe

# Install MetaEditor for MT5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/metaeditor64.exe -O /tmp/metaeditor5setup.exe && \
    xvfb-run wine /tmp/metaeditor5setup.exe /S && \
    rm /tmp/metaeditor5setup.exe

# Create working directory
WORKDIR /app

# Copy build scripts
COPY scripts/build_mt4.sh /usr/local/bin/build_mt4
COPY scripts/build_mt5.sh /usr/local/bin/build_mt5
RUN chmod +x /usr/local/bin/build_mt4 /usr/local/bin/build_mt5

ENTRYPOINT ["/bin/bash"]
"@
        Set-Content -Path $dockerfilePath -Value $dockerfileContent
        Write-Host "Created Dockerfile" -ForegroundColor Green
    } else {
        Write-Host "Dockerfile already exists" -ForegroundColor Yellow
    }
    
    # Create docker-compose.yml
    $dockerComposePath = Join-Path -Path $BasePath -ChildPath "docker-compose.yml"
    if (-not (Test-Path -Path $dockerComposePath)) {
        $dockerComposeContent = @"
version: '3.8'
services:
  mt_builder:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./:/app
    environment:
      - DISPLAY=:99
    command: bash
"@
        Set-Content -Path $dockerComposePath -Value $dockerComposeContent
        Write-Host "Created docker-compose.yml" -ForegroundColor Green
    } else {
        Write-Host "docker-compose.yml already exists" -ForegroundColor Yellow
    }
    
    # Create build.bat
    $buildBatchPath = Join-Path -Path $BasePath -ChildPath "build.bat"
    if (-not (Test-Path -Path $buildBatchPath)) {
        $buildBatchContent = @"
@echo off
echo Building MQL files with Docker...
cd %~dp0
docker compose build
docker compose run --rm mt_builder bash -c "build_mt4 && build_mt5"
echo Build complete!
pause
"@
        Set-Content -Path $buildBatchPath -Value $buildBatchContent
        Write-Host "Created build.bat" -ForegroundColor Green
    } else {
        Write-Host "build.bat already exists" -ForegroundColor Yellow
    }
    
    Write-Host "Docker build environment set up successfully!" -ForegroundColor Green
    return $true
}
# Create build scripts
function Create-BuildScripts {
    param ([string]$ScriptsDir)
    
    $buildMt4Path = Join-Path -Path $ScriptsDir -ChildPath "build_mt4.sh"
    if (-not (Test-Path -Path $buildMt4Path)) {
        $buildMt4Content = @"
#!/bin/bash
set -e

echo "Building MT4 files..."

# Navigate to source directory
cd /app/src

# Configure directories
MT4_METAEDITOR_PATH="/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor"
BUILD_OUTPUT_DIR="/app/build/mt4"

# Ensure build directory exists
mkdir -p \$BUILD_OUTPUT_DIR

# Compile each MQL4 file
find . -type f -name "*.mq4" | while read -r file; do
    filename=\$(basename "\$file")
    basename="\${filename%.*}"
    
    echo "Compiling: \$filename"
    
    # Run MetaEditor compiler in Wine with Xvfb
    xvfb-run wine "\$MT4_METAEDITOR_PATH/metaeditor.exe" /compile:"\$file" /log:"\$BUILD_OUTPUT_DIR/\${basename}.log"
    
    # Check if compilation was successful
    ex4_file="\${file%.*}.ex4"
    if [ -f "\$ex4_file" ]; then
        echo "Compilation successful: \$ex4_file"
        # Move compiled file to build directory
        mv "\$ex4_file" "\$BUILD_OUTPUT_DIR"
    else
        echo "Compilation failed for \$file. Check log at \$BUILD_OUTPUT_DIR/\${basename}.log"
        cat "\$BUILD_OUTPUT_DIR/\${basename}.log"
    fi
done

# Copy include files
mkdir -p "\$BUILD_OUTPUT_DIR/include"
find . -type f -name "*.mqh" -exec cp {} "\$BUILD_OUTPUT_DIR/include/" \;

echo "MT4 build complete. Output in \$BUILD_OUTPUT_DIR"
"@
        Set-Content -Path $buildMt4Path -Value $buildMt4Content -NoNewline
        Add-Content -Path $buildMt4Path -Value "`n" -NoNewline
        Write-Host "Created build_mt4.sh" -ForegroundColor Green
    } else {
        Write-Host "build_mt4.sh already exists" -ForegroundColor Yellow
    }
    
    $buildMt5Path = Join-Path -Path $ScriptsDir -ChildPath "build_mt5.sh"
    if (-not (Test-Path -Path $buildMt5Path)) {
        $buildMt5Content = @"
#!/bin/bash
set -e

echo "Building MT5 files..."

# Navigate to source directory
cd /app/src

# Configure directories
MT5_METAEDITOR_PATH="/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor 64"
BUILD_OUTPUT_DIR="/app/build/mt5"

# Ensure build directory exists
mkdir -p \$BUILD_OUTPUT_DIR

# Compile each MQL5 file
find . -type f -name "*.mq5" | while read -r file; do
    filename=\$(basename "\$file")
    basename="\${filename%.*}"
    
    echo "Compiling: \$filename"
    
    # Run MetaEditor compiler in Wine with Xvfb
    xvfb-run wine "\$MT5_METAEDITOR_PATH/metaeditor64.exe" /compile:"\$file" /log:"\$BUILD_OUTPUT_DIR/\${basename}.log"
    
    # Check if compilation was successful
    ex5_file="\${file%.*}.ex5"
    if [ -f "\$ex5_file" ]; then
        echo "Compilation successful: \$ex5_file"
        # Move compiled file to build directory
        mv "\$ex5_file" "\$BUILD_OUTPUT_DIR"
    else
        echo "Compilation failed for \$file. Check log at \$BUILD_OUTPUT_DIR/\${basename}.log"
        cat "\$BUILD_OUTPUT_DIR/\${basename}.log"
    fi
done

# Copy include files
mkdir -p "\$BUILD_OUTPUT_DIR/include"
find . -type f -name "*.mqh" -exec cp {} "\$BUILD_OUTPUT_DIR/include/" \;

echo "MT5 build complete. Output in \$BUILD_OUTPUT_DIR"
"@
        Set-Content -Path $buildMt5Path -Value $buildMt5Content -NoNewline
        Add-Content -Path $buildMt5Path -Value "`n" -NoNewline
        Write-Host "Created build_mt5.sh" -ForegroundColor Green
    } else {
        Write-Host "build_mt5.sh already exists" -ForegroundColor Yellow
    }
}
function Create-DevEnvironment {
    param (
        [string]$BasePath,
        [string]$Name,
        [array]$Installations = @()
    )
    
    # Create dev environment directory
    $devEnvPath = Join-Path -Path $Config.DevPath -ChildPath $Name
    Create-Directory -Path $devEnvPath
    
    # Create dev environment subdirectories
    $srcPath = Join-Path -Path $devEnvPath -ChildPath "src"
    Create-Directory -Path $srcPath
    
    # Create common subdirectories
    $dirs = @(
        "src/strategies",
        "src/indicators",
        "src/libraries",
        "src/include",
        "src/tests",
        "build/mt4",
        "build/mt5"
    )
    
    foreach ($dir in $dirs) {
        Create-Directory -Path (Join-Path -Path $devEnvPath -ChildPath $dir)
    }
    
    # Create sample strategy file for MT4
    $sampleMT4Path = Join-Path -Path $devEnvPath -ChildPath "src/strategies/SampleStrategy.mq4"
    if (-not (Test-Path -Path $sampleMT4Path)) {
        $sampleMT4Content = @"
//+------------------------------------------------------------------+
//|                                          SampleStrategy.mq4       |
//|                                     MT Trading Framework          |
//|                                  Created: $(Get-Date -Format "yyyy-MM-dd") |
//+------------------------------------------------------------------+
#property copyright "MT Trading Framework"
#property version   "1.0"
#property strict

// Input parameters
input int     MAPeriod = 20;
input ENUM_MA_METHOD MAMethod = MODE_SMA;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   double ma = iMA(Symbol(), Period(), MAPeriod, 0, MAMethod, PRICE_CLOSE, 0);
   double price = Close[0];
   
   if (price > ma)
   {
      // Bullish condition
      Print("Price above MA: Bullish");
   }
   else
   {
      // Bearish condition
      Print("Price below MA: Bearish");
   }
}
"@
        Set-Content -Path $sampleMT4Path -Value $sampleMT4Content
        Write-Host "Created sample MT4 strategy" -ForegroundColor Green
    }
    
    # Create sample strategy file for MT5
    $sampleMT5Path = Join-Path -Path $devEnvPath -ChildPath "src/strategies/SampleStrategy.mq5"
    if (-not (Test-Path -Path $sampleMT5Path)) {
        $sampleMT5Content = @"
//+------------------------------------------------------------------+
//|                                          SampleStrategy.mq5       |
//|                                     MT Trading Framework          |
//|                                  Created: $(Get-Date -Format "yyyy-MM-dd") |
//+------------------------------------------------------------------+
#property copyright "MT Trading Framework"
#property version   "1.0"
#property strict

// Input parameters
input int     MAPeriod = 20;
input ENUM_MA_METHOD MAMethod = MODE_SMA;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   double ma[];
   ArraySetAsSeries(ma, true);
   
   int maHandle = iMA(_Symbol, _Period, MAPeriod, 0, MAMethod, PRICE_CLOSE);
   CopyBuffer(maHandle, 0, 0, 1, ma);
   
   double price[];
   ArraySetAsSeries(price, true);
   CopyClose(_Symbol, _Period, 0, 1, price);
   
   if (price[0] > ma[0])
   {
      // Bullish condition
      Print("Price above MA: Bullish");
   }
   else
   {
      // Bearish condition
      Print("Price below MA: Bearish");
   }
}
"@
        Set-Content -Path $sampleMT5Path -Value $sampleMT5Content
        Write-Host "Created sample MT5 strategy" -ForegroundColor Green
    }
    
    # Create environment config file
    $configPath = Join-Path -Path $devEnvPath -ChildPath "config.json"
    $config = @{
        name = $Name
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        platforms = @()
    }
    
    # Add platform info
    foreach ($installation in $Installations) {
        $config.platforms += @{
            version = $installation.Version
            broker = $installation.BrokerName
            path = $installation.Path
        }
    }
    
    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
    Write-Host "Created environment configuration file" -ForegroundColor Green
    
    # Create convenience batch file for building
    $buildEnvBatchPath = Join-Path -Path $devEnvPath -ChildPath "build.bat"
    $buildEnvBatchContent = @"
@echo off
echo Building MQL files for $Name environment...
cd $(Split-Path -Path $BasePath -NoQualifier)
docker compose run --rm mt_builder bash -c "cd /app/Dev/$Name && build_mt4 && build_mt5"
echo Build complete!
pause
"@
    Set-Content -Path $buildEnvBatchPath -Value $buildEnvBatchContent
    Write-Host "Created build.bat for the environment" -ForegroundColor Green
    
    # Create desktop shortcut for the build script
    Create-Shortcut -TargetPath $buildEnvBatchPath -ShortcutName "Build $Name Environment"
    
    # Create shortcuts for MT installations if available
    foreach ($installation in $Installations) {
        $shortcutName = "$Name - $($installation.BrokerName) $($installation.Version)"
        Create-Shortcut -TargetPath $installation.Terminal -ShortcutName $shortcutName -Arguments "/portable"
    }
    
    Write-Host "Development environment '$Name' created successfully!" -ForegroundColor Green
    return $true
}
#endregion

# Display help if requested
if ($Help) {
    Write-Host "MT Trading Framework Setup Script" -ForegroundColor Cyan
    Write-Host "Usage: .\MTSetup.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -BasePath <path>         Base directory (default: C:\Trading\MTFramework)" -ForegroundColor White
    Write-Host "  -SkipMT4                 Skip MT4 containerization" -ForegroundColor White
    Write-Host "  -SkipMT5                 Skip MT5 containerization" -ForegroundColor White
    Write-Host "  -MT4BrokerName <n>       Name for MT4 broker (default: Default)" -ForegroundColor White
    Write-Host "  -MT5BrokerName <n>       Name for MT5 broker (default: Default)" -ForegroundColor White
    Write-Host "  -SkipGit                 Skip Git repository setup" -ForegroundColor White
    Write-Host "  -SkipDocker              Skip Docker build environment setup" -ForegroundColor White
    Write-Host "  -DevEnvironmentName      Name of development environment to create" -ForegroundColor White
    Write-Host "  -Help                    Display this help message" -ForegroundColor White
    
    exit 0
}

# Main setup process
Show-Header "MT Trading Framework Setup"

# Create base directories
Write-Host "Creating directory structure..." -ForegroundColor Yellow
Create-Directory -Path $Config.BasePath
Create-Directory -Path $Config.BrokerPackagesPath
Create-Directory -Path $Config.MT4Path
Create-Directory -Path $Config.MT5Path
Create-Directory -Path $Config.DevPath
Create-Directory -Path $Config.TestPath
Create-Directory -Path (Join-Path -Path $Config.BasePath -ChildPath "src")
Create-Directory -Path (Join-Path -Path $Config.BasePath -ChildPath "build")

# Install MetaTrader terminals (now containerizing existing installations)
$installations = @()

if (-not $SkipMT4) {
    Show-Header "Containerizing MT4"
    
    # Check if broker name was provided
    if ([string]::IsNullOrEmpty($MT4BrokerName)) {
        $MT4BrokerName = "Default"
        Write-Host "Using default broker name: $MT4BrokerName" -ForegroundColor Yellow
    }
    
    $result = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -DestinationPath $Config.MT4Path
    if ($result) {
        $installations += $result
    } else {
        Write-Host "Failed to containerize MT4 installation." -ForegroundColor Red
    }
} else {
    Write-Host "Skipping MT4 installation" -ForegroundColor Yellow
}

if (-not $SkipMT5) {
    Show-Header "Containerizing MT5"
    
    # Check if broker name was provided
    if ([string]::IsNullOrEmpty($MT5BrokerName)) {
        $MT5BrokerName = "Default"
        Write-Host "Using default broker name: $MT5BrokerName" -ForegroundColor Yellow
    }
    
    $result = Install-MetaTrader -Version "MT5" -BrokerName $MT5BrokerName -DestinationPath $Config.MT5Path
    if ($result) {
        $installations += $result
    } else {
        Write-Host "Failed to containerize MT5 installation." -ForegroundColor Red
    }
} else {
    Write-Host "Skipping MT5 installation" -ForegroundColor Yellow
}

# Create shortcuts with /portable switch
Show-Header "Creating Shortcuts"
foreach ($installation in $installations) {
    $shortcutName = "$($installation.BrokerName) $($installation.Version)"
    Create-Shortcut -TargetPath $installation.Terminal -ShortcutName $shortcutName -Arguments "/portable"
}

# Setup Git repository
if (-not $SkipGit) {
    Show-Header "Setting up Git Repository"
    Setup-Git -BasePath $Config.BasePath
} else {
    Write-Host "Skipping Git repository setup" -ForegroundColor Yellow
}

# Setup Docker build environment
if (-not $SkipDocker) {
    Show-Header "Setting up Docker Build Environment"
    $scriptsDir = Join-Path -Path $Config.BasePath -ChildPath "scripts"
    Create-Directory -Path $scriptsDir
    Create-BuildScripts -ScriptsDir $scriptsDir
    Setup-Docker -BasePath $Config.BasePath
} else {
    Write-Host "Skipping Docker build environment setup" -ForegroundColor Yellow
}

# Create development environment if requested
if (-not [string]::IsNullOrEmpty($DevEnvironmentName)) {
    Show-Header "Creating Development Environment: $DevEnvironmentName"
    Create-DevEnvironment -BasePath $Config.BasePath -Name $DevEnvironmentName -Installations $installations
}

Show-Header "Setup Complete"
Write-Host "MT Trading Framework has been set up successfully!" -ForegroundColor Green
Write-Host "You can find your installations in:" -ForegroundColor Green
Write-Host "- MT4: $($Config.MT4Path)" -ForegroundColor Green
Write-Host "- MT5: $($Config.MT5Path)" -ForegroundColor Green
if (-not [string]::IsNullOrEmpty($DevEnvironmentName)) {
    Write-Host "- Dev Environment: $($Config.DevPath)\$DevEnvironmentName" -ForegroundColor Green
}
Write-Host ""
Write-Host "Use the desktop shortcuts to access your terminals and build environments." -ForegroundColor Green