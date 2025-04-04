# Beginner's Guide to MT Trading Framework

## What is the MT Trading Framework?

The MT Trading Framework is a user-friendly system that helps you develop, test, and manage trading strategies for MetaTrader 4 and MetaTrader 5 platforms.

Think of it as an organized workspace where you can:
- Write trading strategies (Expert Advisors)
- Test them on historical data
- Keep everything organized
- Share your strategies between different computers or with others

## Getting Started in 6 Easy Steps

### 1. Install the Framework

1. Download the framework files
2. Right-click on `Easy-Setup.ps1` and select "Run with PowerShell (Admin)"
3. Follow the simple on-screen instructions
4. Wait for installation to complete

That's it! The setup will create:
- Desktop shortcuts to your MetaTrader platforms
- A build shortcut to compile your strategies
- A sample strategy to get you started

### 2. Open the Dashboard

After installation, you can run the dashboard for easy management:

1. Double-click on `MT-Dashboard.ps1`
2. Use the menu to navigate your trading environments

### 3. Create Your First Strategy

The easiest way to start is by modifying the sample strategy:

1. Open the dashboard
2. Select your environment
3. Choose "Open Strategy Folder"
4. You'll see `SampleStrategy.mq4` and `SampleStrategy.mq5`
5. Copy one of these files and rename it (e.g., `MyFirstStrategy.mq4`)
6. Open it in any text editor (Notepad works fine!)
7. Make simple changes like:
   - Change the MA period from 20 to 50
   - Change the MA method to another type

Here's what that looks like in code:
```
// Change this:
input int MAPeriod = 20;
input ENUM_MA_METHOD MAMethod = MODE_SMA;

// To this:
input int MAPeriod = 50;
input ENUM_MA_METHOD MAMethod = MODE_EMA;
```

### 4. Build Your Strategy

1. From the dashboard, select "Build Strategy"
2. Or click the "Build" shortcut on your desktop
3. Wait for the build to complete

### 5. Sync Your Strategy to MetaTrader

This critical step transfers your files between your development environment and MetaTrader:

1. From the dashboard, select "Sync with MetaTrader"
2. Choose "Two-way sync" when prompted (this is usually the best option)
3. Select which platform to sync with (MT4, MT5, or Both)
4. Wait for the sync to complete

**Why is syncing important?**
- It copies your compiled strategies to MetaTrader so you can test them
- It keeps your development environment and MetaTrader folders in sync
- It helps you avoid losing work when editing in either location

**When to sync:**
- After building your strategy
- Before testing in MetaTrader
- After making changes in MetaTrader's editor
- Any time you want to ensure both locations have the latest files

### 6. Test Your Strategy

1. From the dashboard, select "Launch MetaTrader with this Strategy"
2. When MetaTrader opens, press Ctrl+R to open the Strategy Tester
3. Select your strategy from the "Expert Advisor" dropdown
4. Select a currency pair (like EURUSD)
5. Click "Start" to run the test

## Common Questions

### What's the difference between MT4 and MT5?

- MT4 is the classic version, simpler but still widely used
- MT5 is newer with more features but slightly more complex
- Our framework supports both, so you can decide later!

### How do I know if my strategy is working?

After running a test, check:
- The equity graph (should go up if profitable)
- The "Report" tab for detailed statistics
- The number of trades and win/loss ratio

### What if I get errors when building?

Common issues and solutions:
- **Syntax error**: Check your code for missing semicolons (;) or brackets {}
- **Docker not running**: Start Docker Desktop and try again
- **Include file not found**: Make sure all files are in the right folders

### What if I edit my strategy in MetaTrader's editor?

If you make changes using MetaTrader's built-in editor:
1. Use the dashboard to select "Sync with MetaTrader"
2. Choose "MetaTrader → Development" as the sync direction
3. This will copy your changes back to your development environment

### Why do I need to sync files?

Syncing solves a common problem:
- MetaTrader stores files in its own folders
- Our framework organizes files in a different structure
- Without syncing, changes made in one place won't appear in the other
- The sync functionality keeps everything consistent automatically

### Where are my files stored?

All your files are in:
```
C:\Trading\MTFramework\Dev\YourStrategyName\src\strategies\
```

Compiled files go to:
```
C:\Trading\MTFramework\Dev\YourStrategyName\build\mt4\
C:\Trading\MTFramework\Dev\YourStrategyName\build\mt5\
```

MetaTrader stores its copies in:
```
C:\Trading\MTFramework\MT4\BrokerName\MQL4\Experts\
C:\Trading\MTFramework\MT5\BrokerName\MQL5\Experts\
```

## The Importance of File Synchronization

One of the most powerful features of this framework is the automatic file synchronization between your development environment and MetaTrader. Here's why it matters:

### Problem Without Syncing:
- You edit a file in your development environment → It doesn't appear in MetaTrader
- You edit a file in MetaTrader's editor → It doesn't appear in your development environment
- You lose track of which version is the latest
- You can't easily use version control with files edited in MetaTrader

### Solution With Syncing:
- Changes are automatically copied between locations
- You always have the latest version everywhere
- You can use MetaTrader's editor or any external editor
- Version control works properly with all your changes

### How to Use Sync:

**Option 1: From the Dashboard (Recommended)**
1. Select your environment
2. Choose "Sync with MetaTrader"
3. Select the sync direction and platform

**Option 2: Using Watch Mode (Advanced)**
1. Run `Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -WatchMode`
2. This will continuously monitor for changes and sync automatically
3. Press Ctrl+C to stop the watch mode when done

### When to Sync:
- After building your strategy
- Before and after testing in MetaTrader
- After editing files in MetaTrader's editor
- When switching between different computers
- Before committing changes to Git

## Next Steps

Once you're comfortable with the basics:

1. **Learn MQL4/MQL5 programming**: Start with small modifications and gradually learn more
2. **Create indicators**: Store them in the `indicators` folder
3. **Try watch mode sync**: For continuous synchronization during development
4. **Use version control**: The framework has Git built in

## Need Help?

- Use the dashboard's Help menu
- Check the documentation folder
- Look at the sync explanation document (`mt-sync-explanation.md`) for more details

Happy trading!