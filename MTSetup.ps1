# MTSetup.ps1
# Core MetaTrader Trading Framework Setup

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

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
    [string]$TestEnvironmentName
)

# Debug: Print parameter values to confirm they are passed correctly
Write-Host "Parameters received by MTSetup.ps1:" -ForegroundColor Cyan
Write-Host "BasePath: $BasePath" -ForegroundColor Yellow
Write-Host "SkipMT4: $SkipMT4" -ForegroundColor Yellow
Write-Host "SkipMT5: $SkipMT5" -ForegroundColor Yellow
Write-Host "MT4BrokerName: $MT4BrokerName" -ForegroundColor Yellow
Write-Host "MT5BrokerName: $MT5BrokerName" -ForegroundColor Yellow
Write-Host "MT4Path: $MT4Path" -ForegroundColor Yellow
Write-Host "MT5Path: $MT5Path" -ForegroundColor Yellow
Write-Host "SkipDocker: $SkipDocker" -ForegroundColor Yellow
Write-Host "DevEnvironmentName: $DevEnvironmentName" -ForegroundColor Yellow
Write-Host "TestEnvironmentName: $TestEnvironmentName" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Config = @{
    BasePath = $BasePath
    MT4Path = Join-Path -Path $BasePath -ChildPath "MT4"
    MT5Path = Join-Path -Path $BasePath -ChildPath "MT5"
    DevPath = Join-Path -Path $BasePath -ChildPath "Dev"
    TestPath = Join-Path -Path $BasePath -ChildPath "Test"
}

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
    param ([string]$Version, [string]$BrokerName, [string]$DestinationPath, [string]$ExplicitPath = "")
    $exe = if ($Version -eq "MT4") { "terminal.exe" } else { "terminal64.exe" }
    $destPath = Join-Path -Path $DestinationPath -ChildPath $BrokerName
    Create-Directory -Path $destPath
    $terminalPath = Join-Path -Path $destPath -ChildPath $exe

    if (Test-Path $terminalPath) { Write-Status "$Version for $BrokerName already exists" "Yellow"; return @{ Version = $Version; BrokerName = $BrokerName; Path = $destPath; Terminal = $terminalPath } }
    
    $sourcePath = if ($ExplicitPath -and (Test-Path $ExplicitPath)) { $ExplicitPath } else {
        $paths = @("${env:ProgramFiles(x86)}\*$BrokerName*", "${env:ProgramFiles}\*$BrokerName*") | ForEach-Object { Get-ChildItem -Path $_ -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
        $paths | Where-Object { Test-Path (Join-Path -Path $_ -ChildPath $exe) } | Select-Object -First 1
    }
    
    if (-not $sourcePath) { Write-Status "$Version for $BrokerName not found. Please install it first." "Red"; return $null }
    
    robocopy "$sourcePath" "$destPath" /E /XJ /R:2 /W:1 /NFL /NDL
    if (Test-Path $terminalPath) {
        Set-Content -Path (Join-Path -Path $destPath -ChildPath "origin.ini") -Value "[Common]`r`nPortable=1"
        Write-Status "$Version containerized for $BrokerName" "Green"
        return @{ Version = $Version; BrokerName = $BrokerName; Path = $destPath; Terminal = $terminalPath }
    }
    Write-Status "Failed to containerize $Version" "Red"; return $null
}

function Setup-Environment {
    param ([string]$Path, [string]$Name, [array]$Installations, [string]$Type = "Dev")
    $envPath = Join-Path -Path $Path -ChildPath $Name
    Create-Directory -Path $envPath
    $dirs = @("src/strategies", "build/mt4", "build/mt5")
    foreach ($dir in $dirs) { Create-Directory -Path (Join-Path -Path $envPath -ChildPath $dir) }

    # Sample files content
    $mq4Expert = @"
// SampleStrategy.mq4
#property copyright "MT Trading Framework"
input int MAPeriod = 20;
void OnTick() { double ma = iMA(Symbol(), Period(), MAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0); Print(Close[0] > ma ? "Bullish" : "Bearish"); }
"@
    $mq5Expert = @"
// SampleStrategy.mq5
#property copyright "MT Trading Framework"
input int MAPeriod = 20;
void OnTick() { double ma[]; ArraySetAsSeries(ma, true); CopyBuffer(iMA(_Symbol, _Period, MAPeriod, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma); double price[]; CopyClose(_Symbol, _Period, 0, 1, price); Print(price[0] > ma[0] ? "Bullish" : "Bearish"); }
"@
    $mq4Indicator = @"
// SampleIndicator.mq4
#property copyright "MT Trading Framework"
#property indicator_chart_window
input int MAPeriod = 20;
double Buffer[];
int OnInit() { SetIndexBuffer(0, Buffer); return(INIT_SUCCEEDED); }
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
    for(int i = 0; i < rates_total; i++) Buffer[i] = iMA(NULL, 0, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
    return(rates_total);
}
"@
    $mq5Indicator = @"
// SampleIndicator.mq5
#property copyright "MT Trading Framework"
#property indicator_chart_window
input int MAPeriod = 20;
double Buffer[];
int maHandle;
int OnInit() { maHandle = iMA(_Symbol, _Period, MAPeriod, 0, MODE_SMA, PRICE_CLOSE); ArraySetAsSeries(Buffer, true); return(INIT_SUCCEEDED); }
void OnDeinit(const int reason) { IndicatorRelease(maHandle); }
int OnCalculate(const int rates_total, the int prev_calculated, const datetime &time[], const double &open[], const double &high[], the double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
    CopyBuffer(maHandle, 0, 0, rates_total, Buffer);
    return(rates_total);
}
"@
    $mq4Script = @"
// SampleScript.mq4
#property copyright "MT Trading Framework"
void OnStart() { Alert("Sample Script Executed on " + Symbol()); }
"@
    $mq5Script = @"
// SampleScript.mq5
#property copyright "MT Trading Framework"
void OnStart() { Alert("Sample Script Executed on " + _Symbol); }
"@

    if ($Type -eq "Dev") {
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleStrategy.mq4") -Value $mq4Expert
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleStrategy.mq5") -Value $mq5Expert
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleIndicator.mq4") -Value $mq4Indicator
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleIndicator.mq5") -Value $mq5Indicator
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleScript.mq4") -Value $mq4Script
        Set-Content -Path (Join-Path -Path $envPath -ChildPath "src/strategies/SampleScript.mq5") -Value $mq5Script
    } elseif (Test-Path (Join-Path -Path $Config.DevPath -ChildPath "$DevEnvironmentName/src/strategies")) {
        Copy-Item -Path (Join-Path -Path $Config.DevPath -ChildPath "$DevEnvironmentName/src/strategies/*") -Destination (Join-Path -Path $envPath -ChildPath "src/strategies") -Force
    }

    # Create strategy-specific subfolders in MT4/MT5 container directories and populate with sample files
    foreach ($inst in $Installations) {
        $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
        $subFolders = @("Experts", "Indicators", "Scripts", "Libraries", "Images", "Files", "Include")
        foreach ($folder in $subFolders) {
            $strategyFolder = Join-Path -Path $mqlDir -ChildPath "$folder/$Name"
            Create-Directory -Path $strategyFolder
            # Populate with sample files to make folders visible in MT interface
            if ($Type -eq "Dev") {
                if ($inst.Version -eq "MT4") {
                    if ($folder -eq "Experts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleStrategy.mq4") -Value $mq4Expert }
                    if ($folder -eq "Indicators") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleIndicator.mq4") -Value $mq4Indicator }
                    if ($folder -eq "Scripts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleScript.mq4") -Value $mq4Script }
                }
                if ($inst.Version -eq "MT5") {
                    if ($folder -eq "Experts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleStrategy.mq5") -Value $mq5Expert }
                    if ($folder -eq "Indicators") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleIndicator.mq5") -Value $mq5Indicator }
                    if ($folder -eq "Scripts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleScript.mq5") -Value $mq5Script }
                }
            }
        }
    }

    $buildScript = @"
# Build.ps1 (Docker Mode)
param ([switch]`$SkipMT4, [switch]`$SkipMT5)
`$root = "$BasePath"
`$relPath = "/app/$Type/$Name"
Push-Location `$root
`$cmd = if (-not `$SkipMT4 -and -not `$SkipMT5) { "build_mt4 && build_mt5" } elseif (-not `$SkipMT4) { "build_mt4" } else { "build_mt5" }
docker compose -f docker-compose.yml run --rm mt_builder bash -c "cd `$relPath && `$cmd"
Pop-Location
Write-Host "Build complete. Compiled files copied to MT4/MT5 containers under Experts/$Name." -ForegroundColor Green
"@
    $buildPath = Join-Path -Path $envPath -ChildPath "build.ps1"
    Set-Content -Path $buildPath -Value $buildScript
    
    # Create shortcuts for this environment
    foreach ($inst in $Installations) {
        Create-Shortcut -TargetPath "powershell.exe" -ShortcutName "$Type - Build $Name" -Arguments "-ExecutionPolicy Bypass -File `"$buildPath`"" -BrokerName $inst.BrokerName
        $args = "/portable"
        if ($Type -eq "Test" -and $inst.Version -eq "MT5") { $args += " /testmode" }
        Create-Shortcut -TargetPath $inst.Terminal -ShortcutName "$Type - $Name ($($inst.BrokerName) $($inst.Version))" -Arguments $args -BrokerName $inst.BrokerName
    }
    Write-Status "$Type environment '$Name' created" "Green"
}

function Setup-Basic-Strategy-Folders {
    param ([array]$Installations, [string]$StrategyName)
    $mq4Expert = @"
// SampleStrategy.mq4
#property copyright "MT Trading Framework"
input int MAPeriod = 20;
void OnTick() { double ma = iMA(Symbol(), Period(), MAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0); Print(Close[0] > ma ? "Bullish" : "Bearish"); }
"@
    $mq5Expert = @"
// SampleStrategy.mq5
#property copyright "MT Trading Framework"
input int MAPeriod = 20;
void OnTick() { double ma[]; ArraySetAsSeries(ma, true); CopyBuffer(iMA(_Symbol, _Period, MAPeriod, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma); double price[]; CopyClose(_Symbol, _Period, 0, 1, price); Print(price[0] > ma[0] ? "Bullish" : "Bearish"); }
"@
    $mq4Indicator = @"
// SampleIndicator.mq4
#property copyright "MT Trading Framework"
#property indicator_chart_window
input int MAPeriod = 20;
double Buffer[];
int OnInit() { SetIndexBuffer(0, Buffer); return(INIT_SUCCEEDED); }
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
    for(int i = 0; i < rates_total; i++) Buffer[i] = iMA(NULL, 0, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
    return(rates_total);
}
"@
    $mq5Indicator = @"
// SampleIndicator.mq5
#property copyright "MT Trading Framework"
#property indicator_chart_window
input int MAPeriod = 20;
double Buffer[];
int maHandle;
int OnInit() { maHandle = iMA(_Symbol, _Period, MAPeriod, 0, MODE_SMA, PRICE_CLOSE); ArraySetAsSeries(Buffer, true); return(INIT_SUCCEEDED); }
void OnDeinit(const int reason) { IndicatorRelease(maHandle); }
int OnCalculate(const int rates_total, the int prev_calculated, const datetime &time[], the double &open[], const double &high[], the double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
    CopyBuffer(maHandle, 0, 0, rates_total, Buffer);
    return(rates_total);
}
"@
    $mq4Script = @"
// SampleScript.mq4
#property copyright "MT Trading Framework"
void OnStart() { Alert("Sample Script Executed on " + Symbol()); }
"@
    $mq5Script = @"
// SampleScript.mq5
#property copyright "MT Trading Framework"
void OnStart() { Alert("Sample Script Executed on " + _Symbol); }
"@
    foreach ($inst in $Installations) {
        $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
        $subFolders = @("Experts", "Indicators", "Scripts", "Libraries", "Images", "Files", "Include")
        foreach ($folder in $subFolders) {
            $strategyFolder = Join-Path -Path $mqlDir -ChildPath "$folder/$StrategyName"
            Create-Directory -Path $strategyFolder
            # Populate with sample files to make folders visible in MT interface
            if ($inst.Version -eq "MT4") {
                if ($folder -eq "Experts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleStrategy.mq4") -Value $mq4Expert }
                if ($folder -eq "Indicators") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleIndicator.mq4") -Value $mq4Indicator }
                if ($folder -eq "Scripts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleScript.mq4") -Value $mq4Script }
            }
            if ($inst.Version -eq "MT5") {
                if ($folder -eq "Experts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleStrategy.mq5") -Value $mq5Expert }
                if ($folder -eq "Indicators") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleIndicator.mq5") -Value $mq5Indicator }
                if ($folder -eq "Scripts") { Set-Content -Path (Join-Path -Path $strategyFolder -ChildPath "SampleScript.mq5") -Value $mq5Script }
            }
        }
    }
    Write-Status "Basic strategy folders created for '$StrategyName' in MT4/MT5 containers with sample files" "Green"
}

function Setup-Docker {
    Create-Directory -Path (Join-Path -Path $BasePath -ChildPath "scripts")
    Set-Content -Path (Join-Path -Path $BasePath -ChildPath "Dockerfile") -Value @"
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y wget wine wine64 winetricks && \
    wget http://web.archive.org/web/20220512025614/https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/metaeditor4setup.exe -O /tmp/mt4.exe && \
    wine /tmp/mt4.exe /S && rm /tmp/mt4.exe && \
    wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/metaeditor64.exe -O /tmp/mt5.exe && \
    wine /tmp/mt5.exe /S && rm /tmp/mt5.exe
COPY scripts /usr/local/bin/
RUN chmod +x /usr/local/bin/build_mt*
ENTRYPOINT ["/bin/bash"]
"@
    Set-Content -Path (Join-Path -Path $BasePath -ChildPath "docker-compose.yml") -Value @"
version: '3.8'
services:
  mt_builder:
    build: .
    volumes:
      - ./:/app
"@
    Set-Content -Path (Join-Path -Path $BasePath -ChildPath "scripts/build_mt4.sh") -Value @"
#!/bin/bash
cd /app/$Type/$Name/src/strategies
for f in *.mq4; do 
    [ -f "\$f" ] && wine "/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor/metaeditor.exe" /compile:"\$f" /log:"../../build/mt4/\${f%.mq4}.log" && \
    mv "\${f%.mq4}.ex4" "../../build/mt4/\${f%.mq4}.ex4" && \
    cp "../../build/mt4/\${f%.mq4}.ex4" "$($Config.MT4Path -replace '\\','/')/$MT4BrokerName/MQL4/Experts/$Name/"
done
echo "MT4 build complete"
"@
    Set-Content -Path (Join-Path -Path $BasePath -ChildPath "scripts/build_mt5.sh") -Value @"
#!/bin/bash
cd /app/$Type/$Name/src/strategies
for f in *.mq5; do 
    [ -f "\$f" ] && wine "/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor 64/metaeditor64.exe" /compile:"\$f" /log:"../../build/mt5/\${f%.mq5}.log" && \
    mv "\${f%.mq5}.ex5" "../../build/mt5/\${f%.mq5}.ex5" && \
    cp "../../build/mt5/\${f%.mq5}.ex5" "$($Config.MT5Path -replace '\\','/')/$MT5BrokerName/MQL5/Experts/$Name/"
done
echo "MT5 build complete"
"@
    Write-Status "Docker environment set up" "Green"
}

# Main Setup
Write-Status "Starting MT Trading Framework Setup" "Cyan"
Create-Directory -Path $BasePath
$installations = @()

if (-not $SkipMT4) { 
    $mt4Inst = Install-MetaTrader -Version "MT4" -BrokerName $MT4BrokerName -DestinationPath $Config.MT4Path -ExplicitPath $MT4Path 
    if ($mt4Inst) { 
        $installations += $mt4Inst
        Create-Shortcut -TargetPath $mt4Inst.Terminal -ShortcutName "MT4 - $MT4BrokerName" -BrokerName $MT4BrokerName
    }
}
if (-not $SkipMT5) { 
    $mt5Inst = Install-MetaTrader -Version "MT5" -BrokerName $MT5BrokerName -DestinationPath $Config.MT5Path -ExplicitPath $MT5Path 
    if ($mt5Inst) { 
        $installations += $mt5Inst
        Create-Shortcut -TargetPath $mt5Inst.Terminal -ShortcutName "MT5 - $MT5BrokerName" -BrokerName $MT5BrokerName
    }
}

if ($installations.Count -eq 0) { Write-Status "No MetaTrader installations found. Setup aborted." "Red"; exit 1 }

# Set up folders based on mode
if (-not $SkipDocker) {
    # Advanced mode
    Setup-Docker
    if ($DevEnvironmentName) { Setup-Environment -Path $Config.DevPath -Name $DevEnvironmentName -Installations $installations -Type "Dev" }
    if ($TestEnvironmentName) { Setup-Environment -Path $Config.TestPath -Name $TestEnvironmentName -Installations $installations -Type "Test" }
} else {
    # Basic mode: Create minimal strategy folders in MT4/MT5 containers with sample files
    if ($DevEnvironmentName) {
        Setup-Basic-Strategy-Folders -Installations $installations -StrategyName $DevEnvironmentName
    }
    Write-Status "Basic mode selected: MT4/MT5 installations and basic strategy folders created with sample files." "Yellow"
}

Write-Status "Setup complete at $BasePath" "Green"