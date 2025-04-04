# Visual Guide to MT Trading Framework

This guide provides visual instructions for common tasks in the MT Trading Framework.

## Getting Started

### Step 1: Run the Easy Setup Script

Right-click on `Easy-Setup.ps1` and select "Run with PowerShell (Admin)":

![Run Easy Setup](images/run-easy-setup.png)

Enter your strategy name when prompted:

![Enter Strategy Name](images/enter-strategy-name.png)

### Step 2: Access Your Environment

After setup completes, you'll have shortcuts on your desktop:

![Desktop Shortcuts](images/desktop-shortcuts.png)

- **MetaTrader Terminals**: Open the trading platform
- **Build Shortcut**: Compile your trading strategies
- **Strategy Folders**: Quick access to your strategy files

## Development Workflow

### Editing Your Strategy

1. **Open your strategy files** located at:
   ```
   C:\Trading\MTFramework\Dev\YourStrategy\src\strategies\
   ```

   ![Strategy Files](images/strategy-files.png)

2. **Edit the code** using your favorite editor (VSCode recommended)

   ![Edit Code](images/edit-code.png)

### Building Your Strategy

1. **Click the Build shortcut** on your desktop

   ![Build Shortcut](images/build-shortcut.png)

2. **Watch the build process** complete

   ![Build Process](images/build-process.png)

### Syncing Your Files

This is a crucial step that keeps your development environment and MetaTrader in sync!

1. **Open the dashboard** and select your environment

   ![Open Dashboard](images/open-dashboard.png)

2. **Select "Sync with MetaTrader"**

   ![Sync Option](images/sync-option.png)

3. **Choose sync options**:
   - Direction: Two-way (recommended), Dev→MT, or MT→Dev
   - Platform: MT4, MT5, or Both

   ![Sync Options](images/sync-options.png)

4. **Watch the sync process** complete

   ![Sync Process](images/sync-process.png)

### Testing Your Strategy

1. **Open MetaTrader** using the desktop shortcut

   ![Open MT4](images/open-mt4.png)

2. **Access the Strategy Tester** (Ctrl+R or View > Strategy Tester)

   ![Strategy Tester](images/strategy-tester.png)

3. **Select your strategy** and run the test

   ![Run Test](images/run-test.png)

4. **View test results**

   ![Test Results](images/test-results.png)

## Common Tasks

### Creating a New Strategy

1. **Copy the sample strategy** from:
   ```
   C:\Trading\MTFramework\Dev\YourStrategy\src\strategies\SampleStrategy.mq4
   ```

2. **Save it with a new name** in the same folder

3. **Modify the code** to implement your strategy

4. **Build and test** using the steps above

### Updating an Existing Strategy

1. **Edit the strategy file**
2. **Build** using the desktop shortcut
3. **Sync** to transfer files to MetaTrader
4. **Test** in MetaTrader

### Editing in MetaTrader's Editor

If you prefer using MetaTrader's built-in editor:

1. **Open MetaTrader** using the desktop shortcut
2. **Right-click your strategy** in the Navigator panel
3. **Select "Modify"** to open the editor
4. **Make your changes** and save
5. **Sync back to development** by selecting "MT→Dev" sync direction

   ![MT Editor Sync](images/mt-editor-sync.png)

### Using Multiple Strategies

The framework supports multiple strategies in one environment:

![Multiple Strategies](images/multiple-strategies.png)

### Using Watch Mode for Continuous Sync

For active development sessions:

1. **Open PowerShell** and navigate to your framework folder
2. **Run the sync script with watch mode**:
   ```
   .\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -WatchMode
   ```
3. **Files will sync automatically** as you make changes
4. **Press Ctrl+C** to stop watch mode when done

   ![Watch Mode](images/watch-mode.png)

## Troubleshooting

### Build Errors

If your build fails, check the log file in the build directory:

![Build Error](images/build-error.png)

Common issues:
- Syntax errors in your code
- Missing include files
- Docker not running

### Sync Errors

If you encounter sync problems:

![Sync Error](images/sync-error.png)

Common issues:
- Files locked or in use by MetaTrader
- Conflicting changes in both locations
- Path issues or permissions

**Quick fixes:**
1. Close MetaTrader terminal before syncing
2. Use `-Force` parameter with the sync script
3. Manually resolve conflicts by choosing which version to keep

### MetaTrader Errors

If your strategy doesn't appear in MetaTrader:

1. **Refresh the Navigator** (right-click > Refresh)
2. **Check compilation** was successful
3. **Verify file location** is correct
4. **Run the sync script** to ensure files were transferred

### Sync Direction Guide

Not sure which sync direction to use? Here's a quick guide:

- **Two-way sync**: Use when you're not sure or want to keep everything in sync
- **Dev→MT**: Use after building to send compiled files to MetaTrader
- **MT→Dev**: Use after editing in MetaTrader's editor

![Sync Direction Guide](images/sync-direction-guide.png)

## Understanding the Sync Process

### How Syncing Works

The sync process connects your development environment with MetaTrader:

![Sync Diagram](images/sync-diagram.png)

1. **Source code** (.mq4, .mq5, .mqh) is synchronized in both directions
2. **Compiled files** (.ex4, .ex5) are typically copied from development to MetaTrader
3. **Directory structure** is maintained during the sync

## Getting Help

If you need additional help:
- Check the documentation in the `docs` folder
- Run `Easy-Setup.ps1 -Help` for setup options
- Refer to MetaTrader's official documentation for coding questions

## Sync Commands Reference

For advanced users, here are the key sync command options:

### Basic Sync
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy"
```

### Platform-Specific Sync
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -Platform MT4
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -Platform MT5
```

### Direction Control
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -SyncDirection DevToMT
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -SyncDirection MTToDev
```

### Watch Mode
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -WatchMode
```

### Force Overwrite
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -Force
```
