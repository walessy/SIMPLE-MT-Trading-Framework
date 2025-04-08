# MT Trading Framework

A comprehensive framework for developing, testing, and deploying MetaTrader 4 and MetaTrader 5 trading strategies with proper version control, containerization, and structured organization.

## Overview

The MT Trading Framework provides a structured environment for algorithmic trading development with MetaTrader platforms. It offers:

- **Strategy Organization**: Clear structure for collections of trading strategies
- **Containerized Environments**: Isolated, portable MetaTrader installations
- **Version Control**: Git integration with appropriate settings for MQL projects
- **Workflow Automation**: Scripts for common development tasks
- **Dual User Levels**: Basic mode (no Docker) and Advanced mode (with Docker)
- **Docker Support**: Advanced containerization for consistent builds (optional)

## Features

- **Platform Support**: Works with both MT4 and MT5
- **Multi-Broker Management**: Support for multiple brokers simultaneously
- **Portable Installations**: Self-contained MetaTrader environments
- **Strategy Collections**: Organize related strategies into logical groups
- **Git LFS Integration**: Proper handling of binary files in version control
- **Flexible User Levels**: Choose between Basic mode (no Docker) and Advanced mode (with Docker)
- **Docker-Based Compilation**: Consistent builds across environments (advanced mode)
- **Automatic File Organization**: Structured folders for all trading components

## Quick Start

### Prerequisites

- Windows operating system
- MetaTrader 4 and/or MetaTrader 5 installed
- PowerShell 5.0 or later
- Git (optional, for version control)
- Docker Desktop (optional, for advanced mode)

### Basic Installation

1. Clone or download this repository:
   ```
   git clone https://github.com/yourusername/mt-trading-framework.git
   ```

2. Run the Easy Setup script as Administrator:
   ```
   Right-click Easy-Setup.ps1 -> Run with PowerShell (Admin)
   ```

3. Follow the prompts to configure your environment:
   - Select MetaTrader version (MT4, MT5, or both)
   - Enter broker names
   - Choose setup mode:
     - **Basic Mode**: No Docker required, simpler setup
     - **Advanced Mode**: Uses Docker for consistent compilation (requires Docker Desktop)
   - Name your collection and strategy

4. After setup completes, use the created desktop shortcuts to access your MetaTrader environments

See [User Levels](docs/user-levels.md) for a detailed comparison between Basic and Advanced modes.

### Directory Structure

After installation, your framework will be organized as follows:

```
C:\Trading\MTFramework\
├── MT4\
│   └── [BrokerName]\
│       └── [CollectionName]\
│           └── MT4\
│               ├── MQL4\
│               │   ├── Experts\[StrategyName]\
│               │   ├── Indicators\[StrategyName]\
│               │   ├── Scripts\[StrategyName]\
│               │   └── Include\[StrategyName]\
│               └── Templates\[StrategyName]\
├── MT5\
│   └── [BrokerName]\
│       └── [CollectionName]\
│           └── MT5\
│               ├── MQL5\
│               │   ├── Experts\[StrategyName]\
│               │   ├── Indicators\[StrategyName]\
│               │   ├── Scripts\[StrategyName]\
│               │   └── Include\[StrategyName]\
│               └── Templates\[StrategyName]\
├── Dev\
│   └── [CollectionName]\
│       └── build\
│           ├── mt4\
│           └── mt5\
└── Test\
    └── [CollectionName]\
```

## Usage

### Basic Mode Workflow

1. **Create/Edit Strategy**: Use MetaEditor or your preferred editor to modify files in the MQL folders
2. **Compile**: Compile your code using MetaEditor (F7)
3. **Test**: Use Strategy Tester in MetaTrader to test your strategy
4. **Deploy**: Copy your compiled files to production accounts

### Advanced Mode Workflow (with Docker)

1. **Create/Edit Strategy**: Modify MQL source files
2. **Build**: Docker automatically compiles your code
3. **Sync**: Compiled files are synced to your MetaTrader environment
4. **Test**: Run tests in MetaTrader
5. **Deploy**: Push your changes to Git for deployment

### Git Integration

The framework includes proper Git configuration for MetaTrader projects:

- `.gitignore` configured for MetaTrader-specific files
- Git LFS setup for binary files (compiled EX4/EX5 files)
- Appropriate text file handling with EOL settings

To initialize Git:

```bash
# Run from your framework root directory
./Git\ Repository\ Setup\ for\ MT\ Trading\ Framework.txt
```

### Creating a New Strategy

To create a new strategy within an existing collection:

1. Edit your setup parameters in Easy-Setup.ps1
2. Run the script again with the new strategy name
3. Use the generated structure to develop your strategy

## Scripts and Utilities

### Easy-Setup.ps1

Interactive setup script for basic configuration:

```powershell
.\Easy-Setup.ps1
```

### MTSetup.ps1

Advanced configuration script with more options:

```powershell
.\MTSetup.ps1 -BasePath "C:\Trading\MTFramework" -StrategyName "MyStrategy" -CollectionName "MyCollection"
```

### Git Repository Setup

Initialize Git with proper MetaTrader settings:

```bash
./Git\ Repository\ Setup\ for\ MT\ Trading\ Framework.txt
```

## Advanced Configuration

### User Levels

The framework supports two user levels:

- **Basic Mode**: No Docker required, uses MetaTrader's native compiler
- **Advanced Mode**: Docker-based compilation for consistency across environments

To switch between modes:

```powershell
# For Basic Mode
.\Easy-Setup.ps1  # Then select option 1 when prompted

# For Advanced Mode
.\Easy-Setup.ps1  # Then select option 2 when prompted
```

### Multiple Broker Support

The framework supports multiple brokers simultaneously:

```powershell
.\MTSetup.ps1 -MT4BrokerName "Broker1" -MT5BrokerName "Broker2" -StrategyName "MyStrategy" -CollectionName "MyCollection"
```

### Docker Integration

For advanced users, enable Docker-based compilation:

```powershell
.\MTSetup.ps1 -SkipDocker:$false -StrategyName "MyStrategy" -CollectionName "MyCollection"
```

### File Watcher

Automatically sync compiled files:

```powershell
.\MTSetup.ps1 -Watch -StrategyName "MyStrategy" -CollectionName "MyCollection"
```

## Troubleshooting

### Common Issues

- **MetaTrader Not Found**: Ensure your broker name matches exactly or provide explicit paths
- **Compilation Errors**: Check the "Experts" log tab in MetaEditor
- **Docker Errors**: Verify Docker Desktop is running properly
- **Sync Issues**: Ensure MetaTrader is closed during sync operations

### Getting Help

If you encounter issues:

1. Check the documentation in the `docs` folder
2. Review the script's output for error messages
3. Examine the PowerShell scripts to understand the workflow

## Documentation

Additional documentation:

- [User Levels](docs/user-levels.md) - Comparison between Basic and Advanced modes
- [Basic User Guide](docs/basic-user-guide.md) - Guide for users without Docker
- [Advanced User Guide](docs/advanced-user-guide.md) - Docker-based workflow
- [Script Reference](docs/script-reference.md) - Detailed script parameters

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- MetaQuotes for MetaTrader platforms
- The MQL community for inspiration and examples
