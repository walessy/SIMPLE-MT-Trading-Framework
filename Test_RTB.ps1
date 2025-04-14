Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Rainbow RichTextBox Auto-Update Example"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# Create the RichTextBox
$richTextBox = New-Object System.Windows.Forms.RichTextBox
$richTextBox.Location = New-Object System.Drawing.Point(10, 10)
$richTextBox.Size = New-Object System.Drawing.Size(460, 300)
$richTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Define rainbow colors as script-scope variables so they persist between timer ticks
$script:rainbowColors = @(
    [System.Drawing.Color]::Red,
    [System.Drawing.Color]::Orange, 
    [System.Drawing.Color]::Yellow,
    [System.Drawing.Color]::Green,
    [System.Drawing.Color]::Blue,
    [System.Drawing.Color]::Indigo,
    [System.Drawing.Color]::Violet
)
$script:colorIndex = 0

# Create a timer for automatic updates every second
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 # 1000 milliseconds = 1 second
$timer.Add_Tick({
    # Get the current rainbow color and increment index for next time
    $currentColor = $script:rainbowColors[$script:colorIndex]
    Write-Host "Using color: $($currentColor.Name) at index $script:colorIndex"
    $script:colorIndex = ($script:colorIndex + 1) % $script:rainbowColors.Count
    
    # Temporarily suspend drawing to update silently
    $richTextBox.SuspendLayout()
    
    # Move cursor to end and set the color
    $richTextBox.SelectionStart = $richTextBox.TextLength
    $richTextBox.SelectionLength = 0
    $richTextBox.SelectionColor = $currentColor
    
    # Add the text with timestamp
    $newText = "Rainbow update at $(Get-Date -Format 'HH:mm:ss')`r`n"
    $richTextBox.AppendText($newText)
    
    # Resume layout
    $richTextBox.ResumeLayout()
    
    # Auto-scroll to the bottom
    $richTextBox.SelectionStart = $richTextBox.Text.Length
    $richTextBox.ScrollToCaret()
})

# Create start/stop buttons
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(120, 320)
$startButton.Size = New-Object System.Drawing.Size(120, 30)
$startButton.Text = "Start Rainbow Update"
$startButton.Add_Click({
    # Reset color index when starting
    $script:colorIndex = 0
    $timer.Start()
    $startButton.Enabled = $false
    $stopButton.Enabled = $true
})

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Location = New-Object System.Drawing.Point(250, 320)
$stopButton.Size = New-Object System.Drawing.Size(120, 30)
$stopButton.Text = "Stop Rainbow Update"
$stopButton.Enabled = $false
$stopButton.Add_Click({
    $timer.Stop()
    $startButton.Enabled = $true
    $stopButton.Enabled = $false
})

# Add a clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(380, 320)
$clearButton.Size = New-Object System.Drawing.Size(100, 30)
$clearButton.Text = "Clear Text"
$clearButton.Add_Click({
    $richTextBox.Clear()
})

# Add controls to the form
$form.Controls.Add($richTextBox)
$form.Controls.Add($startButton)
$form.Controls.Add($stopButton)
$form.Controls.Add($clearButton)

# Set up form closing event to ensure timer is stopped
$form.Add_FormClosing({
    $timer.Stop()
})

# Show the form
$form.ShowDialog()