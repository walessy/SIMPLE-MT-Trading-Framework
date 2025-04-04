# MT Trading Framework for Advanced Users

This guide covers the Docker-based workflow for advanced users of the MT Trading Framework.

## Prerequisites

Before getting started, ensure you have:

- Docker Desktop installed and running
- Git installed
- PowerShell (Windows) or Terminal (macOS/Linux)
- Basic knowledge of MQL4/MQL5 programming

## Advanced Setup

### 1. Run the Easy Setup with Advanced Mode

1. Right-click on `Easy-Setup.ps1` and select "Run with PowerShell (Admin)"
2. Enter your strategy name when prompted
3. Select "Advanced" as your user level
4. Choose which platforms you want (MT4, MT5, or both)
5. Confirm your choices

The setup will:
- Create your framework structure
- Install MetaTrader terminals
- Configure Docker environment
- Create desktop shortcuts
- Add sample strategy files

### 2. Understanding the Docker Environment

The framework uses Docker to provide a consistent build environment:

- **Dockerfile**: Defines the build environment with Wine and MetaEditor
- **docker-compose.yml**: Configures the Docker services
- **Build Scripts**: Handles compilation within the Docker container

This ensures that your code compiles identically regardless of the host operating system.

## Advanced Development Workflow

### 1. Write Your Strategy

1. Navigate to your strategy folder:
   ```
   C:\Trading\MTFramework\Dev\YourStrategy\src\strategies\
   ```

2. Create a new file or edit the sample strategy
   - Use any IDE or text editor (VSCode recommended)
   - Save your strategy as `MyStrategy.mq4` (for MT4) or `MyStrategy.mq5` (for MT5)

### 2. Build with Docker

There are two ways to build:

**Option 1: Using the Desktop Shortcut**
1. Click the "Build YourStrategy" shortcut on your desktop
2. This launches Docker and compiles your strategies

**Option 2: Using the Command Line**
1. Open PowerShell/Terminal
2. Navigate to your framework directory
3. Run:
   ```
   docker compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt4 && build_mt5"
   ```

The build process:
1. Mounts your source directory in the Docker container
2. Compiles all MQL files using MetaEditor in Wine
3. Outputs compiled files to the build directory
4. Generates detailed logs for troubleshooting

### 3. Sync with MetaTrader

After building, sync the compiled files to MetaTrader:

1. Open the dashboard (`MT-Dashboard.ps1`)
2. Select your environment
3. Choose "Sync with MetaTrader"
4. Select "Development → MetaTrader" as the sync direction
5. Select the platform (MT4, MT5, or Both)

For continuous development, use watch mode:
```powershell
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -WatchMode
```

### 4. Test Your Strategy

1. In MetaTrader, press Ctrl+R to open the Strategy Tester
2. Select your strategy from the "Expert Advisor" dropdown
3. Choose a currency pair and timeframe
4. Click "Start" to run the test

## Advanced Features

### Version Control Integration

The framework is pre-configured for Git:

```bash
# Check status
git status

# Commit changes
git add .
git commit -m "Implemented new strategy feature"

# Create a branch
git checkout -b feature/new-indicator

# Push to remote (if configured)
git push origin feature/new-indicator
```

### Docker Build Customization

You can customize the Docker build environment:

1. Edit the `Dockerfile` to add dependencies
2. Modify the build scripts in the `scripts/` directory
3. Rebuild the Docker image:
   ```
   docker compose build
   ```

### Cross-Platform Development

Advanced mode with Docker works across operating systems:

**macOS Setup:**
1. Install Docker Desktop for Mac
2. Clone your framework repository
3. Run builds using the same Docker commands

**Linux Setup:**
1. Install Docker and Docker Compose
2. Clone your framework repository
3. Run the builds using the same Docker commands

### Continuous Integration

For teams, you can integrate with CI/CD pipelines:

1. Use the Docker build scripts in your CI pipeline
2. Store compiled artifacts in your CI system
3. Implement automated testing and deployment

Example GitHub Actions workflow:
```yaml
name: Build MT Strategies

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build MT4 Strategies
      run: docker-compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt4"
    - name: Build MT5 Strategies
      run: docker-compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt5"
    - name: Upload Artifacts
      uses: actions/upload-artifact@v2
      with:
        name: compiled-strategies
        path: |
          Dev/YourStrategy/build/mt4/*.ex4
          Dev/YourStrategy/build/mt5/*.ex5
```

## Advanced Command Reference

### Docker Commands

```bash
# Build Docker image
docker compose build

# Run complete build
docker compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt4 && build_mt5"

# Build only MT4 strategies
docker compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt4"

# Build only MT5 strategies
docker compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt5"

# Enter Docker container for debugging
docker compose run --rm mt_builder bash
```

### Advanced Sync Options

```powershell
# Two-way sync with watch mode
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -WatchMode

# Force overwrite during sync
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -Force

# Sync only specific file types
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -FileTypes "*.ex4,*.mqh"

# Sync with custom MT installation
.\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -MT4Path "D:\Custom\MT4Path"
```

## Troubleshooting

### Docker Issues

If Docker build fails:

1. Check Docker is running:
   ```
   docker info
   ```

2. View detailed logs:
   ```
   docker compose run --rm mt_builder bash -c "cat /app/Dev/YourStrategy/build/mt4/*.log"
   ```

3. Verify Docker volumes are mounted correctly:
   ```
   docker compose run --rm mt_builder bash -c "ls -la /app"
   ```

### Build Errors

Common compilation errors:

1. **Missing include files**: Add `.mqh` files to the include directory
2. **Syntax errors**: Check the log files in the build directory
3. **Wine issues**: Try rebuilding the Docker image with `docker compose build --no-cache`

### Advanced Sync Troubleshooting

For complex sync issues:

1. Enable verbose logging:
   ```
   .\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -Verbose
   ```

2. Debug file differences:
   ```
   .\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -DebugMode
   ```

3. Reset sync state:
   ```
   .\Sync-MTEnvironment.ps1 -DevEnvironmentName "YourStrategy" -Reset
   ```

## Performance Optimization

For large projects:

1. **Selective building**: Build only what you need
   ```
   docker compose run --rm mt_builder bash -c "cd /app/Dev/YourStrategy && build_mt4 SpecificStrategy.mq4"
   ```

2. **Persistent Docker volume**: Create a dedicated volume for faster builds
   ```yaml
   # Add to docker-compose.yml
   volumes:
     mt_cache:
       external: false
   ```

3. **Parallel compilation**: Modify build scripts to use parallel processing
   ```bash
   # Add to build scripts
   find . -name "*.mq4" | parallel -j4 "wine metaeditor.exe /compile:{} /log:{}.log"
   ```

## Next Steps

Once you're comfortable with the advanced workflow:

1. **Create multiple development environments**:
   ```powershell
   .\MTSetup.ps1 -DevEnvironmentName "NewStrategy" -SkipMT4 -SkipMT5
   ```

2. **Implement a CI/CD pipeline** for automated building and testing

3. **Create custom Docker extensions** for additional tools like backtesting

4. **Set up remote repositories** for team collaboration:
   ```bash
   git remote add origin https://github.com/yourusername/your-mt-framework.git
   git push -u origin main
   ```

5. **Create a central build repository** for distributing compiled strategies

## Best Practices for Advanced Users

### Code Organization

- Keep source and compiled files strictly separated
- Use `#include` with relative paths for better portability
- Follow a consistent naming convention for files and variables

### Docker Workflow

- Build your Docker image once and reuse it
- Mount volumes efficiently to reduce build time
- Consider creating a development container config for VS Code

### Version Control

- Use feature branches for development
- Tag releases with version numbers
- Keep binaries in Git LFS
- Document changes in a CHANGELOG.md file

### Team Collaboration

- Define a clear workflow for contributions
- Use pull requests for code reviews
- Implement automated testing for quality control
- Create shared include files for common functionality

## Conclusion

The advanced workflow with Docker provides a powerful, consistent environment for professional MetaTrader development. By leveraging container technology, you can:

- Ensure consistency across different machines
- Automate build and deployment processes
- Implement professional software development practices
- Support team collaboration effectively

The additional complexity compared to the basic workflow is offset by increased reliability, repeatability, and flexibility, especially for professional developers and teams working on complex trading solutions.