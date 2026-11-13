# =============================================================================
# 13F. WINDOWS UPDATE DEFERRAL CONTROLS
# =============================================================================
if ($btnPauseUpdates) {
    $btnPauseUpdates.Add_Click({
        $res = [System.Windows.MessageBox]::Show("Do you want to pause Windows Updates for 35 days?`n(Registry: PauseQualityUpdates & PauseFeatureUpdates)", "Pause Updates", "YesNo", "Question")
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $end = (Get-Date).AddDays(35).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            try {
                if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force -ErrorAction Stop | Out-Null }
                foreach ($pair in @(@("PauseFeatureUpdatesStartTime", $now), @("PauseFeatureUpdatesEndTime", $end),
                                    @("PauseQualityUpdatesStartTime", $now), @("PauseQualityUpdatesEndTime", $end),
                                    @("PauseUpdatesExpiryTime", $end))) {
                    New-ItemProperty -Path $wuPath -Name $pair[0] -Value $pair[1] -PropertyType String -Force -ErrorAction Stop | Out-Null
                }
                Write-AppLog "Windows Updates paused for 35 days until: $end" "SUCCESS"
                [System.Windows.MessageBox]::Show("Windows Updates paused until:`n$end", "Updates Paused", "OK", "Information")
            } catch {
                Write-AppLog "Could not pause Windows Updates: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

if ($btnResumeUpdates) {
    $btnResumeUpdates.Add_Click({
        $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        $props = @("PauseFeatureUpdatesStartTime", "PauseFeatureUpdatesEndTime", "PauseQualityUpdatesStartTime", "PauseQualityUpdatesEndTime", "PauseUpdatesExpiryTime")
        foreach ($p in $props) {
            Remove-ItemProperty -Path $wuPath -Name $p -Force -EA SilentlyContinue
        }
        Write-AppLog "Windows Updates resumed. Standard automatic checks active." "SUCCESS"
        [System.Windows.MessageBox]::Show("Windows Updates resumed to normal automatic checks.", "Updates Resumed", "OK", "Information")
    })
}

