[CmdletBinding()]
param (
    [string]$BasePath = "C:\Trading\MTFramework",
    [string]$ConfigPath = "C:\Projetcs\SIMPLE MT-Trading-Framework\config.json",
    [string]$CollectionName = "coll1",
    [string]$MT4BrokerName = "afterprime",
    [string]$MT5BrokerName = "afterprime",
    [string]$StrategyName = "DefaultStrategy"
)

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

# Helper Function
function Write-Status { param ([string]$Message, [string]$Color = "Yellow") Write-Host $Message -ForegroundColor $Color }

function Cleanup-Environment {
    param (
        [string]$BasePath,
        [string]$ConfigPath,
        [string]$CollectionName,
        [string]$MT4BrokerName,
        [string]$MT5BrokerName,
        [string]$StrategyName
    )

    Write-Status "Starting cleanup of MT Trading Framework environment..." "Cyan"

    # Delete the config.json file
    if (Test-Path $ConfigPath) {
        Remove-Item -Path $ConfigPath -Force -ErrorAction SilentlyContinue
        Write-Status "Removed config file: $ConfigPath" "Green"
    } else {
        Write-Status "Config file not found at: $ConfigPath" "Yellow"
    }

    # Delete the MT4 collection folder
    $mt4CollectionPath = Join-Path -Path $BasePath -ChildPath "MT4\$MT4BrokerName\$CollectionName"
    if (Test-Path $mt4CollectionPath) {
        Remove-Item -Path $mt4CollectionPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "Removed MT4 collection folder: $mt4CollectionPath" "Green"
    } else {
        Write-Status "MT4 collection folder not found at: $mt4CollectionPath" "Yellow"
    }

    # Delete the MT5 collection folder
    $mt5CollectionPath = Join-Path -Path $BasePath -ChildPath "MT5\$MT5BrokerName\$CollectionName"
    if (Test-Path $mt5CollectionPath) {
        Remove-Item -Path $mt5CollectionPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "Removed MT5 collection folder: $mt5CollectionPath" "Green"
    } else {
        Write-Status "MT5 collection folder not found at: $mt5CollectionPath" "Yellow"
    }

    # Clean up Desktop shortcuts
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    
    # Clean up MT4 shortcuts in the MT4 broker folder
    $mt4BrokerFolder = Join-Path -Path $desktopPath -ChildPath $MT4BrokerName
    if (Test-Path $mt4BrokerFolder) {
        $mt4Shortcuts = Get-ChildItem -Path $mt4BrokerFolder -Filter "MT4 - $MT4BrokerName [$CollectionName-$StrategyName]*.lnk" -ErrorAction SilentlyContinue
        if ($mt4Shortcuts) {
            foreach ($shortcut in $mt4Shortcuts) {
                Remove-Item -Path $shortcut.FullName -Force -ErrorAction SilentlyContinue
                Write-Status "Removed MT4 shortcut: $($shortcut.Name)" "Green"
            }
            # Remove the broker folder if it's empty
            if (-not (Get-ChildItem -Path $mt4BrokerFolder)) {
                Remove-Item -Path $mt4BrokerFolder -Force -ErrorAction SilentlyContinue
                Write-Status "Removed empty MT4 broker folder: $mt4BrokerFolder" "Green"
            }
        } else {
            Write-Status "No MT4 shortcuts found in: $mt4BrokerFolder" "Yellow"
        }
    } else {
        Write-Status "MT4 broker folder not found at: $mt4BrokerFolder" "Yellow"
    }

    # Clean up MT5 shortcuts in the MT5 broker folder
    $mt5BrokerFolder = Join-Path -Path $desktopPath -ChildPath $MT5BrokerName
    if (Test-Path $mt5BrokerFolder) {
        $mt5Shortcuts = Get-ChildItem -Path $mt5BrokerFolder -Filter "MT5 - $MT5BrokerName [$CollectionName-$StrategyName]*.lnk" -ErrorAction SilentlyContinue
        if ($mt5Shortcuts) {
            foreach ($shortcut in $mt5Shortcuts) {
                Remove-Item -Path $shortcut.FullName -Force -ErrorAction SilentlyContinue
                Write-Status "Removed MT5 shortcut: $($shortcut.Name)" "Green"
            }
            # Remove the broker folder if it's empty
            if (-not (Get-ChildItem -Path $mt5BrokerFolder)) {
                Remove-Item -Path $mt5BrokerFolder -Force -ErrorAction SilentlyContinue
                Write-Status "Removed empty MT5 broker folder: $mt5BrokerFolder" "Green"
            }
        } else {
            Write-Status "No MT5 shortcuts found in: $mt5BrokerFolder" "Yellow"
        }
    } else {
        Write-Status "MT5 broker folder not found at: $mt5BrokerFolder" "Yellow"
    }

    Write-Status "Cleanup completed." "Green"
}

# Execute cleanup
Cleanup-Environment -BasePath $BasePath -ConfigPath $ConfigPath -CollectionName $CollectionName -MT4BrokerName $MT4BrokerName -MT5BrokerName $MT5BrokerName -StrategyName $StrategyName