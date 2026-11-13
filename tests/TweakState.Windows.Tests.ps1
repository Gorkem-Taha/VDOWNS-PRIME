# Real-system round trip: applies the actual tweaks to THIS machine's registry/services and
# reverts them. It only runs when VDOWNS_ALLOW_SYSTEM_TESTS=1 (set by CI on a throwaway
# GitHub runner) and as Administrator on Windows. Never set that variable on your own PC.

BeforeDiscovery {
    $script:Allowed = ($env:OS -eq 'Windows_NT') -and ($env:VDOWNS_ALLOW_SYSTEM_TESTS -eq '1') -and
        ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Describe 'Real Windows tweak round trip' -Tag 'Windows', 'System' -Skip:(-not $Allowed) {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        foreach ($v in 'essentialTweaks', 'uiTweaks', 'perfTweaks') { . ([scriptblock]::Create((Get-VdAssignmentText $v))) }
        . (Join-Path $SrcRoot 'lib/VdNative.ps1')
        . (Join-Path $SrcRoot 'lib/TweakState.ps1')
        $VdStateRoot = 'HKCU:\Software\VDOWNS-CI\TweakState'   # keep CI snapshots apart
        if (Test-Path 'HKCU:\Software\VDOWNS-CI') { Remove-Item 'HKCU:\Software\VDOWNS-CI' -Recurse -Force }

        function Get-RealState($Spec) {
            foreach ($e in @($Spec)) {
                if ($e.Reg) {
                    $k = Get-Item -LiteralPath $e.Reg -ErrorAction SilentlyContinue
                    if ($k -and ($k.GetValueNames() -contains $e.Name)) { "$($e.Reg)|$($e.Name)=$($k.GetValueKind($e.Name)):$($k.GetValue($e.Name, $null, 'DoNotExpandEnvironmentNames'))" }
                    else { "$($e.Reg)|$($e.Name)=<absent>" }
                } elseif ($e.Svc) {
                    $sk = Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\$($e.Svc)" -ErrorAction SilentlyContinue
                    "svc:$($e.Svc) start=$(if ($sk) { $sk.GetValue('Start') }) delayed=$(if ($sk) { $sk.GetValue('DelayedAutostart') }) status=$((Get-Service $e.Svc -ErrorAction SilentlyContinue).Status)"
                } elseif ($e.Key) {
                    "key:$($e.Key)=$(Test-Path -LiteralPath $e.Key)"
                } elseif ($e.PowerPlan) {
                    "plan:" + [regex]::Match((powercfg /getactivescheme | Out-String), '[0-9a-fA-F-]{36}').Value
                }
            }
        }
    }

    # Registry/service/plan tweaks a hosted runner supports (hibernate is unavailable on runner VMs)
    It 'applies and exactly reverts: <_>' -ForEach @(
        'Disable Ad ID', 'Dark Mode (System)', 'Dark Mode (Apps)', 'Show Hidden Files', 'Show File Extensions',
        "Launch to 'This PC'", 'Classic Context Menu', 'Align Taskbar Left', 'Hide Search Icon', 'Clipboard History',
        'Disable Sticky Keys', 'Storage Sense', 'Disable SysMain', 'Disable Telemetry', 'Disable Game DVR', 'Ultimate Performance'
    ) {
        $t = ($essentialTweaks + $uiTweaks + $perfTweaks) | Where-Object Name -eq $_
        $before = (Get-RealState $t.State) -join "`n"

        $ErrorActionPreference = 'Stop'
        Save-VdTweakState $t.Name $t.State
        foreach ($e in @($t.State)) { if ($e.Reg -and -not (Test-Path -LiteralPath $e.Reg)) { New-Item -Path $e.Reg -Force | Out-Null } }
        $global:LASTEXITCODE = 0
        $null = & ([scriptblock]::Create($t.Do.ToString()))
        $LASTEXITCODE | Should -Be 0

        Restore-VdTweakState $t.Name | Should -BeTrue
        (Get-RealState $t.State) -join "`n" | Should -Be $before
    }

    AfterAll {
        if (Test-Path 'HKCU:\Software\VDOWNS-CI') { Remove-Item 'HKCU:\Software\VDOWNS-CI' -Recurse -Force }
    }
}
