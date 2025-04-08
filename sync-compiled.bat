@echo off
setlocal enabledelayedexpansion

echo Sync Script for test (Basic Mode)
echo =======================================
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

echo Syncing compiled files back to development environment...
echo.

if exist "%MT4_PATH%" (
    echo Syncing MT4 files...
    mkdir "%DEV_PATH%\build\mt4" 2>nul
    set "FOUND_FILES=no"
    
    for /d %%b in ("%MT4_PATH%\*") do (
        if exist "%%b\MQL4\Experts\" (
            for /r "%%b\MQL4\Experts" %%f in (*.ex4) do (
                echo Copying: %%~nxf from %%~nxb
                copy "%%f" "%DEV_PATH%\build\mt4\" >nul 2>&1
                if errorlevel 1 (
                    echo  - Failed to copy %%~nxf
                ) else (
                    echo  - Successfully copied %%~nxf
                    set "FOUND_FILES=yes"
                )
            )
        )
    )
    
    if "%FOUND_FILES%"=="no" (
        echo No compiled MT4 files found. Make sure to compile your strategies in MetaTrader first.
    )
) else (
    echo MT4 directory not found at: %MT4_PATH%
)

if exist "%MT5_PATH%" (
    echo Syncing MT5 files...
    mkdir "%DEV_PATH%\build\mt5" 2>nul
    set "FOUND_FILES=no"
    
    for /d %%b in ("%MT5_PATH%\*") do (
        if exist "%%b\MQL5\Experts\" (
            for /r "%%b\MQL5\Experts" %%f in (*.ex5) do (
                echo Copying: %%~nxf from %%~nxb
                copy "%%f" "%DEV_PATH%\build\mt5\" >nul 2>&1
                if errorlevel 1 (
                    echo  - Failed to copy %%~nxf
                ) else (
                    echo  - Successfully copied %%~nxf
                    set "FOUND_FILES=yes"
                )
            )
        )
    )
    
    if "%FOUND_FILES%"=="no" (
        echo No compiled MT5 files found. Make sure to compile your strategies in MetaTrader first.
    )
) else (
    echo MT5 directory not found at: %MT5_PATH%
)

echo.
if exist "%DEV_PATH%\build\mt4\*.ex4" (
    echo MT4 compiled files were successfully synced.
)
if exist "%DEV_PATH%\build\mt5\*.ex5" (
    echo MT5 compiled files were successfully synced.
)
if not exist "%DEV_PATH%\build\mt4\*.ex4" if not exist "%DEV_PATH%\build\mt5\*.ex5" (
    echo No compiled files were found. Please make sure to:
    echo 1. Copy your strategy files to MetaTrader using the build script
    echo 2. Open MetaTrader and compile your strategies by pressing F7
    echo 3. Then run this sync script again
)

echo.
pause