# MT-Dashboard.ps1
# Interactive dashboard for MT Trading Framework
# Run as administrator

[CmdletBinding()]
param (
    [switch]$Help
)

# Global variables
$script:BasePath = "C:\Trading\MTFramework"
$script:CurrentEnv = ""
$script:MenuLevel = "Main"

function Show-Header {
    Clear-Host
    Write-Host "╔═════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           MT TRADING FRAMEWORK              ║" -ForegroundColor Cyan
    Write-Host "║                 DASHBOARD                   ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if (-not [string]::IsNullOrEmpty($script:CurrentEnv)) {
        Write-Host "Active Environment: " -NoNewline
        Write-Host $script:CurrentEnv -ForegroundColor Green
    }
    
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
}

function Show-Help {
    Show-Header
    Write-Host "DASHBOARD HELP" -ForegroundColor Yellow
    Write-Host "This dashboard helps you manage your MT Trading Framework environments."
    Write-Host ""
    Write-Host "Navigation:" -ForegroundColor Yellow
    Write-Host "- Use the number keys to select menu options"
    Write-Host "- Press 'b' to go back to previous menu"
    Write-Host "- Press 'q' to quit the dashboard"
    Write-Host ""
    Write-Host "Common Tasks:" -ForegroundColor Yellow
    Write-Host "- Create new strategies"
    Write-Host "- Build existing strategies"
    Write-Host "- Launch MetaTrader terminals"
    Write-Host "- Sync files between environment and MetaTrader"
    Write-Host ""
    Write-Host "Press any key to return to the dashboard..." -ForegroundColor Cyan
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MainMenu {
    $script:MenuLevel = "Main"
    Show-Header
    
    Write-Host "MAIN MENU" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Select Development Environment"
    Write-Host "2. Create New Environment"
    Write-Host "3. Launch MetaTrader"
    Write-Host "4. Open Framework Folder"
    Write-Host "5. Help"
    Write-Host ""
    Write-Host "Q. Quit"
    Write-Host ""
    Write-Host "Select an option: " -NoNewline -ForegroundColor Yellow
}

function Show-EnvironmentMenu {
    $script:MenuLevel = "Environment"
    Show-Header
    
    Write-Host "ENVIRONMENT: $script:CurrentEnv" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Build Strategy"
    Write-Host "2. Open Strategy Folder"
    Write-Host "3. Create New Strategy"
    Write-Host "4. Sync with MetaTrader"
    Write-Host "5. Launch MetaTrader with this Strategy"
    Write-Host ""
    Write-Host "B. Back to Main Menu"
    Write-Host "Q. Quit"
    Write-Host ""
    Write-Host "Select an option: " -NoNewline -ForegroundColor Yellow
}

function Get-DevelopmentEnvironments {
    $devPath = Join-Path -Path $script:BasePath -ChildPath "Dev"
    if (Test-Path -Path $devPath) {
        return Get-ChildItem -Path $devPath -Directory | Select-Object -ExpandProperty Name
    } else {
        return @()
    }
}

function Show-EnvironmentSelection {
    Show-Header
    
    $environments = Get-DevelopmentEnvironments
    
    if ($environments.Count -eq 0) {
        Write-Host "No development environments found." -ForegroundColor Red
        Write-Host "Would you like to create a new environment? (Y/N): " -NoNewline -ForegroundColor Yellow
        $createNew = Read-Host
        
        if ($createNew -eq "Y" -or $createNew -eq "y") {
            Create-NewEnvironment
        } else {
            Show-MainMenu
        }
        return
    }
    
    Write-Host "SELECT ENVIRONMENT" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $environments.Count; $i++) {
        Write-Host "$($i+1). $($environments[$i])"
    }
    
    Write-Host ""
    Write-Host "B. Back to Main Menu"
    Write-Host "Q. Quit"
    Write-Host ""
    Write-Host "Select an environment: " -NoNewline -ForegroundColor Yellow
    
    $selection = Read-Host
    
    if ($selection -eq "b" -or $selection -eq "B") {
        Show-MainMenu
        return
    }
    
    if ($selection -eq "q" -or $selection -eq "Q") {
        exit
    }
    
    $index = [int]$selection - 1
    
    if ($index -ge 0 -and $index -lt $environments.Count) {
        $script:CurrentEnv = $environments[$index]
        Show-EnvironmentMenu
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Show-EnvironmentSelection
    }
}

function Create-NewEnvironment {
    Show-Header
    
    Write-Host "CREATE NEW ENVIRONMENT" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Enter a name for your new environment: " -NoNewline
    $envName = Read-Host
    
    if ([string]::IsNullOrEmpty($envName)) {
        Write-Host "Environment name cannot be empty." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Show-MainMenu
        return
    }
    
    Write-Host ""
    Write-Host "Creating environment '$envName'..." -ForegroundColor Yellow
    
    # Call the MTSetup.ps1 script to create a new environment
    try {
        $setupPath = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
        & $setupPath -DevEnvironmentName $envName -SkipMT4 -SkipMT5
        
        Write-Host "Environment created successfully!" -ForegroundColor Green
        $script:CurrentEnv = $envName
        Start-Sleep -Seconds 2
        Show-EnvironmentMenu
    } catch {
        Write-Host "Error creating environment: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 3
        Show-MainMenu
    }
}

function Build-Strategy {
    Show-Header
    
    Write-Host "BUILDING STRATEGY" -ForegroundColor Yellow
    Write-Host ""
    
    $envPath = Join-Path -Path $script:BasePath -ChildPath "Dev\$script:CurrentEnv"
    $buildScript = Join-Path -Path $envPath -ChildPath "build.bat"
    
    if (-not (Test-Path -Path $buildScript)) {
        Write-Host "Build script not found." -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
        return
    }
    
    Write-Host "Building strategies in $script:CurrentEnv..." -ForegroundColor Yellow
    Write-Host "This may take a moment. Please wait..." -ForegroundColor Yellow
    Write-Host ""
    
    # Run the build script
    try {
        Start-Process -FilePath $buildScript -Wait
        
        Write-Host ""
        Write-Host "Build completed successfully!" -ForegroundColor Green
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
    } catch {
        Write-Host "Error during build: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
    }
}

function Open-StrategyFolder {
    $envPath = Join-Path -Path $script:BasePath -ChildPath "Dev\$script:CurrentEnv\src\strategies"
    
    if (Test-Path -Path $envPath) {
        Start-Process "explorer.exe" -ArgumentList $envPath
    } else {
        Show-Header
        Write-Host "Strategy folder not found." -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    Show-EnvironmentMenu
}

function Create-NewStrategy {
    Show-Header
    
    Write-Host "CREATE NEW STRATEGY" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Enter a name for your new strategy: " -NoNewline
    $strategyName = Read-Host
    
    if ([string]::IsNullOrEmpty($strategyName)) {
        Write-Host "Strategy name cannot be empty." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Show-EnvironmentMenu
        return
    }
    
    # Create strategy files in MT4/MT5 formats
    $envPath = Join-Path -Path $script:BasePath -ChildPath "Dev\$script:CurrentEnv"
    $strategiesPath = Join-Path -Path $envPath -ChildPath "src\strategies"
    
    if (-not (Test-Path -Path $strategiesPath)) {
        New-Item -Path $strategiesPath -ItemType Directory -Force | Out-Null
    }
    
    $mt4File = Join-Path -Path $strategiesPath -ChildPath "$strategyName.mq4"
    $mt5File = Join-Path -Path $strategiesPath -ChildPath "$strategyName.mq5"
    
    # Sample MT4 content
    $mt4Content = @"
//+------------------------------------------------------------------+
//|                                          $strategyName.mq4        |
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
    
    # Sample MT5 content
    $mt5Content = @"
//+------------------------------------------------------------------+
//|                                          $strategyName.mq5        |
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
    
    # Create the files
    Set-Content -Path $mt4File -Value $mt4Content
    Set-Content -Path $mt5File -Value $mt5Content
    
    Write-Host ""
    Write-Host "Strategy created successfully!" -ForegroundColor Green
    Write-Host "Files created:" -ForegroundColor Yellow
    Write-Host "- $mt4File" -ForegroundColor Yellow
    Write-Host "- $mt5File" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would you like to open the strategy folder? (Y/N): " -NoNewline -ForegroundColor Yellow
    $openFolder = Read-Host
    
    if ($openFolder -eq "Y" -or $openFolder -eq "y") {
        Start-Process "explorer.exe" -ArgumentList $strategiesPath
    }
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-EnvironmentMenu
}

function Sync-WithMetaTrader {
    Show-Header
    
    Write-Host "SYNC WITH METATRADER" -ForegroundColor Yellow
    Write-Host ""
    
    # Check if sync script exists
    $syncScript = Join-Path -Path $script:BasePath -ChildPath "scripts\Sync-MTEnvironment.ps1"
    
    if (-not (Test-Path -Path $syncScript)) {
        $syncScript = Join-Path -Path $PSScriptRoot -ChildPath "Sync-MTEnvironment.ps1"
        
        if (-not (Test-Path -Path $syncScript)) {
            Write-Host "Sync script not found." -ForegroundColor Red
            Write-Host "Press any key to continue..." -ForegroundColor Yellow
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Show-EnvironmentMenu
            return
        }
    }
    
    Write-Host "Select sync direction:" -ForegroundColor Yellow
    Write-Host "1. Two-way sync (recommended)"
    Write-Host "2. Development → MetaTrader"
    Write-Host "3. MetaTrader → Development"
    Write-Host ""
    Write-Host "Select an option: " -NoNewline -ForegroundColor Yellow
    $direction = Read-Host
    
    $syncDirection = "TwoWay"
    
    switch ($direction) {
        "1" { $syncDirection = "TwoWay" }
        "2" { $syncDirection = "DevToMT" }
        "3" { $syncDirection = "MTToDev" }
        default { $syncDirection = "TwoWay" }
    }
    
    Write-Host ""
    Write-Host "Select platform:" -ForegroundColor Yellow
    Write-Host "1. MetaTrader 4"
    Write-Host "2. MetaTrader 5"
    Write-Host "3. Both"
    Write-Host ""
    Write-Host "Select an option: " -NoNewline -ForegroundColor Yellow
    $platform = Read-Host
    
    $syncPlatform = "Both"
    
    switch ($platform) {
        "1" { $syncPlatform = "MT4" }
        "2" { $syncPlatform = "MT5" }
        "3" { $syncPlatform = "Both" }
        default { $syncPlatform = "Both" }
    }
    
    Write-Host ""
    Write-Host "Synchronizing $script:CurrentEnv with MetaTrader..." -ForegroundColor Yellow
    
    # Run sync script
    try {
        & $syncScript -DevEnvironmentName $script:CurrentEnv -Platform $syncPlatform -SyncDirection $syncDirection -Force
        
        Write-Host ""
        Write-Host "Synchronization completed successfully!" -ForegroundColor Green
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
    } catch {
        Write-Host "Error during synchronization: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
    }
}

function Launch-MetaTrader {
    Show-Header
    
    # Find MT terminals
    $mt4Path = Join-Path -Path $script:BasePath -ChildPath "MT4"
    $mt5Path = Join-Path -Path $script:BasePath -ChildPath "MT5"
    
    $mt4Terminals = @()
    $mt5Terminals = @()
    
    if (Test-Path -Path $mt4Path) {
        $mt4Terminals = Get-ChildItem -Path $mt4Path -Directory | ForEach-Object {
            $terminal = Join-Path -Path $_.FullName -ChildPath "terminal.exe"
            if (Test-Path -Path $terminal) {
                return @{
                    Name = $_.Name
                    Path = $terminal
                    Type = "MT4"
                }
            }
        }
    }
    
    if (Test-Path -Path $mt5Path) {
        $mt5Terminals = Get-ChildItem -Path $mt5Path -Directory | ForEach-Object {
            $terminal = Join-Path -Path $_.FullName -ChildPath "terminal64.exe"
            if (Test-Path -Path $terminal) {
                return @{
                    Name = $_.Name
                    Path = $terminal
                    Type = "MT5"
                }
            }
        }
    }
    
    $terminals = $mt4Terminals + $mt5Terminals
    
    if ($terminals.Count -eq 0) {
        Write-Host "No MetaTrader terminals found." -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        if ($script:MenuLevel -eq "Main") {
            Show-MainMenu
        } else {
            Show-EnvironmentMenu
        }
        return
    }
    
    Write-Host "LAUNCH METATRADER" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $terminals.Count; $i++) {
        Write-Host "$($i+1). $($terminals[$i].Name) ($($terminals[$i].Type))"
    }
    
    Write-Host ""
    Write-Host "B. Back"
    Write-Host "Q. Quit"
    Write-Host ""
    Write-Host "Select a terminal: " -NoNewline -ForegroundColor Yellow
    
    $selection = Read-Host
    
    if ($selection -eq "b" -or $selection -eq "B") {
        if ($script:MenuLevel -eq "Main") {
            Show-MainMenu
        } else {
            Show-EnvironmentMenu
        }
        return
    }
    
    if ($selection -eq "q" -or $selection -eq "Q") {
        exit
    }
    
    $index = [int]$selection - 1
    
    if ($index -ge 0 -and $index -lt $terminals.Count) {
        $terminal = $terminals[$index]
        
        Write-Host ""
        Write-Host "Launching $($terminal.Name) $($terminal.Type)..." -ForegroundColor Yellow
        
        Start-Process -FilePath $terminal.Path -ArgumentList "/portable"
        
        Write-Host "Terminal launched!" -ForegroundColor Green
        Start-Sleep -Seconds 2
        
        if ($script:MenuLevel -eq "Main") {
            Show-MainMenu
        } else {
            Show-EnvironmentMenu
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Launch-MetaTrader
    }
}

function Launch-EnvironmentMetaTrader {
    Show-Header
    
    # Find MT terminals
    $mt4Path = Join-Path -Path $script:BasePath -ChildPath "MT4"
    $mt5Path = Join-Path -Path $script:BasePath -ChildPath "MT5"
    
    $mt4Terminals = @()
    $mt5Terminals = @()
    
    if (Test-Path -Path $mt4Path) {
        $mt4Terminals = Get-ChildItem -Path $mt4Path -Directory | ForEach-Object {
            $terminal = Join-Path -Path $_.FullName -ChildPath "terminal.exe"
            if (Test-Path -Path $terminal) {
                return @{
                    Name = $_.Name
                    Path = $terminal
                    Type = "MT4"
                }
            }
        }
    }
    
    if (Test-Path -Path $mt5Path) {
        $mt5Terminals = Get-ChildItem -Path $mt5Path -Directory | ForEach-Object {
            $terminal = Join-Path -Path $_.FullName -ChildPath "terminal64.exe"
            if (Test-Path -Path $terminal) {
                return @{
                    Name = $_.Name
                    Path = $terminal
                    Type = "MT5"
                }
            }
        }
    }
    
    $terminals = $mt4Terminals + $mt5Terminals
    
    if ($terminals.Count -eq 0) {
        Write-Host "No MetaTrader terminals found." -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
        return
    }
    
    Write-Host "LAUNCH METATRADER WITH $script:CurrentEnv" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $terminals.Count; $i++) {
        Write-Host "$($i+1). $($terminals[$i].Name) ($($terminals[$i].Type))"
    }
    
    Write-Host ""
    Write-Host "B. Back"
    Write-Host ""
    Write-Host "Select a terminal: " -NoNewline -ForegroundColor Yellow
    
    $selection = Read-Host
    
    if ($selection -eq "b" -or $selection -eq "B") {
        Show-EnvironmentMenu
        return
    }
    
    $index = [int]$selection - 1
    
    if ($index -ge 0 -and $index -lt $terminals.Count) {
        $terminal = $terminals[$index]
        
        Write-Host ""
        Write-Host "Launching $($terminal.Name) $($terminal.Type) with $script:CurrentEnv..." -ForegroundColor Yellow
        
        # First sync the environment with the terminal
        $syncScript = Join-Path -Path $script:BasePath -ChildPath "scripts\Sync-MTEnvironment.ps1"
        
        if (Test-Path -Path $syncScript) {
            Write-Host "Syncing environment with terminal..." -ForegroundColor Yellow
            & $syncScript -DevEnvironmentName $script:CurrentEnv -Platform $terminal.Type -SyncDirection "DevToMT" -Force
        }
        
        # Then launch the terminal
        Start-Process -FilePath $terminal.Path -ArgumentList "/portable"
        
        Write-Host "Terminal launched!" -ForegroundColor Green
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-EnvironmentMenu
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Launch-EnvironmentMetaTrader
    }
}

function Open-FrameworkFolder {
    Start-Process "explorer.exe" -ArgumentList $script:BasePath
    
    if ($script:MenuLevel -eq "Main") {
        Show-MainMenu
    } else {
        Show-EnvironmentMenu
    }
}

# Main Program Logic
if ($Help) {
    Show-Help
    Show-MainMenu
} else {
    Show-MainMenu
}

while ($true) {
    $key = Read-Host
    
    if ($key -eq "q" -or $key -eq "Q") {
        exit
    }
    
    if ($script:MenuLevel -eq "Main") {
        switch ($key) {
            "1" { Show-EnvironmentSelection }
            "2" { Create-NewEnvironment }
            "3" { Launch-MetaTrader }
            "4" { Open-FrameworkFolder }
            "5" { Show-Help; Show-MainMenu }
            default { Show-MainMenu }
        }
    } elseif ($script:MenuLevel -eq "Environment") {
        if ($key -eq "b" -or $key -eq "B") {
            Show-MainMenu
            continue
        }
        
        switch ($key) {
            "1" { Build-Strategy }
            "2" { Open-StrategyFolder }
            "3" { Create-NewStrategy }
            "4" { Sync-WithMetaTrader }
            "5" { Launch-EnvironmentMetaTrader }
            default { Show-EnvironmentMenu }
        }
    }
}