# MT Trading Framework Test Documentation

This document outlines the test scripts designed to verify the features and functionality of the MT Trading Framework setup, specifically the MTSetup.ps1 script and its integration with Docker for both Basic (Option 1) and Advanced (Option 2) modes. The tests ensure directory structure consistency, file creation, Docker-based compilation, shortcut generation, and support for both MT4 and MT5 platforms.

## Overview

The test suite includes three PowerShell scripts:

1. **Test-BasicMode.ps1**: Validates Basic mode, where Docker is skipped, focusing on directory structure and sample file creation without compilation.
2. **Test-AdvancedMode.ps1**: Tests Advanced mode, where Docker is used, verifying setup, compilation, and full functionality.
3. **Test-MT5Support.ps1**: Confirms MT5-specific features in Advanced mode, including compilation of MT5-specific files.

Each script simulates a realistic setup, runs the MTSetup.ps1 script with appropriate parameters, and checks the results against expected outcomes.

## Prerequisites

- **Operating System**: Windows with PowerShell installed.
- **Software**: Docker Desktop must be installed and running.
- **Files**: The test directory (e.g., C:\Trading) must contain MTSetup.ps1, Dockerfile, docker-compose.yml, and a scripts subdirectory with build_mt4.sh and build_mt5.sh.
- **Test Scripts**: The three test scripts should be saved in the same directory as the above files.
- **Permissions**: PowerShell must be run as Administrator to avoid permission-related issues.

## Test Scripts

### 1. Test-BasicMode.ps1

#### Purpose

This test verifies Basic mode (Option 1) of MTSetup.ps1, ensuring that the script correctly sets up an MT4 installation, creates the expected directory structure with sample files, and generates a desktop shortcut, all without involving Docker.

#### Features Tested

- **Install-MetaTrader**: Checks that the MT4 terminal executable is copied to the target directory.
- **Setup-Strategy-Folders**: Ensures the MQL4 directory structure (Experts, Indicators, Scripts, Libraries, Include, Files, Images) and Templates directory are created with sample MT4 files.
- **Create-Shortcut**: Confirms a desktop shortcut for MT4 is created in a broker-specific folder.

#### Expected Outcomes

- The MT4 installation directory is created with a terminal executable and an origin.ini file enabling portable mode.
- MQL4 subdirectories exist, each containing a sample MT4 file (e.g., .mq4 for Experts, Indicators, Scripts, Libraries; .mqh for Include; .txt for Files and Images).
- A Templates directory exists at the root level with a sample template file.
- No compiled files (e.g., .ex4) are present, as compilation is skipped in Basic mode.
- A shortcut is created on the desktop in a folder matching the broker name.

### 2. Test-AdvancedMode.ps1

#### Purpose

This test validates Advanced mode (Option 2) of MTSetup.ps1, ensuring that the script sets up an MT4 installation, creates the directory structure with sample files, uses Docker to compile MT4 files, and generates a desktop shortcut, all as a standalone process.

#### Features Tested

- **Install-MetaTrader**: Verifies the MT4 terminal executable is correctly installed.
- **Setup-Strategy-Folders**: Confirms the MQL4 directory structure and Templates directory are created with sample files.
- **Setup-Docker**: Ensures Docker is set up, including building the mt_builder image.
- **Build-MQLFiles**: Checks that MT4 files are compiled into executable formats using Docker.
- **Create-Shortcut**: Validates the creation of an MT4 desktop shortcut.

#### Expected Outcomes

- The MT4 installation directory is created with a terminal executable and an origin.ini file.
- MQL4 subdirectories contain both source files (e.g., .mq4) and compiled files (e.g., .ex4) for Experts, Indicators, and Scripts.
- Other MQL4 subdirectories (Libraries, Include, Files, Images) and the Templates directory match Basic mode with their respective sample files.
- The Docker image mt_builder is built successfully, though the container stops after compilation.
- A desktop shortcut is created in a broker-specific folder.

### 3. Test-MT5Support.ps1

#### Purpose

This test confirms MT5-specific support in Advanced mode, ensuring that MTSetup.ps1 handles MT5 installations, creates the appropriate directory structure with MT5-specific sample files, compiles those files using Docker, and generates an MT5 desktop shortcut.

#### Features Tested

- **Install-MetaTrader**: Verifies the MT5 terminal executable is installed.
- **Setup-Strategy-Folders**: Ensures the MQL5 directory structure and Templates directory are created with MT5 sample files.
- **Setup-Docker**: Confirms Docker setup for MT5 compilation.
- **Build-MQLFiles**: Validates compilation of MT5 files into executable formats.
- **Create-Shortcut**: Checks for an MT5 desktop shortcut.

#### Expected Outcomes

- The MT5 installation directory contains a terminal executable (terminal64.exe) and an origin.ini file.
- MQL5 subdirectories (Experts, Indicators, Scripts) contain both source files (e.g., .mq5) and compiled files (e.g., .ex5).
- Other MQL5 subdirectories (Libraries, Include, Files, Images) and the Templates directory contain their respective sample files.
- The Docker-based compilation succeeds, producing MT5 executable files.
- A desktop shortcut for MT5 is created in a broker-specific folder.

## Running the Tests

### Instructions

1. **Prepare Environment**:
   - Ensure Docker Desktop is running.
   - Place all required files in a directory (e.g., C:\Trading).
   - Save the test scripts in the same directory.

2. **Execute Tests**:
   - Open PowerShell as Administrator.
   - Navigate to the test directory with: `cd C:\Trading`.
   - Run each test script in sequence:
     - `.\Test-BasicMode.ps1`
     - `.\Test-AdvancedMode.ps1`
     - `.\Test-MT5Support.ps1`

3. **Review Output**:
   - Look for "PASS" messages in green for successful checks.
   - "FAIL" messages in red indicate issues, with details provided for diagnosis.
   - Each test cleans up after itself, removing temporary directories and Docker resources.

## Expected Outcomes

- All tests should output "PASS" for each verification step if the framework is functioning correctly.
- Basic mode produces a structure with source files only, while Advanced mode includes compiled files.
- MT5 support mirrors MT4 functionality but with MT5-specific files.

## Troubleshooting

- **Docker Issues**:
  - Verify Docker Desktop is running.
  - Check logs with: `docker-compose -f C:\TradingTest\docker-compose.yml logs`.
  - Ensure internet access for Docker image builds.
- **Missing Files**:
  - Confirm all required files are in the test directory.
  - Review test output for specific missing paths.
- **Permission Problems**:
  - Run PowerShell as Administrator.
- **Compilation Failures**:
  - Manually test Docker: Navigate to C:\TradingTest, run `docker-compose up`, then `docker-compose exec mt_builder bash`, and execute `build_mt4` or `build_mt5`.

## Customization

If your setup includes additional features (e.g., custom parameters or files), the test scripts may need adjustment. Provide details on any deviations from the standard setup, and the tests can be tailored accordingly.
