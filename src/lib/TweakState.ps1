$VdStateRoot = 'HKCU:\Software\VDOWNS\TweakState'
$VdUltimatePlanGuid = 'c4e0702f-b217-4220-b268-5cbd645bac82'

function Get-VdRegSnapshot([string]$Path, [string]$Name) {
    $snap = @{ Path = $Path; Name = $Name; Exists = $false }
    if (Test-Path -LiteralPath $Path) {
        $key = Get-Item -LiteralPath $Path
        if ($key.GetValueNames() -contains $Name) {
            $snap.Exists = $true
            $snap.Kind = $key.GetValueKind($Name).ToString()
            $val = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
            if ($val -is [byte[]]) { $snap.Value = [Convert]::ToBase64String($val); $snap.IsBase64 = $true } else { $snap.Value = $val }
        }
    }
    $snap
}

function Restore-VdRegSnapshot($Snap) {
    if (-not $Snap) { return }
    if ($Snap.Exists) {
        if (-not (Test-Path -LiteralPath $Snap.Path)) { New-Item -Path $Snap.Path -Force | Out-Null }
        $v = $Snap.Value
        if ($Snap.IsBase64) { $v = [Convert]::FromBase64String($v) }
        elseif ($Snap.Kind -eq 'MultiString') { $v = [string[]]@($v) }
        New-ItemProperty -LiteralPath $Snap.Path -Name $Snap.Name -Value $v -PropertyType $Snap.Kind -Force -ErrorAction Stop | Out-Null
    } elseif (Test-Path -LiteralPath $Snap.Path) {
        Remove-ItemProperty -LiteralPath $Snap.Path -Name $Snap.Name -Force -ErrorAction SilentlyContinue
    }
}

function Save-VdTweakState([string]$TweakName, $Spec) {
    if (-not $Spec) { return }
    if (-not (Test-Path $VdStateRoot)) { New-Item -Path $VdStateRoot -Force | Out-Null }
    # Keep the very first snapshot: re-applying must not overwrite the true original
    if ((Get-Item -Path $VdStateRoot).GetValueNames() -contains $TweakName) { return }
    $items = foreach ($e in $Spec) {
        if ($e.Reg) {
            @{ Type = 'Reg'; Snap = (Get-VdRegSnapshot $e.Reg $e.Name) }
        } elseif ($e.Svc) {
            $svcKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($e.Svc)"
            $svc = Get-Service -Name $e.Svc -ErrorAction SilentlyContinue
            @{ Type = 'Svc'; Name = $e.Svc; WasRunning = [bool]($svc -and $svc.Status -eq 'Running')
               Start = (Get-VdRegSnapshot $svcKey 'Start'); Delayed = (Get-VdRegSnapshot $svcKey 'DelayedAutostart') }
        } elseif ($e.Key) {
            @{ Type = 'Key'; Path = $e.Key; Existed = [bool](Test-Path -LiteralPath $e.Key) }
        } elseif ($e.Hibernate) {
            $h = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name HibernateEnabled -ErrorAction SilentlyContinue).HibernateEnabled
            @{ Type = 'Hibernate'; Enabled = ($h -eq 1) }
        } elseif ($e.PowerPlan) {
            $m = [regex]::Match((powercfg /getactivescheme | Out-String), '[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')
            @{ Type = 'PowerPlan'; ActiveGuid = $m.Value }
        }
    }
    $json = ConvertTo-Json -InputObject @($items) -Depth 6 -Compress
    New-ItemProperty -Path $VdStateRoot -Name $TweakName -Value $json -PropertyType String -Force -ErrorAction Stop | Out-Null
}

function Restore-VdTweakState([string]$TweakName) {
    if (-not (Test-Path $VdStateRoot)) { return $false }
    $json = (Get-Item -Path $VdStateRoot).GetValue($TweakName)
    if (-not $json) { return $false }
    foreach ($it in ($json | ConvertFrom-Json)) {
        switch ($it.Type) {
            'Reg' { Restore-VdRegSnapshot $it.Snap }
            'Svc' {
                Restore-VdRegSnapshot $it.Start
                Restore-VdRegSnapshot $it.Delayed
                if ($it.WasRunning) { Start-Service -Name $it.Name -ErrorAction SilentlyContinue }
            }
            'Key' { if (-not $it.Existed -and (Test-Path -LiteralPath $it.Path)) { Remove-Item -LiteralPath $it.Path -Recurse -Force -ErrorAction Stop } }
            'Hibernate' { if ($it.Enabled) { powercfg /hibernate on | Out-Null } else { powercfg /hibernate off | Out-Null } }
            'PowerPlan' {
                if ($it.ActiveGuid) { powercfg /setactive $it.ActiveGuid | Out-Null }
                if ($it.ActiveGuid -ne $VdUltimatePlanGuid) { powercfg /delete $VdUltimatePlanGuid 2>$null | Out-Null }
            }
        }
    }
    Remove-ItemProperty -Path $VdStateRoot -Name $TweakName -Force -ErrorAction SilentlyContinue
    return $true
}
