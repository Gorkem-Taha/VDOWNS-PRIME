Add-TweakGroup -Title "Essential Privacy" -Tweaks $essentialTweaks -Color "#F85149"
Add-TweakGroup -Title "Interface Explorer" -Tweaks $uiTweaks -Color "#58A6FF"
Add-TweakGroup -Title "Performance Power" -Tweaks $perfTweaks -Color "#3FB950"

# Apply / revert the selected tweaks (background task; see Invoke-VdTweakBatch)
function Start-TweakBatch {
    param([ValidateSet('Apply', 'Revert')][string]$Mode)
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected$(if ($Mode -eq 'Revert') { ' to revert' }).", "Info", "OK", "Information")
        return
    }
    Write-AppLog "$(if ($Mode -eq 'Apply') { 'Applying' } else { 'Reverting' }) $($selected.Count) selected tweaks asynchronously..." $(if ($Mode -eq 'Apply') { 'ACTION' } else { 'WARN' })
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $btnApplyTweaks.IsEnabled = $false
    $btnRevertTweaks.IsEnabled = $false

    $tweakData = @(foreach ($t in $selected) {
        @{ Name = $t.Name; ScriptStr = $(if ($Mode -eq 'Apply') { $t.Do.ToString() } else { $t.Undo.ToString() }); State = $t.State }
    })
    $onDone = if ($Mode -eq 'Apply') {
        { param($result) $count = @($result) | Select-Object -Last 1; Complete-TweakBatch; Write-AppLog "Tweak deployment completed ($count applied)." "SUCCESS" }
    } else {
        { param($result) $count = @($result) | Select-Object -Last 1; Complete-TweakBatch; Write-AppLog "Tweak reversion completed ($count reverted)." "INFO" }
    }
    Start-VdTask 'Invoke-VdTweakBatch' @{ Tweaks = $tweakData; Mode = $Mode; SH = (New-VdTaskContext) } -OnComplete $onDone
}

function Complete-TweakBatch {
    $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    $btnApplyTweaks.IsEnabled = $true
    $btnRevertTweaks.IsEnabled = $true
}

$btnApplyTweaks.Add_Click({ Start-TweakBatch 'Apply' })
$btnRevertTweaks.Add_Click({ Start-TweakBatch 'Revert' })
