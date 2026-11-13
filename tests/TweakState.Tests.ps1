# Apply -> re-apply -> revert round trip of the real tweak definitions against an in-memory
# registry. Runs everywhere and never touches the real system.

BeforeDiscovery {
    # -ForEach data is read during discovery, before any BeforeAll runs
    $RoundTrip = 'Show File Extensions', 'Show Hidden Files', "Launch to 'This PC'", 'Disable Sticky Keys',
                 'Disable Telemetry', 'Enable Hibernate', 'Ultimate Performance', 'Classic Context Menu'
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    foreach ($v in 'essentialTweaks', 'uiTweaks', 'perfTweaks') { . ([scriptblock]::Create((Get-VdAssignmentText $v))) }
    $script:AllTweaks = $essentialTweaks + $uiTweaks + $perfTweaks
    . (Join-Path $SrcRoot 'lib/TweakState.ps1')
    . (Join-Path $PSScriptRoot 'RegistryFake.ps1')   # shadows Test-Path, Get-Item, powercfg, ...

    function Initialize-FakeMachine {
        Reset-VdFakeSystem
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        New-Item $adv
        New-ItemProperty -Path $adv -Name HideFileExt -Value 1 -PropertyType DWord
        New-ItemProperty -Path $adv -Name Hidden -Value 2 -PropertyType DWord
        # LaunchTo intentionally absent: revert must remove it again
        New-Item 'HKCU:\Control Panel\Accessibility\StickyKeys'
        New-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name Flags -Value '58' -PropertyType String
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack'
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack' -Name Start -Value 2 -PropertyType DWord
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack' -Name DelayedAutostart -Value 1 -PropertyType DWord
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name HibernateEnabled -Value 1 -PropertyType DWord
    }
}

Describe 'Tweak definitions' {
    It 'has 19 tweaks with unique names' {
        $AllTweaks.Count | Should -Be 19
        @($AllTweaks.Name | Sort-Object -Unique).Count | Should -Be 19
    }
    It 'every reversible tweak declares the state it touches' {
        $AllTweaks | Where-Object { $_.Name -notin 'Create Restore Point', 'Run OO ShutUp10' -and -not $_.State } | Should -BeNullOrEmpty
    }
}

Describe 'Snapshot and exact revert' {
    BeforeAll {
        Initialize-FakeMachine
        $script:Before = Get-VdFakeDump
        $names = 'Show File Extensions', 'Show Hidden Files', "Launch to 'This PC'", 'Disable Sticky Keys',
                 'Disable Telemetry', 'Enable Hibernate', 'Ultimate Performance', 'Classic Context Menu'
        $targets = $AllTweaks | Where-Object { $_.Name -in $names }
        $targets.Count | Should -Be 8
        foreach ($round in 1, 2) {
            foreach ($t in $targets) { Save-VdTweakState $t.Name $t.State; $null = & ([scriptblock]::Create($t.Do.ToString())) }
        }
    }

    It 'applied the tweaks' {
        $Reg[(Norm 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced')]['LaunchTo'].Value | Should -Be 1
        $Svc.DiagTrack | Should -Be 'Stopped'
        $Active | Should -Be $VdUltimatePlanGuid
    }

    It 'did not duplicate the Ultimate Performance plan on re-apply' {
        @($Plans | Where-Object { $_ -eq $VdUltimatePlanGuid }).Count | Should -Be 1
    }

    It 'restores <_> from its snapshot' -ForEach $RoundTrip {
        Restore-VdTweakState $_ | Should -BeTrue
    }

    It 'leaves the machine exactly as before' {
        $Reg[(Norm $VdStateRoot)].Count | Should -Be 0
        $Reg.Remove((Norm $VdStateRoot)); $Reg.Remove((Norm 'HKCU:\Software\VDOWNS'))
        Get-VdFakeDump | Should -Be $Before
        $Svc.DiagTrack | Should -Be 'Running'
        $Active | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
        $Plans | Should -Not -Contain $VdUltimatePlanGuid
    }

    It 'reports "no snapshot" so the caller can fall back to the generic undo' {
        Restore-VdTweakState 'Show File Extensions' | Should -BeFalse
    }
}
