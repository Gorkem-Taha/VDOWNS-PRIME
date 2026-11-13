# 14. LIVE HARDWARE TELEMETRY & CONSOLE DRAWER
# =============================================================================

# A. Collapsible Log Drawer & Copy Handler
if ($btnToggleLog -and $logPanelGrid) {
    $script:logExpanded = $false
    $btnToggleLog.Add_Click({
        if ($script:logExpanded) {
            $logPanelGrid.Height = 32
            $logBox.Visibility = "Collapsed"
            $btnToggleLog.Content = "▲ Expand"
            $script:logExpanded = $false
        } else {
            $logPanelGrid.Height = 130
            $logBox.Visibility = "Visible"
            $btnToggleLog.Content = "▼ Collapse"
            $script:logExpanded = $true
        }
    })
}

if ($btnCopyLog -and $logBox) {
    $btnCopyLog.Add_Click({
        try {
            if (-not [string]::IsNullOrEmpty($logBox.Text)) {
                [System.Windows.Clipboard]::SetText($logBox.Text)
                Write-AppLog "Activity logs copied to clipboard." "SUCCESS"
            }
        } catch { Write-AppLog "Could not copy the log to the clipboard: $($_.Exception.Message)" "WARN" }
    })
}

if ($btnClearLog -and $logBox) {
    $btnClearLog.Add_Click({
        $logBox.Clear()
        if ($lblLogCount) { $lblLogCount.Text = "CLEARED" }
    })
}

# B. Live Hardware Telemetry Engine
try {
    $prodName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName" -ErrorAction SilentlyContinue).ProductName
    $dispVer  = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($lblOsInfo) {
        $lblOsInfo.Text = if ($prodName) { "$prodName ($dispVer)" } else { "Windows 10/11" }
    }
} catch {
    if ($lblOsInfo) { $lblOsInfo.Text = "Windows 10/11" }
}

$script:telemetryTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:telemetryTimer.Interval = [TimeSpan]::FromSeconds(3.5)
$script:telemetryTimer.Add_Tick({
    try {
        # 1. Native Win32 RAM Telemetry (0.01ms execution, zero RPC/WMI overhead)
        $mem = [NativeSysInfo]::GetMemory()
        if ($mem) {
            $totalGB = [math]::Round($mem.ullTotalPhys / 1GB, 1)
            $availGB = [math]::Round($mem.ullAvailPhys / 1GB, 1)
            $usedGB  = [math]::Round($totalGB - $availGB, 1)
            $ramPct  = [int]$mem.dwMemoryLoad
            if ($lblRamPct) { $lblRamPct.Text = "${usedGB}/${totalGB} GB (${ramPct}%)" }
            if ($pbRam) { $pbRam.Value = $ramPct }
        }

        # 2. Targeted C: Drive Telemetry (Direct query without enumerating removable/network drives)
        $cDrive = New-Object System.IO.DriveInfo("C")
        if ($cDrive.IsReady) {
            $dFreeGB  = [math]::Round($cDrive.AvailableFreeSpace / 1GB, 1)
            $dTotalGB = [math]::Round($cDrive.TotalSize / 1GB, 1)
            $dUsedGB  = [math]::Round($dTotalGB - $dFreeGB, 1)
            $dPct     = [math]::Min(100, [math]::Max(0, [int](($dUsedGB / $dTotalGB) * 100)))
            if ($lblDiskPct) { $lblDiskPct.Text = "${dFreeGB} GB free" }
            if ($pbDisk) { $pbDisk.Value = $dPct }
        }

        # 3. Native Win32 CPU Load Telemetry (0.01ms GetSystemTimes, zero thread stalls)
        $load = [NativeSysInfo]::GetCpuLoad()
        if ($lblCpuPct) { $lblCpuPct.Text = "${load} %" }
        if ($pbCpu) { $pbCpu.Value = $load }
    } catch { Write-Verbose "Telemetry tick skipped: $($_.Exception.Message)" }   # runs every 3.5 s: never log
})
$script:telemetryTimer.Start()

# Initial logs
Write-AppLog "VDOWNS PRIME v$($script:VdownsVersion) (Fluent UI Edition) initialized." "INFO"
Write-AppLog "Hardware-accelerated WPF subsystem online." "SUCCESS"
try {
    $wv = (Invoke-VdNative 'winget.exe' @('--version') 'UTF8').Output.Trim()
    Write-AppLog "Winget detected: $wv" "INFO"
} catch { Write-AppLog "Winget not found! App Center may not work." "ERROR" }
Update-HealthScoreUI

# Elevated with a different (admin) account? Then every HKCU tweak, backup and startup change
# lands in that account's profile, not in the signed-in user's.
try {
    $desktopUser = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
    $runAsUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    if ($desktopUser -and $runAsUser -and $desktopUser -ne $runAsUser) {
        Write-AppLog "Running as '$runAsUser' but the signed-in user is '$desktopUser'. Per-user settings will apply to '$runAsUser'." "WARN"
        if (-not $script:SmokeTest) { [System.Windows.MessageBox]::Show("VDOWNS PRIME is running as '$runAsUser', but the signed-in desktop user is '$desktopUser'.`n`nPer-user changes (dark mode, Explorer options, startup items, developer backups) will apply to '$runAsUser', not to '$desktopUser'.", "Different User Account", "OK", "Warning") | Out-Null }
    }
} catch { Write-Verbose "Signed-in user check skipped: $($_.Exception.Message)" }
Write-AppLog "System Architect is ready. Select a category from the sidebar to begin." "SUCCESS"

# 15. SHOW WINDOW
# =============================================================================
if ($window) {
    $window.Add_Closed({
        if ($script:telemetryTimer) { $script:telemetryTimer.Stop() }
    })
}
if ($script:SmokeTest) {
    $window.Add_ContentRendered({
        $errLines = @($logBox.Text -split "`r?`n" | Where-Object { $_ -match '\[ERROR\]' })
        $report = @(
            "SMOKE_OK version=$($script:VdownsVersion) ps=$($PSVersionTable.PSVersion) controls=$($script:Controls.Count) apps=$($script:InstallList.Count) tweaks=$($script:TweakList.Count) debloat=$($script:DebloatList.Count) features=$($script:FeatureList.Count) chips=$((Get-UIElement 'filterChipsPanel').Children.Count) logErrors=$($errLines.Count)"
            "--- activity log ---"
            $logBox.Text
        )
        Set-Content -Path $script:SmokeReport -Value $report -Encoding UTF8
        $window.Close()
    })
}
$window.ShowDialog() | Out-Null

} catch {
    if ($script:SmokeTest) {
        Set-Content -Path $script:SmokeReport -Value "SMOKE_FAIL line=$($_.InvocationInfo.ScriptLineNumber) $($_.Exception.Message)" -Encoding UTF8
        exit 1
    }
    [System.Windows.MessageBox]::Show(
        "Critical Error Occurred:`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)",
        "VDOWNS PRIME Error", "OK", "Error")
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    # Read-Host removed for noConsole GUI
}
