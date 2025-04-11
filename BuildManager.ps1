[CmdletBinding()]
param ()

# Ensure script runs from its own directory
Set-Location -Path $PSScriptRoot

# Import functions from MTSetup.ps1 without running setup
. (Join-Path -Path $PSScriptRoot -ChildPath "MTSetup.ps1")

# Load config
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
if (-not (Test-Path $configFile)) {
    Write-Host "Config file not found at $configFile. Please run MTSetup.ps1 first." -ForegroundColor Red
    exit 1
}
$configs = Get-Content $configFile -Raw | ConvertFrom-Json

# Continuous Build Functions
function Start-ContinuousBuild {
    param ([array]$Installations, [string]$DevPath, [string]$TestPath, [string]$DeployPath, [string]$PackagePath, 
           [string]$MT4Path, [string]$MT5Path, [string]$StrategyName, [string]$CollectionName, 
           [string]$BasePath, [switch]$SkipDocker, [int]$BuildIntervalSeconds = 30)

    $flagFile = Join-Path -Path $BasePath -ChildPath "continuous_build_running.flag"
    if (Test-Path $flagFile) {
        $jobId = Get-Content -Path $flagFile -ErrorAction SilentlyContinue
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
        if ($job -and $job.State -eq "Running") {
            Write-StatusGUI "Continuous build already running for $CollectionName-$StrategyName (Job ID: $jobId)."
            return
        } else {
            Write-StatusGUI "Found stale flag file. Cleaning up..."
            Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Id $jobId -ErrorAction SilentlyContinue
                Remove-Job -Id $jobId -ErrorAction SilentlyContinue
            }
        }
    }

    $job = Start-Job -ScriptBlock {
        param ($installations, $devPath, $testPath, $deployPath, $packagePath, $mt4Path, $mt5Path, $strategyName, $collectionName, $skipDocker, $interval, $basePath, $scriptRoot)
        # Define Write-StatusGUI within the job to send messages back to the GUI
        function Write-StatusGUI {
            param ([string]$Message)
            try {
                [System.Windows.Forms.Application]::OpenForms[0].Controls['statusBox'].Invoke([Action]{ 
                    [System.Windows.Forms.Application]::OpenForms[0].Controls['statusBox'].AppendText("$Message`r`n") 
                })
            } catch {
                Write-Output "Failed to update GUI: $_"
            }
        }
        # Define Update-CurrentTask to update the current task label
        function Update-CurrentTask {
            param ([string]$Task)
            try {
                [System.Windows.Forms.Application]::OpenForms[0].Controls['currentTaskLabel'].Invoke([Action]{ 
                    [System.Windows.Forms.Application]::OpenForms[0].Controls['currentTaskLabel'].Text = "Current Task: $Task"
                })
            } catch {
                Write-Output "Failed to update current task: $_"
            }
        }

        Set-Location -Path $basePath
        . (Join-Path -Path $scriptRoot -ChildPath "MTSetup.ps1")
        while ($true) {
            if (-not (Test-Path (Join-Path -Path $basePath -ChildPath "continuous_build_running.flag"))) { break }
            Write-StatusGUI "Running periodic build for $collectionName-$strategyName at $(Get-Date)..."
            
            if (-not $skipDocker) {
                Update-CurrentTask "Building MQL Files..."
                Write-StatusGUI "Starting MQL file compilation..."
                Build-MQLFiles -Installations $installations -StrategyName $strategyName
                Write-StatusGUI "Docker build completed."
            } else {
                Write-StatusGUI "Basic mode: Checking for manually compiled files..."
            }
            
            Update-CurrentTask "Syncing Compiled Files..."
            Write-StatusGUI "Syncing compiled files to Dev, Test, Deploy, and Package environments..."
            Sync-CompiledFiles -DevPath $devPath -TestPath $testPath -DeployPath $deployPath -PackagePath $packagePath `
                              -MT4Path $mt4Path -MT5Path $mt5Path -CollectionName $collectionName -StrategyName $strategyName
            Write-StatusGUI "Files synced to all environments."
            
            Update-CurrentTask "Waiting for Next Build..."
            Write-StatusGUI "Build cycle completed. Waiting for next cycle..."
            Start-Sleep -Seconds $interval
        }
    } -ArgumentList $Installations, $DevPath, $TestPath, $DeployPath, $PackagePath, $MT4Path, $MT5Path, $StrategyName, $CollectionName, $SkipDocker, $BuildIntervalSeconds, $BasePath, $PSScriptRoot

    Set-Content -Path $flagFile -Value $job.Id
    Write-StatusGUI "Continuous build started for $CollectionName-$StrategyName (Job ID: $($job.Id))."
    
    # Start the countdown timer
    $script:lastBuildTime = Get-Date
    $script:buildInterval = $BuildIntervalSeconds
    $timer.Start()
}

function Stop-ContinuousBuild {
    param ([string]$BasePath)
    $flagFile = Join-Path -Path $BasePath -ChildPath "continuous_build_running.flag"
    if (Test-Path $flagFile) {
        $jobId = Get-Content -Path $flagFile -ErrorAction SilentlyContinue
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
        if ($job) {
            Stop-Job -Id $jobId -ErrorAction SilentlyContinue
            Remove-Job -Id $jobId -ErrorAction SilentlyContinue
        }
        Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
        Write-StatusGUI "Continuous build stopped for $BasePath."
        $timer.Stop()
        $timerLabel.Text = "Next Build: N/A"
        $currentTaskLabel.Text = "Current Task: None"
    } else {
        Write-StatusGUI "No continuous build running for $BasePath."
    }
}

# GUI Setup
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "MT Trading Framework Build Manager"
$form.Size = New-Object System.Drawing.Size(400, 450)
$form.StartPosition = "CenterScreen"

$setupLabel = New-Object System.Windows.Forms.Label
$setupLabel.Text = "Select Setup:"
$setupLabel.Location = New-Object System.Drawing.Point(10, 10)
$setupLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($setupLabel)

$setupComboBox = New-Object System.Windows.Forms.ComboBox
$setupComboBox.Location = New-Object System.Drawing.Point(120, 10)
$setupComboBox.Size = New-Object System.Drawing.Size(250, 20)
$configs | ForEach-Object { $setupComboBox.Items.Add("$($_.CollectionName)-$($_.StrategyName)") } | Out-Null
if ($configs.Count -gt 0) { $setupComboBox.SelectedIndex = 0 }
$form.Controls.Add($setupComboBox)

$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Name = "statusBox"
$statusBox.Multiline = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.ReadOnly = $true
$statusBox.Location = New-Object System.Drawing.Point(10, 40)
$statusBox.Size = New-Object System.Drawing.Size(360, 200)
$form.Controls.Add($statusBox)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Build"
$startButton.Location = New-Object System.Drawing.Point(10, 250)
$startButton.Size = New-Object System.Drawing.Size(80, 30)
$startButton.Add_Click({
    if ($setupComboBox.SelectedIndex -eq -1) {
        $statusBox.AppendText("Please select a setup.`r`n")
        return
    }
    $selectedConfig = $configs[$setupComboBox.SelectedIndex]
    try {
        Start-ContinuousBuild -Installations $selectedConfig.Installations `
                              -DevPath $selectedConfig.Config.DevPath `
                              -TestPath $selectedConfig.Config.TestPath `
                              -DeployPath $selectedConfig.Config.DeployPath `
                              -PackagePath $selectedConfig.Config.PackagePath `
                              -MT4Path $selectedConfig.Config.MT4RootPath `
                              -MT5Path $selectedConfig.Config.MT5RootPath `
                              -StrategyName $selectedConfig.StrategyName `
                              -CollectionName $selectedConfig.CollectionName `
                              -BasePath $selectedConfig.BasePath `
                              -SkipDocker:$selectedConfig.SkipDocker `
                              -BuildIntervalSeconds 30
        $statusBox.AppendText("Started continuous build at $(Get-Date)`r`n")
        $startButton.Enabled = $false
        $stopButton.Enabled = $true
    } catch {
        $statusBox.AppendText("Error starting build: $_`r`n")
    }
})
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Build"
$stopButton.Location = New-Object System.Drawing.Point(100, 250)
$stopButton.Size = New-Object System.Drawing.Size(80, 30)
$stopButton.Enabled = $false
$stopButton.Add_Click({
    if ($setupComboBox.SelectedIndex -eq -1) {
        $statusBox.AppendText("Please select a setup.`r`n")
        return
    }
    $selectedConfig = $configs[$setupComboBox.SelectedIndex]
    try {
        Stop-ContinuousBuild -BasePath $selectedConfig.BasePath
        $statusBox.AppendText("Stopped continuous build at $(Get-Date)`r`n")
        $startButton.Enabled = $true
        $stopButton.Enabled = $false
    } catch {
        $statusBox.AppendText("Error stopping build: $_`r`n")
    }
})
$form.Controls.Add($stopButton)

$currentTaskLabel = New-Object System.Windows.Forms.Label
$currentTaskLabel.Name = "currentTaskLabel"
$currentTaskLabel.Text = "Current Task: None"
$currentTaskLabel.Location = New-Object System.Drawing.Point(10, 290)
$currentTaskLabel.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($currentTaskLabel)

$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.Text = "Next Build: N/A"
$timerLabel.Location = New-Object System.Drawing.Point(10, 310)
$timerLabel.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($timerLabel)

$modeLabel = New-Object System.Windows.Forms.Label
$modeLabel.Text = "Mode: N/A"
$modeLabel.Location = New-Object System.Drawing.Point(10, 330)
$modeLabel.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($modeLabel)

# Timer for Countdown
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000  # Update every second
$timer.Add_Tick({
    if ($script:lastBuildTime -and $script:buildInterval) {
        $elapsed = [int]((Get-Date) - $script:lastBuildTime).TotalSeconds
        $remaining = $script:buildInterval - $elapsed
        if ($remaining -gt 0) {
            $minutes = [math]::Floor($remaining / 60)
            $seconds = $remaining % 60
            $timerLabel.Text = "Next Build: $minutes min $seconds sec"
        } else {
            $timerLabel.Text = "Next Build: Now"
            $script:lastBuildTime = Get-Date  # Reset timer after build
        }
    }
})

function Write-StatusGUI {
    param ([string]$Message)
    $statusBox.Invoke([Action]{ $statusBox.AppendText("$Message`r`n") })
}

# Check for existing build jobs on startup
if ($configs.Count -gt 0) {
    $selectedConfig = $configs[0]
    $flagFile = Join-Path -Path $selectedConfig.BasePath -ChildPath "continuous_build_running.flag"
    if (Test-Path $flagFile) {
        $jobId = Get-Content -Path $flagFile -ErrorAction SilentlyContinue
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
        if ($job -and $job.State -eq "Running") {
            $startButton.Enabled = $false
            $stopButton.Enabled = $true
            $script:lastBuildTime = Get-Date
            $script:buildInterval = 30
            $timer.Start()
        } else {
            Write-StatusGUI "Found stale flag file on startup. Cleaning up..."
            Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Id $jobId -ErrorAction SilentlyContinue
                Remove-Job -Id $jobId -ErrorAction SilentlyContinue
            }
        }
    }
}

$setupComboBox.Add_SelectedIndexChanged({
    $selectedConfig = $configs[$setupComboBox.SelectedIndex]
    $modeLabel.Text = if ($selectedConfig.SkipDocker) { "Mode: Basic (Manual Builds)" } else { "Mode: Advanced (Docker Builds)" }
    
    # Check if a build is running for the newly selected setup
    $flagFile = Join-Path -Path $selectedConfig.BasePath -ChildPath "continuous_build_running.flag"
    if (Test-Path $flagFile) {
        $jobId = Get-Content -Path $flagFile -ErrorAction SilentlyContinue
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
        if ($job -and $job.State -eq "Running") {
            $startButton.Enabled = $false
            $stopButton.Enabled = $true
            if (-not $timer.Enabled) {
                $script:lastBuildTime = Get-Date
                $script:buildInterval = 30
                $timer.Start()
            }
        } else {
            $startButton.Enabled = $true
            $stopButton.Enabled = $false
            $timer.Stop()
            $timerLabel.Text = "Next Build: N/A"
            $currentTaskLabel.Text = "Current Task: None"
            Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Id $jobId -ErrorAction SilentlyContinue
                Remove-Job -Id $jobId -ErrorAction SilentlyContinue
            }
        }
    } else {
        $startButton.Enabled = $true
        $stopButton.Enabled = $false
        $timer.Stop()
        $timerLabel.Text = "Next Build: N/A"
        $currentTaskLabel.Text = "Current Task: None"
    }
})

if ($configs.Count -gt 0) { 
    $modeLabel.Text = if ($configs[0].SkipDocker) { "Mode: Basic (Manual Builds)" } else { "Mode: Advanced (Docker Builds)" }
}

$form.ShowDialog()