@echo off
setlocal enabledelayedexpansion

echo Simple Build Script for test (Basic Mode)
echo ==============================================
echo.

REM Get the script's directory to determine paths dynamically
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Extract the base directory (parent of Dev)
for %%i in ("%SCRIPT_DIR%\..\..") do set "BASE_DIR=%%~fi"

REM Set paths dynamically based on the script location
set "DEV_PATH=%SCRIPT_DIR%"
set "MT4_PATH=%BASE_DIR%\MT4"
set "MT5_PATH=%BASE_DIR%\MT5"

echo Detected paths:
echo - Base Directory: %BASE_DIR%
echo - Development Path: %DEV_PATH%
echo - MT4 Path: %MT4_PATH%
echo - MT5 Path: %MT5_PATH%
echo.

echo Building using MetaTrader compilers...
echo.

if exist "%MT4_PATH%" (
    echo Building MT4 files...
    for /r "%DEV_PATH%\src\strategies" %%f in (*.mq4) do (
        echo Processing: %%~nxf
        mkdir "%DEV_PATH%\build\mt4" 2>nul
        
        REM Find all MT4 broker directories and copy to each
        set "FOUND_TARGET=false"
        for /d %%b in ("%MT4_PATH%\*") do (
            if exist "%%b\MQL4\Experts\" (
                echo Copying to %%~nxb MT4...
                copy "%%f" "%%b\MQL4\Experts\" >nul 2>&1
                if errorlevel 1 (
                    echo  - Failed to copy to %%~nxb
                ) else (
                    echo  - Copied successfully to %%~nxb
                    set "FOUND_TARGET=true"
                )
            )
        )
        
        if "!FOUND_TARGET!"=="false" (
            echo  - No valid MT4 broker folders found with MQL4\Experts directory
        )
    )
) else (
    echo MT4 directory not found at: %MT4_PATH%
)

if exist "%MT5_PATH%" (
    echo Building MT5 files...
    for /r "%DEV_PATH%\src\strategies" %%f in (*.mq5) do (
        echo Processing: %%~nxf
        mkdir "%DEV_PATH%\build\mt5" 2>nul
        
        REM Find all MT5 broker directories and copy to each
        set "FOUND_TARGET=false"
        for /d %%b in ("%MT5_PATH%\*") do (
            if exist "%%b\MQL5\Experts\" (
                echo Copying to %%~nxb MT5...
                copy "%%f" "%%b\MQL5\Experts\" >nul 2>&1
                if errorlevel 1 (
                    echo  - Failed to copy to %%~nxb
                ) else (
                    echo  - Copied successfully to %%~nxb
                    set "FOUND_TARGET=true"
                )
            )
        )
        
        if "!FOUND_TARGET!"=="false" (
            echo  - No valid MT5 broker folders found with MQL5\Experts directory
        )
    )
) else (
    echo MT5 directory not found at: %MT5_PATH%
)

echo.
echo Files copied to MetaTrader folders.
echo.
echo IMPORTANT: 
echo To complete compilation, please open each MetaTrader terminal,
echo navigate to your strategy in the Navigator panel, and press F7 
echo or right-click and select "Compile".
echo.
echo After compilation, run the Sync script to copy the compiled files 
echo back to your development environment.
echo.
pause