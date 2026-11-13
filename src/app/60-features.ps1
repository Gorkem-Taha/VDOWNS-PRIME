# =============================================================================
# 10. FEATURES & CONFIGURATION
# =============================================================================
function Add-FeatureCard {
    param([string]$Name, [string]$WinName, [string]$Description)
    
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $card.Background = $surfaceBrush
    $card.BorderBrush = $borderBrush
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.Padding = [System.Windows.Thickness]::new(18, 14, 18, 14)
    $card.Margin = [System.Windows.Thickness]::new(0, 5, 0, 5)
    
    $dockPanel = New-Object System.Windows.Controls.DockPanel
    
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.VerticalAlignment = "Center"
    $cb.Margin = [System.Windows.Thickness]::new(0, 0, 15, 0)
    [System.Windows.Controls.DockPanel]::SetDock($cb, "Right")
    
    $info = New-Object System.Windows.Controls.StackPanel
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $Name
    $nameText.FontSize = 15
    $nameText.FontWeight = "SemiBold"
    $nameText.Foreground = $textBrush
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $Description
    $descText.FontSize = 12
    $descText.Foreground = $textDimBrush
    $descText.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)
    [void]$info.Children.Add($nameText)
    [void]$info.Children.Add($descText)
    
    [void]$dockPanel.Children.Add($cb)
    [void]$dockPanel.Children.Add($info)
    $card.Child = $dockPanel
    
        $targetConfigBox = if ($script:featureContainer) { $script:featureContainer } elseif ($configContainer) { $configContainer } else { $script:configContainer }
    if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($card) }
    [void]$script:FeatureList.Add(@{Check=$cb; WinName=$WinName; Name=$Name})
}

# Script-scope target for the section headers ($targetConfigBox inside Add-FeatureCard is function-local)
$targetConfigBox = if ($featureContainer) { $featureContainer } else { Get-UIElement "featureContainer" }

$featHeader = New-Object System.Windows.Controls.TextBlock
$featHeader.Text = "Windows Optional Features"
$featHeader.FontSize = 18
$featHeader.FontWeight = "SemiBold"
$featHeader.Foreground = $accentBrush
$featHeader.Margin = [System.Windows.Thickness]::new(0, 5, 0, 15)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($featHeader) }

Add-FeatureCard "Hyper-V Platform" "Microsoft-Hyper-V-All" "Hardware virtualization for VMs and Docker (Pro/Enterprise/Education)"
Add-FeatureCard "WSL 2 (Linux)" "Microsoft-Windows-Subsystem-Linux,VirtualMachinePlatform" "Windows Subsystem for Linux + Virtual Machine Platform (required for WSL 2)"
Add-FeatureCard "Windows Sandbox" "Containers-DisposableClientVM" "Isolated desktop environment for safe testing (Pro/Enterprise/Education)"
Add-FeatureCard ".NET Framework 3.5" "NetFx3" "Required by legacy applications and games"

# Maintenance header
$maintHeader = New-Object System.Windows.Controls.TextBlock
$maintHeader.Text = "System Maintenance"
$maintHeader.FontSize = 18
$maintHeader.FontWeight = "SemiBold"
$maintHeader.Foreground = $dangerBrush
$maintHeader.Margin = [System.Windows.Thickness]::new(0, 25, 0, 10)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($maintHeader) }

$maintDesc = New-Object System.Windows.Controls.TextBlock
$maintDesc.Text = "Deep System Clean configures all cleanup categories and runs the extended Disk Cleanup utility in the background."
$maintDesc.Foreground = $textDimBrush
$maintDesc.FontSize = 13
$maintDesc.TextWrapping = "Wrap"
$maintDesc.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($maintDesc) }

if ($btnEnableFeatures) { $btnEnableFeatures.Add_Click({
    # DISM can take minutes: run it in a separate process and stream the output instead of freezing the UI
    $names = @($script:FeatureList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.WinName -split ',' } | Where-Object { $_ -match '^[A-Za-z0-9\-\.]+$' })
    if ($names.Count -eq 0) { [System.Windows.MessageBox]::Show("No features selected.", "Info", "OK", "Information"); return }
    $list = ($names | ForEach-Object { "'$_'" }) -join ', '
    $featureScript = @"
`$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name EditionID -ErrorAction SilentlyContinue).EditionID
if (`$edition -match 'Core') { Write-Output "Note: Windows `$edition (Home) does not include Hyper-V or Windows Sandbox." }
`$restart = `$false
foreach (`$f in @($list)) {
    Write-Output "Enabling `$f ..."
    try {
        `$r = Enable-WindowsOptionalFeature -Online -FeatureName `$f -All -NoRestart -ErrorAction Stop
        if (`$r.RestartNeeded) { `$restart = `$true }
        Write-Output "  OK: `$f"
    } catch {
        Write-Output "  FAILED: `$f - `$(`$_.Exception.Message)"
    }
}
if (`$restart) { Write-Output 'A RESTART is required to finish enabling the selected features.' }
"@
    Write-AppLog "Enabling $($names.Count) Windows feature(s) in the background..." "ACTION"
    Start-PSStreamingCommand $featureScript
}) }

if ($btnDeepClean) { $btnDeepClean.Add_Click({
    $result = [System.Windows.MessageBox]::Show("This will run Disk Cleanup in the background for a safe set of categories:`ntemporary files, caches, logs, crash dumps, Delivery Optimization files and superseded Windows Update files.`n`nNot touched: Downloads, Recycle Bin, previous Windows installations (rollback), Windows ESD files (Reset this PC) and language packs.`nNote: after Update Cleanup, already installed updates can no longer be uninstalled.`n`nContinue?", "Confirm Deep Clean", "YesNo", "Warning")
    if ($result -ne "Yes") { return }
    Write-AppLog "Starting Deep System Clean..." "ACTION"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        # Allow-list only: user data (Downloads, Recycle Bin) and recovery data (previous
        # installations, ESD files used by "Reset this PC", language packs) are never selected.
        # Every other handler gets its flag removed, which also clears flags set by v3.3.1.
        $safeHandlers = @(
            "Active Setup Temp Folders", "BranchCache", "D3D Shader Cache", "Delivery Optimization Files",
            "Diagnostic Data Viewer database files", "Downloaded Program Files", "Feedback Hub Archive log files",
            "Internet Cache Files", "Old ChkDsk Files", "RetailDemo Offline Content", "Setup Log Files",
            "System error memory dump files", "System error minidump files", "Temporary Files",
            "Temporary Setup Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files",
            "Windows Error Reporting Files", "Windows Upgrade Log Files"
        )
        $enabled = 0
        Get-ChildItem $regPath | ForEach-Object {
            if ($safeHandlers -contains $_.PSChildName) {
                New-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -PropertyType DWORD -Force | Out-Null
                $enabled++
            } else {
                Remove-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Force -ErrorAction SilentlyContinue
            }
        }
        Write-AppLog "Disk Cleanup categories selected: $enabled (safe allow-list)." "INFO"
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden
        Write-AppLog "Deep Clean started in background." "SUCCESS"
    } catch { Write-AppLog "Clean Error: $($_.Exception.Message)" "ERROR" }
}) }

