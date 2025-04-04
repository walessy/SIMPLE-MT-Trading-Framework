# File Synchronization Between MetaTrader and Framework

## The Challenge

When developing MetaTrader strategies with our framework, we face an important challenge:

1. **MetaTrader's Built-in Editor** saves files directly to the MetaTrader's directory structure:
   - MT4: `[MT4 Terminal]/MQL4/Experts/`, `[MT4 Terminal]/MQL4/Include/`, etc.
   - MT5: `[MT5 Terminal]/MQL5/Experts/`, `[MT5 Terminal]/MQL5/Include/`, etc.

2. **Our Framework's Structure** organizes files differently:
   - Development files: `Dev/MyStrategy/src/strategies/`, `Dev/MyStrategy/src/include/`, etc.
   - Build outputs: `Dev/MyStrategy/build/mt4/`, `Dev/MyStrategy/build/mt5/`, etc.
   - Global builds: `build/mt4/`, `build/mt5/`, etc.

This leads to a disconnect where files edited in one location don't automatically appear in the other, potentially causing version conflicts and lost work.

## The Solution: Sync-MTEnvironment.ps1

To solve this challenge, we've created a dedicated synchronization script that keeps files in sync between MetaTrader and our framework.

### How It Works

The `Sync-MTEnvironment.ps1` script:

1. **Two-way Synchronization**: Files can be synced in both directions:
   - From framework to MetaTrader
   - From MetaTrader to framework
   - Both ways (default)

2. **Smart File Handling**:
   - Only copies files that have changed
   - Maintains directory structure
   - Asks for confirmation before overwriting (unless forced)

3. **Complete Coverage**:
   - Syncs source files (.mq4, .mq5, .mqh)
   - Syncs compiled files (.ex4, .ex5)
   - Handles all component types (experts, indicators, scripts, includes, libraries)

4. **Watch Mode**: Can continuously monitor for changes and sync automatically

5. **Global Build Sync**: Ensures the global build directory stays up-to-date

### Usage Examples

#### Basic Synchronization

To perform a one-time, two-way sync between the "MyStrategy" environment and both MT4/MT5:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy"
```

#### Platform-Specific Sync

To sync only with MT4:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -Platform MT4
```

#### Direction Control

To push changes from the development environment to MetaTrader (but not the other way):

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -SyncDirection DevToMT
```

To pull changes from MetaTrader to the development environment:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -SyncDirection MTToDev
```

#### Continuous Monitoring

To continuously watch for changes and sync automatically:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -WatchMode
```

This is particularly useful when actively editing files in the MetaTrader editor.

#### Force Overwrite

To overwrite files without confirmation prompts:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -Force
```

## Recommended Workflow

For the most effective development experience, we recommend:

1. **Initial Setup**:
   - Create your development environment with `MTSetup.ps1`
   - Run an initial sync: `.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy"`

2. **Development with MetaTrader Editor**:
   - Start watch mode: `.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -WatchMode`
   - Edit files in the MetaTrader Editor
   - Files will automatically sync to your development environment

3. **Building**:
   - Use the framework's build process (Docker-based) to compile your files
   - Run a sync after building to update MetaTrader: `.\Sync-MTEnvironment.ps1 -DevEnvironmentName "MyStrategy" -SyncDirection DevToMT`

4. **Testing**:
   - Test your strategies in MetaTrader
   - Any changes you make in MetaTrader will be synchronized back to your development environment

5. **Version Control**:
   - Commit changes from your development environment to Git
   - The synchronization ensures your Git repository always has the latest changes

## Handling Multiple Development Environments

If you have multiple development environments, you'll need to run the sync script for each one separately:

```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "Strategy1"
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "Strategy2"
```

This keeps each development environment synchronized with the appropriate files in MetaTrader.

## Troubleshooting

If you encounter issues with synchronization:

1. **Files Not Syncing**: 
   - Ensure paths are correct in the script
   - Check file permissions
   - Try using the `-Force` flag

2. **Conflicts**:
   - If you get many conflict prompts, it means files have diverged
   - Choose which version to keep carefully
   - Consider using `-SyncDirection` to determine priority

3. **Performance Issues**:
   - If watch mode is using too many resources, increase the sleep interval in the script
   - Or use one-time syncs instead of watch mode

The synchronization script bridges the gap between MetaTrader's structure and our framework, allowing you to leverage both the power of MetaTrader's built-in editor and the benefits of our structured development environment.