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
    } catch {}

    # 2. AllowTelemetry registry
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -EA SilentlyContinue).AllowTelemetry
        if ($val -ne 0) {
            $score -= 15
            [void]$deductions.Add("Telemetry policies enabled (-15)")
        }
    } catch {}

    # 3. GameDVR
    try {
        $g = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -EA SilentlyContinue).GameDVR_Enabled
        if ($g -eq 1) {
            $score -= 10
            [void]$deductions.Add("Xbox GameDVR background recorder active (-10)")
        }
    } catch {}

    # 4. SysMain
    try {
        $sm = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sm -and $sm.Status -eq "Running") {
            $score -= 10
            [void]$deductions.Add("SysMain Superfetch active (-10)")
        }
    } catch {}

    # 5. Restore Point Check (Instant Registry Lookup)
    try {
        $rpReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        $lastSeq = (Get-ItemProperty -Path $rpReg -Name "LastSequenceNumber" -ErrorAction SilentlyContinue).LastSequenceNumber
        if ($null -eq $lastSeq -or $lastSeq -le 0) {
            $score -= 10
            [void]$deductions.Add("No recent System Restore Point found (-10)")
        }
    } catch {}

    # 6. File extensions hidden
    try {
        $he = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -EA SilentlyContinue).HideFileExt
        if ($he -ne 0) {
            $score -= 10
            [void]$deductions.Add("Known file extensions hidden (-10)")
        }
    } catch {}

    $finalScore = [math]::Max(0, [math]::Min(100, $score))
    return @{ Score = $finalScore; Deductions = $deductions }
}

function Update-HealthScoreUI {
    $res = Get-SystemHealthScore
    if ($lblHealthScore) {
        $lblHealthScore.Text = "$($res.Score)/100"
        if ($res.Score -ge 80) {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#3FB950")
        } elseif ($res.Score -ge 50) {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#D29922")
        } else {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#F85149")
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

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("btnPrimeBoost", $btnPrimeBoost)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

            try {
                Log-Msg "[1/6] Creating System Restore Point..." "ACTION"
                try {
                    Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
                    Checkpoint-Computer -Description "VDOWNS_PrimeBoost" -RestorePointType "MODIFY_SETTINGS" -EA SilentlyContinue
                    Log-Msg "System Restore Point created." "SUCCESS"
                } catch { Log-Msg "Restore Point skipped: $($_.Exception.Message)" "WARN" }

                Log-Msg "[2/6] Disabling Windows Telemetry & Advertising ID..." "ACTION"
                foreach ($k in @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR", "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                    if (-not (Test-Path $k)) { New-Item -Path $k -Force -EA SilentlyContinue | Out-Null }
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Stop-Service -Name "DiagTrack" -Force -EA SilentlyContinue
                Set-Service -Name "DiagTrack" -StartupType Disabled -EA SilentlyContinue

                Log-Msg "[3/6] Disabling Xbox GameDVR background recording..." "ACTION"
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force -EA SilentlyContinue

                Log-Msg "[4/6] Disabling SysMain Superfetch..." "ACTION"
                Stop-Service -Name "SysMain" -Force -EA SilentlyContinue
                Set-Service -Name "SysMain" -StartupType Disabled -EA SilentlyContinue

                Log-Msg "[5/6] Applying Dark Mode & Showing File Extensions..." "ACTION"
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force -EA SilentlyContinue

                Log-Msg "[6/6] Purging Temporary File Caches..." "ACTION"
                Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue

                Log-Msg "Prime 1-Click Optimization finished. Review the log above for any skipped steps." "SUCCESS"
            } catch {
                Log-Msg "Optimization error: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnPrimeBoost) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnPrimeBoost.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            Update-HealthScoreUI
            Write-AppLog "Health score refreshed after Prime Optimization." "INFO"
        }
    })
}

