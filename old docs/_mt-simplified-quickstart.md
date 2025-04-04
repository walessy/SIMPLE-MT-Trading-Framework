# Quick Start Guide - MT Trading Framework

This guide will help you get started with the MT Trading Framework quickly.

## Installation (5 Minutes)

1. **Download the Files**
   
   Clone the repository or download the files to your computer.

2. **Run the Setup Script**
   
   Open PowerShell as Administrator and run:
   ```powershell
   .\MTSetup.ps1
   ```

3. **Create a Development Environment**
   
   During setup, specify a development environment name:
   ```powershell
   .\MTSetup.ps1 -DevEnvironmentName "MyStrategy"
   ```

4. **Start Developing**
   
   You can now use the desktop shortcuts to:
   - Open the MetaTrader terminals
   - Build your MQL code

## Development Workflow

### 1. Write Your Code

Navigate to your development environment's source directory:
```
C:\Trading\MTFramework\Dev\MyStrategy\src\strategies
```

Create or edit your `.mq4` or `.mq5` files here.

### 2. Build Your Code

Double-click the "Build MyStrategy Environment" shortcut on your desktop, or run:
```
C:\Trading\MTFramework\Dev\MyStrategy\build.bat
```

This will compile your code using Docker and output the compiled files to the build directory.

### 3. Test Your Strategy

Open the MetaTrader terminal using the desktop shortcut and test your strategy in the Strategy Tester.

### 4. Version Control

Your framework already has Git initialized. Use standard Git commands:

```bash
# Check status
git status

# Add changes
git add .

# Commit changes
git commit -m "Added my strategy"

# Create a branch
git checkout -b feature/new-strategy
```

## Next Steps

- **Add More Brokers**: Edit the `$Config.DefaultBrokers` section in the MTSetup.ps1 script.
- **Customize Docker**: Modify the Dockerfile or docker-compose.yml for advanced customization.
- **Implement CI/CD**: Set up continuous integration for automated testing.