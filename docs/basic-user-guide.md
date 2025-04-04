# MT Trading Framework for Basic Users

This guide explains how to use the MT Trading Framework without Docker, ideal for traders who want a simple setup.

## What You Need

- Windows computer
- MetaTrader 4 and/or MetaTrader 5 (installed by the setup script)
- Basic knowledge of MQL4/MQL5 programming

## Getting Started

### 1. Run the Easy Setup

1. Right-click on `Easy-Setup.ps1` and select "Run with PowerShell (Admin)"
2. Enter your strategy name when prompted
3. Select "Basic" as your user level
4. Choose which platforms you want (MT4, MT5, or both)
5. Confirm your choices

The setup will:
- Create your framework structure
- Install MetaTrader terminals
- Create desktop shortcuts
- Add sample strategy files

### 2. Understanding Your Environment

After setup, you'll have:

- **Strategy Folder**: `C:\Trading\MTFramework\Dev\YourStrategy\src\strategies\`
  This is where you write your strategy code (.mq4 and .mq5 files)

- **MetaTrader Folders**: `C:\Trading\MTFramework\MT4\` and `C:\Trading\MTFramework\MT5\`
  These contain the MetaTrader terminals

- **Desktop Shortcuts**:
  - **Build YourStrategy (Basic)**: Copies files to MetaTrader
  - **MetaTrader terminals**: Opens the trading platforms

## Development Workflow (Basic User)

### 1. Write Your Strategy

1. Navigate to your strategy folder:
   ```
   C:\Trading\MTFramework\Dev\YourStrategy\src\strategies\
   ```

2. Create a new file or edit the sample strategy
   - Use any text editor (like Notepad, Notepad++, or VSCode)
   - Save your strategy as `MyStrategy.mq4` (for MT4) or `MyStrategy.mq5` (for MT5)

### 2. Copy and Compile

Since you're using the Basic mode, compilation happens in MetaTrader:

1. Click the "Build YourStrategy (Basic)" shortcut on your desktop
2. This copies your strategy files to the MetaTrader folders
3. Open the MetaTrader terminal using its desktop shortcut
4. In MetaTrader, open the Navigator panel (Ctrl+N if not visible)
5. Find your strategy under "Expert Advisors"
6. Right-click on it and select "Compile" (or press F7)

### 3. Sync Files

After compiling in MetaTrader, you need to sync the compiled files back:

1. Open the dashboard (`MT-Dashboard.ps1`)
2. Select your environment
3. Choose "Sync with MetaTrader"
4. Select "MetaTrader → Development" as the sync direction
5. Select the platform (MT4, MT5, or Both)

This copies the compiled files (.ex4 or .ex5) back to your development environment.

### 4. Test Your Strategy

1. In MetaTrader, press Ctrl+R to open the Strategy Tester
2. Select your strategy from the "Expert Advisor" dropdown
3. Choose a currency pair and timeframe
4. Click "Start" to run the test

## Using MetaTrader's Editor (Optional)

If you prefer MetaTrader's built-in editor:

1. In MetaTrader, right-click on your strategy in the Navigator panel
2. Select "Modify" to open the editor
3. Make your changes and save
4. Compile directly in MetaTrader by pressing F7
5. Sync back to your development environment as described above

## Key Commands for Basic Users

### Dashboard

The dashboard provides a user-friendly interface:

1. Run `MT-Dashboard.ps1`
2. Navigate menus with number keys
3. Access all functionality without remembering commands

### Manual Sync

If you need to manually sync:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -SyncDirection MTToDev
```

This copies files from MetaTrader to your development environment.

## Common Questions for Basic Users

### Why do I need to sync after compiling?

MetaTrader saves compiled files in its own folders. Syncing copies these files to your development environment, keeping everything organized and backed up.

### Can I edit files directly in MetaTrader?

Yes! Just remember to sync the changes back to your development environment to keep everything consistent.

### What's the difference between Basic and Advanced mode?

Basic mode uses MetaTrader's own compiler and doesn't require Docker, making it simpler to set up. Advanced mode uses Docker for compilation, which provides better consistency across machines but requires additional software.

### Do I need to run the build script before each test?

Only if you've made changes to your strategy. If you're just adjusting test parameters, you can run tests without rebuilding.

### How do I upgrade to Advanced mode later?

1. Install Docker Desktop
2. Run `.\MTSetup.ps1 -ConfigureDocker`
3. Use the "Build" shortcut instead of "Build (Basic)"

## Troubleshooting

### Compilation errors in MetaTrader

1. Check the "Experts" tab at the bottom of MetaTrader
2. Look for error messages
3. Fix the errors in your code and try again

### Files not showing in MetaTrader

1. Check if the build script ran successfully
2. Refresh the Navigator panel (right-click > Refresh)
3. Verify files were copied to the correct location

### Sync issues

1. Make sure MetaTrader is closed during sync
2. Run the sync script with the `-Force` parameter
3. Check file permissions

## Next Steps

Once you're comfortable with basics:
1. Learn more about MQL programming
2. Create custom indicators
3. Explore more advanced trading strategies
4. Consider upgrading to Advanced mode if you need more features

Happy trading!