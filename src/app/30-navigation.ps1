# =============================================================================
# 6. NAVIGATION
# =============================================================================
if ($btnMenuInstall) { $btnMenuInstall.Add_Click({ Show-Page "install" }) }
if ($btnMenuWinget) { $btnMenuWinget.Add_Click({ Show-Page "winget" }) }
if ($btnMenuTweaks) { $btnMenuTweaks.Add_Click({ Show-Page "tweaks" }) }
if ($btnMenuConfig) { $btnMenuConfig.Add_Click({ Show-Page "config" }) }
if ($btnMenuDebloat) { $btnMenuDebloat.Add_Click({ Show-Page "debloat" }) }
if ($btnMenuUpdates) { $btnMenuUpdates.Add_Click({ Show-Page "updates" }) }
if ($btnMenuBackup) { $btnMenuBackup.Add_Click({ Show-Page "backup" }) }
if ($btnExit) { $btnExit.Add_Click({ if ($window) { $window.Close() } }) }
if ($btnClearLog -and $logBox) { $btnClearLog.Add_Click({ $logBox.Clear() }) }

$btnTabCurated = Get-UIElement "btnTabCurated"
$btnTabWinget  = Get-UIElement "btnTabWinget"
if ($btnTabCurated) { $btnTabCurated.Add_Click({ Switch-AppTab "curated" }) }
if ($btnTabWinget)  { $btnTabWinget.Add_Click({ Switch-AppTab "winget" }) }

