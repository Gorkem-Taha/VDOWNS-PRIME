# =============================================================================
# 13B. PC HEALTH SCORE & 1-CLICK PRIME OPTIMIZATION
# =============================================================================
function Get-SystemHealthScore {
    $score = 100
    $deductions = [System.Collections.ArrayList]::new()

    # 1. Telemetry DiagTrack service
    try {
        $svc = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $score -= 15
            [void]$deductions.Add("Telemetry service active (-15)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    # 2. AllowTelemetry registry
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -EA SilentlyContinue).AllowTelemetry
        if ($val -ne 0) {
            $score -= 15
            [void]$deductions.Add("Telemetry policies enabled (-15)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    # 3. GameDVR
    try {
        $g = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -EA SilentlyContinue).GameDVR_Enabled
        if ($g -eq 1) {
            $score -= 10
            [void]$deductions.Add("Xbox GameDVR background recorder active (-10)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    # 4. SysMain
    try {
        $sm = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sm -and $sm.Status -eq "Running") {
            $score -= 10
            [void]$deductions.Add("SysMain Superfetch active (-10)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    # 5. Restore Point Check (Instant Registry Lookup)
    try {
        $rpReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        $lastSeq = (Get-ItemProperty -Path $rpReg -Name "LastSequenceNumber" -ErrorAction SilentlyContinue).LastSequenceNumber
        if ($null -eq $lastSeq -or $lastSeq -le 0) {
            $score -= 10
            [void]$deductions.Add("No recent System Restore Point found (-10)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    # 6. File extensions hidden
    try {
        $he = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -EA SilentlyContinue).HideFileExt
        if ($he -ne 0) {
            $score -= 10
            [void]$deductions.Add("Known file extensions hidden (-10)")
        }
    } catch { Write-Verbose "Health check skipped: $($_.Exception.Message)" }

    $finalScore = [math]::Max(0, [math]::Min(100, $score))
    return @{ Score = $finalScore; Deductions = $deductions }
}

function Update-HealthScoreUI {
    $res = Get-SystemHealthScore
    if ($lblHealthScore) {
        $lblHealthScore.Text = "$($res.Score)/100"
        if ($res.Score -ge 80) {
            $lblHealthScore.Foreground = (Get-VdBrush "#3FB950")
        } elseif ($res.Score -ge 50) {
            $lblHealthScore.Foreground = (Get-VdBrush "#D29922")
        } else {
            $lblHealthScore.Foreground = (Get-VdBrush "#F85149")
        }
    }
}

if ($btnRefreshHealth) {
    $btnRefreshHealth.Add_Click({
        Update-HealthScoreUI
        Write-AppLog "System optimization health score refreshed." "INFO"
    })
}

if ($btnPrimeBoost) {
    $btnPrimeBoost.Add_Click({
        $msg = "⚡ PRIME 1-CLICK SYSTEM OPTIMIZATION`n`nThis action will safely apply recommended system baselines:`n1. Create a System Restore Point ('VDOWNS_PrimeBoost')`n2. Disable Windows Telemetry & DiagTrack background data collection`n3. Disable Xbox Game DVR background recording`n4. Disable SysMain Superfetch SSD thrashing`n5. Enable file extensions and Dark Mode`n6. Purge temporary Windows cache`n`nDo you want to proceed?"
        $res = [System.Windows.MessageBox]::Show($msg, "Confirm Prime Optimization", "YesNo", "Question")
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        Write-AppLog "Executing 1-Click Prime Optimization pipeline..." "ACTION"
        $btnPrimeBoost.IsEnabled = $false

        Start-VdTask 'Invoke-VdPrimeBoost' @{ SH = (New-VdTaskContext) } -OnComplete {
            $btnPrimeBoost.IsEnabled = $true
            Update-HealthScoreUI
            Write-AppLog "Health score refreshed after Prime Optimization." "INFO"
        }
    })
}

