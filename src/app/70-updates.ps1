# =============================================================================
# 12. UPDATE & REPAIR CENTER
# =============================================================================
if ($btnUpdateApps) {
    $btnUpdateApps.Add_Click({
        Write-AppLog "Starting: Update All Apps..." "ACTION"
        Start-StreamingCommand "winget" "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
    })
}

# PSWindowsUpdate: pinned version, Authenticode-verified before import (runs in the child powershell.exe)
$script:PSWUBootstrap = @'
#@include lib/PSWUBootstrap.ps1
'@

if ($btnUpdateWindows) {
    $btnUpdateWindows.Add_Click({
        Write-AppLog "Starting: Windows Update..." "ACTION"
        Start-PSStreamingCommand ($script:PSWUBootstrap + "`r`nGet-WindowsUpdate -Install -AcceptAll -IgnoreReboot")
    })
}

if ($btnUpdateDrivers) {
    $btnUpdateDrivers.Add_Click({
        Write-AppLog "Starting: Driver Updates..." "ACTION"
        Start-PSStreamingCommand ($script:PSWUBootstrap + "`r`nGet-WindowsUpdate -UpdateType Driver -Install -AcceptAll -IgnoreReboot")
    })
}

if ($btnUpdateStore) {
    $btnUpdateStore.Add_Click({
        Write-AppLog "Starting: MS Store Updates..." "ACTION"
        Start-StreamingCommand "winget" "upgrade --all --accept-package-agreements --accept-source-agreements --source msstore --include-unknown"
    })
}

if ($btnRepairSfc) {
    $btnRepairSfc.Add_Click({
        Write-AppLog "Starting: SFC Scan..." "ACTION"
        Start-StreamingCommand "sfc" "/scannow"
    })
}

if ($btnRepairDism) {
    $btnRepairDism.Add_Click({
        Write-AppLog "Starting: DISM Repair..." "ACTION"
        Start-StreamingCommand "dism" "/Online /Cleanup-Image /RestoreHealth"
    })
}

if ($btnResetNetwork) {
    $btnResetNetwork.Add_Click({
        Write-AppLog "Starting: Network Reset..." "ACTION"
        Start-PSStreamingCommand 'ipconfig /flushdns; netsh winsock reset; netsh int ip reset; Write-Host "Network stack reset complete. Please reboot."'
    })
}

if ($btnFixUpdates) {
    $btnFixUpdates.Add_Click({
        $result = [System.Windows.MessageBox]::Show("This will forcibly reset Windows Update components.`nContinue?", "Emergency Fix", "YesNo", "Warning")
        if ($result -ne "Yes") { return }
        Write-AppLog "Starting: Emergency WU Fix..." "WARN"
        Start-PSStreamingCommand 'Stop-Service wuauserv -Force; Stop-Service cryptSvc -Force; Stop-Service bits -Force; Remove-Item "C:\\Windows\\SoftwareDistribution" -Recurse -Force; Start-Service wuauserv; Start-Service cryptSvc; Start-Service bits; Write-Host "WU components successfully purged and reset."'
    })
}

