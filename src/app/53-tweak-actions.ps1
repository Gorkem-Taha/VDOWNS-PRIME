Add-TweakGroup "Essential Privacy" $essentialTweaks "#F85149"
Add-TweakGroup "Interface Explorer" $uiTweaks "#58A6FF"
Add-TweakGroup "Performance Power" $perfTweaks "#3FB950"

# Apply Tweaks (Async Runspace to prevent UI freezing)
$btnApplyTweaks.Add_Click({
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected.", "Info", "OK", "Information")
        return
    }

    Write-AppLog "Applying $($selected.Count) selected tweaks asynchronously..." "ACTION"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $false }
    if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $false }

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Do.ToString(); State = $t.State }
    }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnApply = $btnApplyTweaks
        BtnRevert = $btnRevertTweaks
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Tweaks, $SH, $Lib)
        . ([scriptblock]::Create($Lib))
        # Any error inside a tweak is a failure (it used to be logged as SUCCESS)
        $ErrorActionPreference = 'Stop'
        $applied = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                # Snapshot first; if that fails the tweak is skipped so Revert can always restore
                Save-VdTweakState $tName $item.State
                # Registry tweaks write into keys that may not exist yet on a fresh profile
                foreach ($e in @($item.State)) { if ($e -and $e.Reg -and -not (Test-Path -LiteralPath $e.Reg)) { New-Item -Path $e.Reg -Force | Out-Null } }
                $global:LASTEXITCODE = 0
                $null = & $sBlock
                if ($LASTEXITCODE -ne 0) { throw "command exited with code $LASTEXITCODE" }
                $applied++
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [SUCCESS] Applied: $tName`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $err = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [ERROR] Failed: $tName - $err`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            }
        }

        if ($applied -gt 0) {
            try { $SH.Window.Dispatcher.Invoke([action]{
                $ts = Get-Date -Format 'HH:mm:ss'
                $SH.LogBox.AppendText("[$ts] [INFO] Refreshing Windows Explorer...`r`n")
                $SH.LogBox.ScrollToEnd()
            }) } catch {}
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }

        return $applied
    })
    [void]$ps.AddParameter("Tweaks", $tweakData)
    [void]$ps.AddParameter("SH", $syncHash)
    [void]$ps.AddParameter("Lib", ($script:VdNativeLib + "`r`n" + $script:TweakStateLib))
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
        $count = @($result) | Select-Object -Last 1
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $true }
        if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $true }
        Write-AppLog "Tweak deployment completed ($count applied)." "SUCCESS"
    }
})

# Revert Tweaks (Async Runspace to prevent UI freezing)
$btnRevertTweaks.Add_Click({
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected to revert.", "Info", "OK", "Information")
        return
    }

    Write-AppLog "Reverting $($selected.Count) selected tweaks asynchronously..." "WARN"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $false }
    if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $false }

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Undo.ToString(); State = $t.State }
    }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnApply = $btnApplyTweaks
        BtnRevert = $btnRevertTweaks
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Tweaks, $SH, $Lib)
        . ([scriptblock]::Create($Lib))
        $ErrorActionPreference = 'Stop'
        $reverted = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                # Prefer the exact pre-tweak snapshot; fall back to the generic Undo block
                $global:LASTEXITCODE = 0
                $how = if (Restore-VdTweakState $tName) { "original state restored" } else { $null = & $sBlock; "default undo applied (no snapshot)" }
                if ($LASTEXITCODE -ne 0) { throw "command exited with code $LASTEXITCODE" }
                $reverted++
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [SUCCESS] Reverted: $tName - $how`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $err = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [ERROR] Failed to revert: $tName - $err`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            }
        }

        if ($reverted -gt 0) {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }

        return $reverted
    })
    [void]$ps.AddParameter("Tweaks", $tweakData)
    [void]$ps.AddParameter("SH", $syncHash)
    [void]$ps.AddParameter("Lib", ($script:VdNativeLib + "`r`n" + $script:TweakStateLib))
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
        $count = @($result) | Select-Object -Last 1
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $true }
        if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $true }
        Write-AppLog "Tweak reversion completed ($count reverted)." "INFO"
    }
})

