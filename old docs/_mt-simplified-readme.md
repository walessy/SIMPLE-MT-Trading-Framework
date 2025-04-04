# MT Trading Framework

A simplified framework for MetaTrader 4/5 development, testing, and deployment.

## Overview

This framework provides a structured approach to:
- Installing and managing MT4/MT5 terminals
- Creating development environments
- Building MQL code using Docker
- Version control with Git

## Getting Started

### Quick Setup

Run the main setup script with default options:

```powershell
.\MTSetup.ps1
```

This will:
1. Create the directory structure
2. Install default MT4/MT5 terminals
3. Set up Git repository
4. Configure Docker build environment
5. Create desktop shortcuts

### Custom Setup

You can customize the setup with various parameters:

```powershell
.\MTSetup.ps1 -BasePath "D:\Trading" -SkipMT4 -DevEnvironmentName "MyStrategy"
```

Available parameters:
- `-BasePath`: Custom location for the framework
- `-SkipMT4`: Skip MT4 installation
- `-SkipMT5`: Skip MT5 installation
- `-SkipGit`: Skip Git repository setup
- `-SkipDocker`: Skip Docker build environment setup
- `-DevEnvironmentName`: Create a development environment
- `-Help`: Display help message

## Directory Structure

```
MTFramework/
├── BrokerPackages/   # Broker installer files
├── MT4/              # MT4 installations
├── MT5/              # MT5 installations
├── Dev/              # Development environments
│   └── MyStrategy/   # Example dev environment
│       ├── src/      # MQL source code
│       └── build/    # Compiled files
├── Test/             # Testing environments
├── src/              # Global source code
├── build/            # Global build output
├── scripts/          # Build scripts
├── Dockerfile        # Docker configuration
└── docker-compose.yml
```

## Development Workflow

### Create a Development Environment

```powershell
.\MTSetup.ps1 -DevEnvironmentName "MyStrategy"
```

This creates a new development environment with:
- Source directories for strategies, indicators, libraries
- Sample MT4/MT5 strategy files
- Build directories
- Desktop shortcuts for terminals and build

### Develop Your Strategy

1. Write your MQL4/5 code in the development environment's `src` directory
2. Use the desktop shortcuts to open the MetaTrader terminals
3. Test your strategy in the MetaTrader Strategy Tester

### Build Your Strategy

Use the desktop shortcut "Build MyStrategy Environment" or run the batch file directly:

```
Dev\MyStrategy\build.bat
```

This will:
1. Start the Docker container
2. Compile all MQL4/5 files in the src directory
3. Output the compiled files to the build directory

### Version Control

The framework automatically sets up a Git repository with:
- `.gitignore` configured for MetaTrader files
- Main and develop branches

Use standard Git commands for version control:

```
git add .
git commit -m "Added new strategy"
git push
```

## Maintenance

### Add New Brokers

Edit the `$Config.DefaultBrokers` section in the MTSetup.ps1 script to add more brokers:

```powershell
$Config = @{
    DefaultBrokers = @(
        @{
            Version = "MT4"
            BrokerName = "NewBroker"
            InstallerUrl = "https://download.broker.com/mt4setup.exe"
        }
    )
}
```

Then run the setup script again with the `-ForceReinstall` flag:

```powershell
.\MTSetup.ps1 -ForceReinstall
```

### Updating the Framework

Simply download the latest version and run the setup script again. It will:
- Preserve existing installations
- Update configuration files
- Set up any new features

## Troubleshooting

### Docker Build Issues

If the Docker build fails:
1. Ensure Docker Desktop is running
2. Check your MQL syntax
3. Look at the error logs in the build directory
4. Verify Docker is properly installed with `docker --version`

### MT4/MT5 Installation Issues

If MT4/MT5 installation fails:
1. Check if the broker's installer is accessible
2. Try downloading the installer manually
3. Run the installer directly
4. Make sure you have admin rights

### Git Issues

If Git operations fail:
1. Ensure Git is installed and in your PATH
2. Check if Git LFS is needed for binary files
3. Verify your Git credentials are set up correctly