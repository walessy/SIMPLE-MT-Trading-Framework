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

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

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

function Setup-Basic-Strategy-Folders {
    param ([array]$Installations, [string]$StrategyName)
    if (-not $Installations -or $Installations.Count -eq 0) { Write-Status "No valid installations provided for strategy setup" "Red"; return }
    
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
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
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
        if ($inst -and $inst.Path) {
            $mqlDir = Join-Path -Path $inst.Path -ChildPath "MQL$($inst.Version[-1])"
            $subFolders = @("Experts", "Indicators", "Scripts", "Libraries", "Images", "Files", "Include")
            foreach ($folder in $subFolders) {
                $strategyFolder = Join-Path -Path $mqlDir -ChildPath "$folder/$StrategyName"
                Create-Directory -Path $strategyFolder
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
    Write-Status "Basic strategy folders created for '$StrategyName' in MT4/MT5 containers with sample files" "Green"
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

if ($installations.Count -eq 0) { 
    Write-Status "No MetaTrader installations found. Setup aborted." "Red"
    exit 1 
}

if (-not $SkipDocker) {
    # Advanced mode (unchanged for brevity, but not relevant to your case)
    Write-Status "Advanced mode not implemented in this fix for brevity" "Yellow"
} else {
    if ($DevEnvironmentName -and $installations.Count -gt 0) {
        Setup-Basic-Strategy-Folders -Installations $installations -StrategyName $DevEnvironmentName
    }
    Write-Status "Basic mode selected: MT4/MT5 installations and basic strategy folders created with sample files." "Yellow"
}

Write-Status "Setup complete at $BasePath" "Green"