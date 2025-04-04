# MT Trading Framework User Levels

The MT Trading Framework supports two different user levels, each with different capabilities and requirements.

## Basic User (No Docker Required)

### Who is this for?
- Traders who want to write and test strategies
- Users who prefer a simple setup with minimal technical requirements
- Beginners who are just getting started with algorithmic trading

### Requirements
- Windows computer
- PowerShell (comes with Windows)
- Basic knowledge of MQL4/MQL5 language
- MetaTrader 4 and/or MetaTrader 5 installed

### Setup
1. Install MetaTrader 4 and/or MetaTrader 5 using the standard installation process
2. Run `Easy-Setup.ps1` and select the Basic mode
3. Follow the prompts to set up your environment
4. No Docker installation required

### How it works
- The framework creates containerized copies of your existing MetaTrader installations
- These containers run in portable mode, keeping your development separate from main installations
- Strategy files are edited directly in your development environment
- Compilation is done using MetaTrader's compiler
- Sync script transfers files between development and containerized MetaTrader
- All operations are managed through the user-friendly dashboard

### Limitations
- Compilation process is slightly slower
- Requires MetaTrader installation on the same computer
- Some advanced build options not available

## Advanced User (Docker-Based)

### Who is this for?
- Professional developers
- Users who want maximum control and consistency
- Teams working on multiple strategies

### Requirements
- Windows, Mac, or Linux computer
- Docker Desktop installed
- Git installed
- Knowledge of MQL4/MQL5 language
- MetaTrader 4 and/or MetaTrader 5 installed (on Windows)

### Setup
1. Install MetaTrader 4 and/or MetaTrader 5 using the standard installation process
2. Ensure Docker Desktop is running
3. Run `Easy-Setup.ps1` and select the Advanced mode
4. Follow the prompts to set up your environment

### How it works
- The framework creates containerized copies of your existing MetaTrader installations
- These containers run in portable mode, keeping your development separate from main installations
- Strategy files are edited in your development environment
- Compilation is done in a Docker container for consistency
- Sync script transfers files between development and containerized MetaTrader
- Build process works the same across different computers

### Advantages
- Consistent build environment regardless of host OS
- Faster compilation for multiple files
- Better support for automated build pipelines
- No dependency on MetaTrader installation for compilation (after initial setup)

## Choosing the Right Level

### Choose Basic if:
- You're new to algorithmic trading
- You prefer simplicity over advanced features
- You don't want to install Docker
- You only use Windows

### Choose Advanced if:
- You work on multiple computers or operating systems
- You're part of a team developing strategies
- You want the fastest, most consistent build process
- You already use Docker for other projects

## Switching Between Levels

You can switch between levels at any time:

### From Basic to Advanced:
1. Install Docker Desktop
2. Run `.\MTSetup.ps1 -ConfigureDocker` to set up the Docker environment
3. Use the dashboard or build scripts as normal

### From Advanced to Basic:
1. No special steps needed
2. Just use the MetaTrader compilation options instead of Docker

## Feature Comparison

| Feature | Basic User | Advanced User |
|---------|------------|--------------|
| Strategy Development | ✓ | ✓ |
| Strategy Testing | ✓ | ✓ |
| File Synchronization | ✓ | ✓ |
| Version Control | ✓ | ✓ |
| Dashboard Interface | ✓ | ✓ |
| Multiple Environments | ✓ | ✓ |
| Docker Compilation | ✗ | ✓ |
| Cross-Platform Support | ✗ | ✓ |
| Build Automation | Limited | Full |
| Build Speed | Standard | Faster |
| Consistency Across Machines | ✗ | ✓ |