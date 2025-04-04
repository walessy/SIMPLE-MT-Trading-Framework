# Step-by-Step Verification Guide

This document provides detailed instructions to set up, run, test, and deploy the example strategy to verify that your MT Trading Framework is functioning correctly.

## Prerequisites

Before starting, ensure you have:

- PowerShell 5.1 or later
- Docker Desktop installed
- Git installed
- Administrator privileges on your computer

## 1. Initial Setup

### 1.1. Download the Framework Files

1. Create a folder for the framework files:
   ```
   mkdir C:\MT-Framework-Verification
   cd C:\MT-Framework-Verification
   ```

2. Download or copy all the framework files to this directory.

### 1.2. Run the Setup Script

1. Open PowerShell as Administrator
2. Navigate to the framework directory:
   ```powershell
   cd C:\MT-Framework-Verification
   ```

3. Run the setup script with a development environment name:
   ```powershell
   .\MTSetup.ps1 -DevEnvironmentName "TestStrategy"
   ```

4. Wait for the script to finish. It will:
   - Create directories
   - Download and install MT4/MT5
   - Set up Git repository
   - Set up Docker environment
   - Create the TestStrategy development environment
   - Create desktop shortcuts

### 1.3. Verify Directory Structure

Check that the following directories have been created:
- `C:\Trading\MTFramework\` (base directory)
- `C:\Trading\MTFramework\MT4\`
- `C:\Trading\MTFramework\MT5\`
- `C:\Trading\MTFramework\Dev\TestStrategy\`
- `C:\Trading\MTFramework\src\`
- `C:\Trading\MTFramework\build\`

## 2. Build the Example Strategy

### 2.1. Copy the Example Files

1. Copy the example files to the development environment source directory:
   ```powershell
   Copy-Item "C:\MT-Framework-Verification\SampleStrategy.mq4" -Destination "C:\Trading\MTFramework\Dev\TestStrategy\src\strategies\"
   Copy-Item "C:\MT-Framework-Verification\SampleStrategy.mq5" -Destination "C:\Trading\MTFramework\Dev\TestStrategy\src\strategies\"
   Copy-Item "C:\MT-Framework-Verification\Utils.mqh" -Destination "C:\Trading\MTFramework\Dev\TestStrategy\src\include\"
   ```

### 2.2. Run the Build Process

There are two ways to build the example:

#### Option 1: Using the Desktop Shortcut
1. Find and double-click the "Build TestStrategy Environment" shortcut on your desktop.
2. Watch the build process run in the Docker container.
3. Wait for the "Build complete!" message.

#### Option 2: Using the Build Script Directly
1. Navigate to the development environment:
   ```powershell
   cd "C:\Trading\MTFramework\Dev\TestStrategy"
   ```

2. Run the build script:
   ```powershell
   .\build.bat
   ```

### 2.3. Verify Build Results

Check that the compiled files were created:
1. Look for `SampleStrategy.ex4` in `C:\Trading\MTFramework\Dev\TestStrategy\build\mt4\`
2. Look for `SampleStrategy.ex5` in `C:\Trading\MTFramework\Dev\TestStrategy\build\mt5\`
3. Verify that the include directory was copied to both build folders

## 3. Test the Strategy in MetaTrader

### 3.1. Open MetaTrader

1. Find and click the desktop shortcut for "TestStrategy - AfterPrime MT4" (or MT5, depending on which you want to test).
2. MetaTrader should open in portable mode.

### 3.2. Copy the Compiled Files to MetaTrader

MT4:
1. In the MT4 Navigator panel, right-click on "Expert Advisors"
2. Select "Open Folder"
3. Copy the `SampleStrategy.ex4` file from `C:\Trading\MTFramework\Dev\TestStrategy\build\mt4\` to this folder

MT5:
1. In the MT5 Navigator panel, right-click on "Expert Advisors"
2. Select "Open Folder"
3. Copy the `SampleStrategy.ex5` file from `C:\Trading\MTFramework\Dev\TestStrategy\build\mt5\` to this folder

### 3.3. Copy the Include Files

MT4:
1. In the MT4 Navigator panel, right-click on "Include"
2. Select "Open Folder"
3. Copy the `Utils.mqh` file from `C:\Trading\MTFramework\Dev\TestStrategy\build\mt4\include\` to this folder

MT5:
1. In the MT5 Navigator panel, right-click on "Include"
2. Select "Open Folder"
3. Copy the `Utils.mqh` file from `C:\Trading\MTFramework\Dev\TestStrategy\build\mt5\include\` to this folder

### 3.4. Refresh the Navigator

1. In the Navigator panel, right-click and select "Refresh" to see the new files.
2. The "SampleStrategy" should now appear under "Expert Advisors".

### 3.5. Run the Strategy Tester

MT4:
1. Press Ctrl+R to open the Strategy Tester
2. Select "SampleStrategy" from the Expert Advisor dropdown
3. Select a currency pair (e.g., "EURUSD")
4. Choose a time period (e.g., "H1")
5. Select a date range for testing
6. Click "Start" to run the test

MT5:
1. Press Ctrl+R to open the Strategy Tester
2. Select "SampleStrategy" from the Expert Advisor dropdown
3. Select a currency pair (e.g., "EURUSD")
4. Choose a time period (e.g., "H1")
5. Select a date range for testing
6. Click "Start" to run the test

### 3.6. Verify Test Results

1. Check that the test completes without errors
2. Verify that trades were opened and closed
3. Look at the "Graph" tab to see the equity curve
4. Check the "Report" tab for detailed statistics

## 4. Modify and Rebuild the Strategy

### 4.1. Make a Simple Modification

1. Navigate to the strategy source file:
   ```
   C:\Trading\MTFramework\Dev\TestStrategy\src\strategies\SampleStrategy.mq4
   ```

2. Open it in a text editor and make a simple change, such as modifying the default MA period:
   ```
   // Change this line:
   input int MAPeriod = 20;
   
   // To this:
   input int MAPeriod = 50;
   ```

3. Save the file.

### 4.2. Rebuild the Modified Strategy

1. Run the build script again:
   ```powershell
   cd "C:\Trading\MTFramework\Dev\TestStrategy"
   .\build.bat
   ```

2. Verify that the compilation succeeds.

### 4.3. Test the Modified Strategy

1. Copy the new `SampleStrategy.ex4` to the MT4 "Experts" folder (as in step 3.2)
2. Run the Strategy Tester again (as in step 3.5)
3. Confirm that the behavior is different with the new parameter value

## 5. Version Control Integration

### 5.1. Check Git Status

1. Navigate to the framework directory:
   ```powershell
   cd C:\Trading\MTFramework
   ```

2. Check the status of the Git repository:
   ```powershell
   git status
   ```

3. You should see the modified strategy files listed.

### 5.2. Commit Your Changes

1. Add the changes to the staging area:
   ```powershell
   git add .
   ```

2. Commit the changes:
   ```powershell
   git commit -m "Modified MA period in SampleStrategy"
   ```

3. Verify the commit was successful:
   ```powershell
   git log
   ```

## 6. Deploy to Production

### 6.1. Copy to Production Terminals

1. Navigate to the build directory:
   ```powershell
   cd "C:\Trading\MTFramework\Dev\TestStrategy\build\mt4"
   ```

2. Copy the compiled files to the production MT4 terminal:
   ```powershell
   Copy-Item "SampleStrategy.ex4" -Destination "C:\Trading\MTFramework\MT4\AfterPrime\experts\"
   Copy-Item "include\Utils.mqh" -Destination "C:\Trading\MTFramework\MT4\AfterPrime\MQL4\Include\"
   ```

3. Repeat for MT5 if needed.

### 6.2. Test in Production Environment

1. Open the production MT4 terminal using the desktop shortcut for "AfterPrime MT4" (without the "TestStrategy -" prefix)
2. Verify that the strategy appears in the Navigator panel
3. Run a quick backtest to confirm it works correctly

## 7. Create a New Development Environment

### 7.1. Create Another Development Environment

1. Run the setup script with a new environment name:
   ```powershell
   .\MTSetup.ps1 -DevEnvironmentName "NewStrategy" -SkipMT4 -SkipMT5
   ```

2. The script will create a new development environment without reinstalling MT4/MT5.

### 7.2. Verify the New Environment

1. Check that the new directory structure was created:
   ```
   C:\Trading\MTFramework\Dev\NewStrategy\
   ```

2. Verify that the sample files were created in this environment.

## Troubleshooting

### Docker Build Issues

If the Docker build fails:
1. Ensure Docker Desktop is running
2. Check your Docker installation with `docker --version`
3. Look at the error message in the console
4. Check for syntax errors in the MQL files

### MT4/MT5 Installation Issues

If MetaTrader installation fails:
1. Try downloading the installer manually
2. Run the installer directly
3. Check for administrative permissions

### Compilation Errors

If compilation fails:
1. Check the log files in the build directory
2. Look for syntax errors in the modified code
3. Ensure Docker is running correctly

### Git Issues

If Git operations fail:
1. Check if Git is installed properly
2. Ensure you're in the correct directory
3. Look for detailed error messages

## Conclusion

If you've successfully completed all these steps, your MT Trading Framework is verified and ready for use. You can now:

1. Create multiple development environments
2. Build and test strategies in isolation
3. Use Docker for consistent builds
4. Track changes with Git
5. Deploy to production terminals

This verification process confirms that all key components of the framework are functioning correctly.