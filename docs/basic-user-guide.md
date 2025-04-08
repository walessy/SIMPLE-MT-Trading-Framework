# MT Trading Framework for Basic Users

This guide explains how to use the MT Trading Framework without Docker, ideal for traders who want a simple setup.

## What You Need

- Windows computer
- MetaTrader 4 and/or MetaTrader 5 installed on your computer
- Basic knowledge of MQL4/MQL5 programming

## Getting Started

### 1. Install MetaTrader

Before running the setup script:

1. Download and install MetaTrader 4 and/or MetaTrader 5 using the standard installation process
2. Complete the initial setup of MetaTrader
3. Make sure you can open the MetaTrader terminal normally

### 2. Run the Easy Setup

1. Right-click on `Easy-Setup.ps1` and select "Run with PowerShell (Admin)"
2. Follow the prompts:
   - Select MetaTrader version (MT4, MT5, or both)
   - Enter your broker names
   - Provide installation paths (or let the script auto-detect)
   - Choose "Basic" setup mode (option 1)
   - Enter your collection name (e.g., "coll")
   - Enter your strategy name (e.g., "Amos")

The setup will:
- Locate your existing MetaTrader installations
- Create containerized copies that run in portable mode
- Set up your framework directory structure with collection and strategy organization
- Create desktop shortcuts organized by broker
- Add sample strategy files

### 3. Understanding Your Environment

After setup, you'll have:

- **Framework Root**: `C:\Trading\MTFramework\`
- **MetaTrader Folders**:
  - `C:\Trading\MTFramework\MT4\[BrokerName]\[CollectionName]\MT4\`
  - `C:\Trading\MTFramework\MT5\[BrokerName]\[CollectionName]\MT5\`
- **Strategy Structure**:
  - MQL4/MQL5 folders containing:
    - Experts\[StrategyName]\
    - Indicators\[StrategyName]\
    - Scripts\[StrategyName]\
    - Libraries\[StrategyName]\
    - Include\[StrategyName]\
    - Files\[StrategyName]\
    - Images\[StrategyName]\
  - Templates\[StrategyName]\

- **Desktop Shortcuts**: Located in folders named after your brokers:
  - `MT4 - [BrokerName] [[CollectionName]-[StrategyName]Strategy]`
  - `MT5 - [BrokerName] [[CollectionName]-[StrategyName]Strategy]`

## Development Workflow

### 1. Write Your Strategy

1. Open your containerized MetaTrader terminal using the desktop shortcut
2. Open MetaEditor (F4) to edit your strategy files
3. Navigate to your strategy folder structure:
   - For MT4: `MQL4\Experts\[StrategyName]\`
   - For MT5: `MQL5\Experts\[StrategyName]\`
4. Edit or create new strategy files

Alternatively, you can use your preferred text editor to modify the files directly in the folders.

### 2. Compile Your Strategy

1. In MetaEditor, compile your strategy by pressing F7
2. The compiled files (.ex4 for MT4, .ex5 for MT5) will be created in the same folder

### 3. Test Your Strategy

1. In the MetaTrader terminal, open the Strategy Tester (Ctrl+R)
2. Select your strategy from the "Expert Advisor" dropdown (found under your strategy name)
3. Configure test parameters and run your test

### 4. Creating Trading Templates

1. Set up your chart with indicators and settings
2. Right-click on the chart and select "Template" > "Save Template"
3. Save it in the Templates\[StrategyName]\ folder with a descriptive name

## Managing Collections and Strategies

The framework organizes your trading systems using collections and strategies:

- **Collection**: A group of related strategies (e.g., "Trend", "Scalping", "Portfolio")
- **Strategy**: A specific trading approach within a collection (e.g., "MACD_Cross", "RSI_Range")

This organization allows you to:
- Maintain multiple trading approaches
- Test different variations of strategies
- Keep related indicators and scripts together
- Share setups between different brokers

## Git Integration

The framework includes Git support for version control:

1. Run the `Git Repository Setup for MT Trading Framework.txt` script to:
   - Initialize a Git repository
   - Configure .gitignore for MetaTrader-specific files
   - Set up Git LFS for handling binary files
   - Create initial project structure

2. Use standard Git commands to track your changes:
   ```
   git add .
   git commit -m "Description of changes"
   git push
   ```

## Working with Multiple Brokers

The framework supports multiple brokers by:

1. Creating separate containerized MetaTrader installations for each broker
2. Organizing desktop shortcuts in broker-specific folders
3. Allowing the same strategy to be tested across different brokers

## Upgrading to Advanced Mode

If you later decide to use the Docker-based advanced mode:

1. Install Docker Desktop for Windows
2. Run the setup script again, selecting "Advanced" mode (option 2)
3. The script will set up Docker and compile your strategies automatically

## Troubleshooting

### MetaTrader Doesn't Find Your Broker

1. Check if your broker name matches exactly what's in the installation folder
2. Try providing the explicit path when running the setup

### Compilation Errors

1. Check the "Experts" tab at the bottom of MetaEditor for error messages
2. Verify that your code syntax is correct
3. Make sure any included files are in the correct locations

### Missing Files After Setup

1. Verify that your original MetaTrader installation was found
2. Check file permissions on your source and destination folders
3. Try running the setup script with administrator privileges

### Terminal Won't Start in Portable Mode

1. Make sure the portable flag is set in the origin.ini file
2. Check that all required files were copied during setup
3. Try removing the containerized copy and running setup again

## Sample Strategy Structure

The framework provides sample files for each component of your strategy:

1. **Expert Advisors**: Trading algorithms (MQL4/Experts/[StrategyName]/SampleStrategy.mq4)
2. **Indicators**: Technical indicators (MQL4/Indicators/[StrategyName]/SampleIndicator.mq4)
3. **Scripts**: Utility scripts (MQL4/Scripts/[StrategyName]/SampleScript.mq4)
4. **Libraries**: Reusable code (MQL4/Libraries/[StrategyName]/SampleLibrary.mq4)
5. **Include Files**: Header files (MQL4/Include/[StrategyName]/SampleInclude.mqh)
6. **Templates**: Chart templates (Templates/[StrategyName]/SampleTemplate.tpl)

These samples provide a starting point for your strategy development.

## Best Practices

1. **Keep Strategy Components Together**: Place all related files in the same strategy folder
2. **Use Descriptive Names**: Name files clearly to identify their purpose
3. **Document Your Code**: Add comments explaining your strategy logic
4. **Test Incrementally**: Make small changes and test frequently
5. **Back Up Your Work**: Use Git to track changes and protect your code
6. **Maintain Templates**: Save chart setups as templates for quick access
7. **Use Include Files**: Place common code in include files to share between components

Happy trading!