# BuildManager.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Script-level variables to avoid scope issues
$script:isRunning = $false
$script:secondsRemaining = 0
$script:buildInterval = 30  # Build interval in seconds

# Helper function to append text with color to a RichTextBox
function Append-TextWithColor {
    param (
        [System.Windows.Forms.RichTextBox]$TextBox,
        [string]$Text,
        [System.Drawing.Color]$Color
    )
    # Debug logging to see what text is being appended
    Write-Host "Appending to RichTextBox: $Text"
    $TextBox.SuspendLayout()
    $TextBox.SelectionStart = $TextBox.TextLength
    $TextBox.SelectionLength = 0
    $TextBox.SelectionColor = $Color
    $TextBox.AppendText($Text + "`n")
    $TextBox.SelectionColor = $TextBox.ForeColor
    $TextBox.ResumeLayout()
    # Auto-scroll to the bottom
    $TextBox.SelectionStart = $TextBox.Text.Length
    $TextBox.ScrollToCaret()
}

# Form setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "MT Trading Framework Build Manager"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

# Dropdown for selecting strategy collection
$dropdownLabel = New-Object System.Windows.Forms.Label
$dropdownLabel.Text = "Select Strategy Collection:"
$dropdownLabel.Location = New-Object System.Drawing.Point(10, 10)
$dropdownLabel.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($dropdownLabel)

$dropdown = New-Object System.Windows.Forms.ComboBox
$dropdown.Location = New-Object System.Drawing.Point(160, 10)
$dropdown.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($dropdown)

# Start Build button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Build"
$startButton.Location = New-Object System.Drawing.Point(370, 10)
$startButton.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($startButton)

# Stop Build button
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Build"
$stopButton.Location = New-Object System.Drawing.Point(480, 10)
$stopButton.Size = New-Object System.Drawing.Size(100, 30)
$stopButton.Enabled = $false
$form.Controls.Add($stopButton)

# Build status box (RichTextBox)
$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(10, 50)
$statusBox.Size = New-Object System.Drawing.Size(560, 200)  # Top half of the form
$statusBox.Multiline = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.ReadOnly = $true
$statusBox.BackColor = [System.Drawing.Color]::LightGray
$statusBox.ForeColor = [System.Drawing.Color]::Black
# Add KeyPress event handler to suppress default sounds
$statusBox.Add_KeyPress({
    param($sender, $e)
    $e.Handled = $true  # Suppress default keypress sounds
})
# Add TextChanged event handler to suppress potential sounds
$statusBox.Add_TextChanged({
    param($sender, $e)
    # Do nothing, just suppress any potential sound
})
$form.Controls.Add($statusBox)

# Countdown box (TextBox)
$countdownBox = New-Object System.Windows.Forms.TextBox
$countdownBox.Location = New-Object System.Drawing.Point(10, 260)
$countdownBox.Size = New-Object System.Drawing.Size(560, 200)  # Bottom half of the form
$countdownBox.Multiline = $true
$countdownBox.ReadOnly = $true
$countdownBox.BackColor = [System.Drawing.Color]::LightGray
$countdownBox.ForeColor = [System.Drawing.Color]::DarkOrange
$countdownBox.Text = ""
$form.Controls.Add($countdownBox)

# Load setup.json to get the BasePath
$setupFile = Join-Path -Path $PSScriptRoot -ChildPath "setup.json"
if (-not (Test-Path $setupFile)) {
    Append-TextWithColor -TextBox $statusBox -Text "Setup file not found at $setupFile. Please run MTSetup.ps1 first." -Color Red
    $startButton.Enabled = $false
    exit
}

$setupConfig = Get-Content $setupFile -Raw | ConvertFrom-Json
$basePath = $setupConfig.BasePath

# Load build.json from the BasePath
$buildFile = Join-Path -Path $basePath -ChildPath "build.json"
if (-not (Test-Path $buildFile)) {
    Append-TextWithColor -TextBox $statusBox -Text "Build file not found at $buildFile. Please run MTSetup.ps1 to set up the environment." -Color Red
    $startButton.Enabled = $false
    exit
}

$buildConfig = Get-Content $buildFile -Raw | ConvertFrom-Json

# Populate dropdown with strategy collections
$strategyCollections = $buildConfig.StrategyCollections | ForEach-Object { "$($_.CollectionName)-$($_.StrategyName)" } | Sort-Object
foreach ($sc in $strategyCollections) {
    $dropdown.Items.Add($sc) | Out-Null
}
if ($dropdown.Items.Count -gt 0) {
    $dropdown.SelectedIndex = 0
}

# Function to display strategy collections, platforms, and strategies
function Display-StrategyCollections {
    param (
        [System.Windows.Forms.RichTextBox]$TextBox,
        [PSCustomObject]$StrategyCollection,
        [PSCustomObject]$SetupConfig
    )

    Append-TextWithColor -TextBox $TextBox -Text "Strategy Collection:" -Color DarkBlue
    Append-TextWithColor -TextBox $TextBox -Text "  Collection: $($StrategyCollection.CollectionName)" -Color White
    Append-TextWithColor -TextBox $TextBox -Text "    Strategy: $($StrategyCollection.StrategyName)" -Color White

    # Find the corresponding setup configuration to get platform and environment details
    $setupStrategyCollection = $SetupConfig.StrategyCollections | Where-Object { $_.CollectionName -eq $StrategyCollection.CollectionName -and $_.StrategyName -eq $StrategyCollection.StrategyName }
    if ($setupStrategyCollection) {
        foreach ($platform in $setupStrategyCollection.Platforms) {
            $platformName = $platform.Platform
            Append-TextWithColor -TextBox $TextBox -Text "    Platform: $platformName" -Color White

            # List environments for each platform
            $environments = $platform.Environments | Sort-Object
            foreach ($env in $environments) {
                Append-TextWithColor -TextBox $TextBox -Text "      Environment: $env" -Color White
            }
        }
    }
}

# Timer for periodic build (every 30 seconds)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $script:buildInterval * 1000  # Convert to milliseconds

# Timer for countdown (every second)
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000  # 1 second

# Main build timer tick event
$timer.Add_Tick({
    if (-not $script:isRunning) {
        $timer.Stop()
        return
    }

    $selected = $dropdown.SelectedItem
    if (-not $selected) {
        Append-TextWithColor -TextBox $statusBox -Text "Please select a strategy collection to build." -Color Red
        return
    }

    $collectionName, $strategyName = $selected.Split('-')
    $strategyCollection = $buildConfig.StrategyCollections | Where-Object { $_.CollectionName -eq $collectionName -and $_.StrategyName -eq $strategyName }
    if (-not $strategyCollection) {
        Append-TextWithColor -TextBox $statusBox -Text "Configuration for $selected not found in build.json." -Color Red
        return
    }

    # Stop the countdown timer during the build
    $countdownTimer.Stop()
    $countdownBox.Text = ""
    Write-Host "Build started, cleared countdownBox"
    Append-TextWithColor -TextBox $statusBox -Text "Running build for $selected at $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')..." -Color DarkOrange

    # Display strategy collection details
    Display-StrategyCollections -TextBox $statusBox -StrategyCollection $strategyCollection -SetupConfig $setupConfig

    # Run the build
    $buildSuccess = $true
    try {
        if ($strategyCollection.SkipDocker) {
            Append-TextWithColor -TextBox $statusBox -Text "Basic mode: Checking for manually compiled files..." -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "Syncing compiled files to Dev, Test, Deploy, and Package environments..." -Color DarkBlue

            $mt4DevPath = $strategyCollection.Config.MT4Paths.DevPath
            $mt4TestPath = $strategyCollection.Config.MT4Paths.TestPath
            $mt4DeployPath = $strategyCollection.Config.MT4Paths.DeployPath
            $mt4PackagePath = $strategyCollection.Config.MT4Paths.PackagePath
            $mt5DevPath = $strategyCollection.Config.MT5Paths.DevPath
            $mt5TestPath = $strategyCollection.Config.MT5Paths.TestPath
            $mt5DeployPath = $strategyCollection.Config.MT5Paths.DeployPath
            $mt5PackagePath = $strategyCollection.Config.MT5Paths.PackagePath
            $mt4Path = $strategyCollection.Config.MT4RootPath
            $mt5Path = $strategyCollection.Config.MT5RootPath

            Append-TextWithColor -TextBox $statusBox -Text "MT4 DevPath: $mt4DevPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 TestPath: $mt4TestPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 DeployPath: $mt4DeployPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 PackagePath: $mt4PackagePath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 DevPath: $mt5DevPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 TestPath: $mt5TestPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 DeployPath: $mt5DeployPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 PackagePath: $mt5PackagePath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4Path: $mt4Path" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5Path: $mt5Path" -Color DarkBlue

            # Validate paths
            $paths = @($mt4DevPath, $mt4TestPath, $mt4DeployPath, $mt4PackagePath, $mt5DevPath, $mt5TestPath, $mt5DeployPath, $mt5PackagePath, $mt4Path, $mt5Path)
            foreach ($path in $paths) {
                if (-not $path) {
                    throw "One or more configuration paths are missing."
                }
            }

            # Call Sync-CompiledFiles from MTSetup.ps1
            $syncScript = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
            try {
                . $syncScript
                Sync-CompiledFiles -MT4DevPath $mt4DevPath `
                                  -MT4TestPath $mt4TestPath `
                                  -MT4DeployPath $mt4DeployPath `
                                  -MT4PackagePath $mt4PackagePath `
                                  -MT5DevPath $mt5DevPath `
                                  -MT5TestPath $mt5TestPath `
                                  -MT5DeployPath $mt5DeployPath `
                                  -MT5PackagePath $mt5PackagePath `
                                  -MT4Path $mt4Path `
                                  -MT5Path $mt5Path `
                                  -CollectionName $collectionName `
                                  -StrategyName $strategyName
                Append-TextWithColor -TextBox $statusBox -Text "Files synced to all environments." -Color Green
            } catch {
                $buildSuccess = $false
                Append-TextWithColor -TextBox $statusBox -Text "Sync failed: $($_.Exception.Message)" -Color Red
            }
        } else {
            Append-TextWithColor -TextBox $statusBox -Text "Advanced mode: Building with Docker..." -Color DarkBlue
            $setupScript = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
            try {
                . $setupScript
                Setup-Docker -Installations $strategyCollection.Installations -StrategyName $strategyName
            } catch {
                $buildSuccess = $false
                Append-TextWithColor -TextBox $statusBox -Text "Docker build failed: $($_.Exception.Message)" -Color Red
            }
        }
    } catch {
        $buildSuccess = $false
        Append-TextWithColor -TextBox $statusBox -Text "Build failed: $($_.Exception.Message)" -Color Red
    }

    # Display build status with color
    if ($buildSuccess) {
        Append-TextWithColor -TextBox $statusBox -Text "Build cycle completed successfully." -Color Green
    } else {
        Append-TextWithColor -TextBox $statusBox -Text "Build cycle failed." -Color Red
    }

    # Reset the countdown and restart the countdown timer
    $script:secondsRemaining = $script:buildInterval
    $countdownBox.Text = "Next build in $($script:secondsRemaining)s..."
    Write-Host "Reset countdownBox: Next build in $($script:secondsRemaining)s..."
    $countdownTimer.Start()
})

# Main build timer tick event
$timer.Add_Tick({
    if (-not $script:isRunning) {
        $timer.Stop()
        return
    }

    $selected = $dropdown.SelectedItem
    if (-not $selected) {
        Append-TextWithColor -TextBox $statusBox -Text "Please select a strategy collection to build." -Color Red
        return
    }

    $collectionName, $strategyName = $selected.Split('-')
    $strategyCollection = $buildConfig.StrategyCollections | Where-Object { $_.CollectionName -eq $collectionName -and $_.StrategyName -eq $strategyName }
    if (-not $strategyCollection) {
        Append-TextWithColor -TextBox $statusBox -Text "Configuration for $selected not found in build.json." -Color Red
        return
    }

    # Stop the countdown timer during the build
    $countdownTimer.Stop()
    $countdownBox.Text = ""
    Write-Host "Build started, cleared countdownBox"
    Append-TextWithColor -TextBox $statusBox -Text "Running build for $selected at $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')..." -Color DarkOrange

    # Display strategy collection details
    Display-StrategyCollections -TextBox $statusBox -StrategyCollection $strategyCollection -SetupConfig $setupConfig

    # Run the build
    $buildSuccess = $true
    try {
        if ($strategyCollection.SkipDocker) {
            Append-TextWithColor -TextBox $statusBox -Text "Basic mode: Checking for manually compiled files..." -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "Syncing compiled files to Dev, Test, Deploy, and Package environments..." -Color DarkBlue

            $mt4DevPath = $strategyCollection.Config.MT4Paths.DevPath
            $mt4TestPath = $strategyCollection.Config.MT4Paths.TestPath
            $mt4DeployPath = $strategyCollection.Config.MT4Paths.DeployPath
            $mt4PackagePath = $strategyCollection.Config.MT4Paths.PackagePath
            $mt5DevPath = $strategyCollection.Config.MT5Paths.DevPath
            $mt5TestPath = $strategyCollection.Config.MT5Paths.TestPath
            $mt5DeployPath = $strategyCollection.Config.MT5Paths.DeployPath
            $mt5PackagePath = $strategyCollection.Config.MT5Paths.PackagePath
            $mt4Path = $strategyCollection.Config.MT4RootPath
            $mt5Path = $strategyCollection.Config.MT5RootPath

            Append-TextWithColor -TextBox $statusBox -Text "MT4 DevPath: $mt4DevPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 TestPath: $mt4TestPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 DeployPath: $mt4DeployPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4 PackagePath: $mt4PackagePath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 DevPath: $mt5DevPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 TestPath: $mt5TestPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 DeployPath: $mt5DeployPath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5 PackagePath: $mt5PackagePath" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT4Path: $mt4Path" -Color DarkBlue
            Append-TextWithColor -TextBox $statusBox -Text "MT5Path: $mt5Path" -Color DarkBlue

            # Call Sync-CompiledFiles from MTSetup.ps1
            $syncScript = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
            . $syncScript
            Sync-CompiledFiles -MT4DevPath $mt4DevPath -MT4TestPath $mt4TestPath -MT4DeployPath $mt4DeployPath -MT4PackagePath $mt4PackagePath -MT5DevPath $mt5DevPath -MT5TestPath $mt5TestPath -MT5DeployPath $mt5DeployPath -MT5PackagePath $mt5PackagePath -MT4Path $mt4Path -MT5Path $mt5Path -CollectionName $collectionName -StrategyName $strategyName

            Append-TextWithColor -TextBox $statusBox -Text "Files synced to all environments." -Color Green
        } else {
            Append-TextWithColor -TextBox $statusBox -Text "Advanced mode: Building with Docker..." -Color DarkBlue
            # Call Setup-Docker from MTSetup.ps1
            $setupScript = Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1"
            . $setupScript
            Setup-Docker -Installations $strategyCollection.Installations -StrategyName $strategyName
        }
    } catch {
        $buildSuccess = $false
        Append-TextWithColor -TextBox $statusBox -Text "Build failed: $_" -Color Red
    }

    # Display build status with color
    if ($buildSuccess) {
        Append-TextWithColor -TextBox $statusBox -Text "Build cycle completed successfully." -Color Green
    } else {
        Append-TextWithColor -TextBox $statusBox -Text "Build cycle failed." -Color Red
    }

    # Reset the countdown and restart the countdown timer
    $script:secondsRemaining = $script:buildInterval
    $countdownBox.Text = "Next build in $($script:secondsRemaining)s..."
    Write-Host "Reset countdownBox: Next build in $($script:secondsRemaining)s..."
    $countdownTimer.Start()
})

# Start Build button click event
$startButton.Add_Click({
    $script:isRunning = $true
    $startButton.Enabled = $false
    $stopButton.Enabled = $true
    $script:secondsRemaining = $script:buildInterval
    Append-TextWithColor -TextBox $statusBox -Text "Build process started." -Color Green
    $countdownBox.Text = "Next build in $($script:secondsRemaining)s..."
    Write-Host "Started countdownBox: Next build in $($script:secondsRemaining)s..."
    $timer.Start()
    $countdownTimer.Start()
})

# Stop Build button click event
$stopButton.Add_Click({
    $script:isRunning = $false
    $timer.Stop()
    $countdownTimer.Stop()
    $startButton.Enabled = $true
    $stopButton.Enabled = $false
    $countdownBox.Text = ""
    Write-Host "Cleared countdownBox"
    Append-TextWithColor -TextBox $statusBox -Text "Build process stopped." -Color DarkOrange
})

# Set up form closing event to ensure timers are stopped
$form.Add_FormClosing({
    $timer.Stop()
    $countdownTimer.Stop()
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()