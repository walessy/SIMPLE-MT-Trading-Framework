@echo off
echo Sync Script for test (Basic Mode)
echo =======================================
echo.

set DEV_PATH=C:\Trading\MTFramework\Dev\test
set MT4_PATH=C:\Trading\MTFramework\MT4
set MT5_PATH=C:\Trading\MTFramework\MT5

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