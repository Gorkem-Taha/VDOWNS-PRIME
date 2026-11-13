# Background task library (src/lib/Tasks.ps1) with a fake window/log and a fake winget.
# The fake Dispatcher runs the action inline, so the same code paths as in the app execute.

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    . (Join-Path $SrcRoot 'lib/VdNative.ps1')
    . (Join-Path $SrcRoot 'lib/TweakState.ps1')
    . (Join-Path $SrcRoot 'lib/Tasks.ps1')

    function New-FakeContext {
        $log = New-Object System.Text.StringBuilder
        $box = [pscustomobject]@{ Sb = $log }
        $box | Add-Member ScriptMethod AppendText { param($t) [void]$this.Sb.Append($t) }
        $box | Add-Member ScriptMethod ScrollToEnd { }
        $disp = [pscustomobject]@{}
        $disp | Add-Member ScriptMethod Invoke { param($a) $a.Invoke() }
        @{
            Window = [pscustomobject]@{ Dispatcher = $disp }
            LogBox = $box
            ProgressBar = [pscustomobject]@{ Value = 0 }
            ProgressText = [pscustomobject]@{ Text = '' }
        }
    }
    function Get-FakeLog($SH) { $SH.LogBox.Sb.ToString() }
}

Describe 'UI helpers' {
    It 'Write-VdTaskLog formats and marshals a log line' {
        $SH = New-FakeContext
        Write-VdTaskLog $SH 'hello' 'WARN'
        Get-FakeLog $SH | Should -Match '^\[\d\d:\d\d:\d\d\] \[WARN\] hello\r\n$'
    }
    It 'is a no-op without a window (tests, unattended use)' {
        { Write-VdTaskLog $null 'x'; Set-VdTaskProgress @{} 'x' 5; Show-VdTaskMessage $null 'x' 'y' } | Should -Not -Throw
    }
    It 'Set-VdTaskProgress updates text and value' {
        $SH = New-FakeContext
        Set-VdTaskProgress $SH 'Installing' 40
        $SH.ProgressText.Text | Should -Be 'Installing'
        $SH.ProgressBar.Value | Should -Be 40
    }
}

Describe 'Invoke-VdWingetBatch' {
    BeforeAll {
        # Fake winget: exit code chosen per package id
        function Invoke-VdNative { param($File, $ArgList, $Encoding)
            $script:Calls += , @($ArgList)
            $code = switch ($ArgList[2]) { 'Ok.App' { 0 } 'Already.App' { -1978335189 } default { 1 } }
            [pscustomobject]@{ ExitCode = $code; Output = ''; Error = '' }
        }
    }
    BeforeEach { $script:Calls = @() }

    It 'reports success, already-installed and failure separately' {
        $SH = New-FakeContext
        $apps = @(@{ Id = 'Ok.App'; Name = 'Ok' }, @{ Id = 'Already.App'; Name = 'Already' }, @{ Id = 'Bad.App'; Name = 'Bad' })
        Invoke-VdWingetBatch -Apps $apps -Action install -SH $SH
        $log = Get-FakeLog $SH
        $log | Should -Match '\[SUCCESS\] Installed: Ok'
        $log | Should -Match '\[INFO\] Already installed: Already'
        $log | Should -Match '\[ERROR\] Failed to install Bad \(winget exit code 1\)'
        $log | Should -Match '1 succeeded, 1 failed, 1 skipped'
        $SH.ProgressBar.Value | Should -Be 100
    }
    It 'installs with exact ids and never --force' {
        Invoke-VdWingetBatch -Apps @(@{ Id = 'Ok.App'; Name = 'Ok' }) -Action install -SH $null
        $Calls[0] | Should -Contain '-e'
        $Calls[0] | Should -Not -Contain '--force'
    }
    It 'uninstall treats "already installed" as a failure code' {
        $SH = New-FakeContext
        Invoke-VdWingetBatch -Apps @(@{ Id = 'Already.App'; Name = 'Already' }) -Action uninstall -SH $SH
        Get-FakeLog $SH | Should -Match '\[ERROR\] Failed to uninstall Already'
    }
}

Describe 'Invoke-VdTweakBatch' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'RegistryFake.ps1')
        function Stop-Process { }   # no Explorer restart in tests
        Reset-VdFakeSystem
        New-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 1 -PropertyType DWord
        foreach ($v in 'essentialTweaks', 'uiTweaks', 'perfTweaks') { . ([scriptblock]::Create((Get-VdAssignmentText $v))) }
        $t = ($uiTweaks | Where-Object Name -eq 'Show File Extensions')
        $script:ApplyItem = @{ Name = $t.Name; ScriptStr = $t.Do.ToString(); State = $t.State }
        $script:RevertItem = @{ Name = $t.Name; ScriptStr = $t.Undo.ToString(); State = $t.State }
    }

    It 'applies with a snapshot, then reverts to the exact original' {
        $SH = New-FakeContext
        Invoke-VdTweakBatch -Tweaks @($ApplyItem) -Mode Apply -SH $SH | Should -Be 1
        $Reg[(Norm 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced')]['HideFileExt'].Value | Should -Be 0
        Invoke-VdTweakBatch -Tweaks @($RevertItem) -Mode Revert -SH $SH | Should -Be 1
        $Reg[(Norm 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced')]['HideFileExt'].Value | Should -Be 1
        Get-FakeLog $SH | Should -Match 'Reverted: Show File Extensions - original state restored'
    }
    It 'reports a failing tweak as an error, not as success' {
        $SH = New-FakeContext
        $bad = @{ Name = 'Broken'; ScriptStr = 'throw "boom"'; State = $null }
        Invoke-VdTweakBatch -Tweaks @($bad) -Mode Apply -SH $SH | Should -Be 0
        $log = Get-FakeLog $SH
        $log | Should -Match '\[ERROR\] Failed to apply: Broken - boom'
        $log | Should -Not -Match 'SUCCESS'
    }
    It 'treats a non-zero native exit code as failure' {
        $SH = New-FakeContext
        $bad = @{ Name = 'NativeFail'; ScriptStr = '$global:LASTEXITCODE = 5'; State = $null }
        Invoke-VdTweakBatch -Tweaks @($bad) -Mode Apply -SH $SH | Should -Be 0
        Get-FakeLog $SH | Should -Match 'exited with code 5'
    }
}

Describe 'Invoke-VdStream' -Skip:($env:OS -eq 'Windows_NT') {
    It 'streams stdout, drops progress spinners and reports the exit code' {
        $SH = New-FakeContext
        Invoke-VdStream -FileName '/bin/sh' -Arguments "-c `"echo line1; echo '-'; echo line2; exit 4`"" -SH $SH | Should -Be 4
        $log = Get-FakeLog $SH
        $log | Should -Match 'line1\r\nline2\r\n'
        $log | Should -Match 'FINISHED WITH ERRORS \(exit code 4\)'
    }
}
