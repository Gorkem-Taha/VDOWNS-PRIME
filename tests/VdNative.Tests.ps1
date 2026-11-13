BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    . (Join-Path $SrcRoot 'lib/VdNative.ps1')
}

Describe 'ConvertFrom-VdWingetTable' {
    It 'parses winget list by column offsets, ignoring progress noise and the summary' {
        $list = "   - `r   \ `r" + @'
Name                                   Id                                Version        Available     Source
-----------------------------------------------------------------------------------------------------------
7-Zip 24.08 (x64)                      7zip.7zip                         24.08          24.09         winget
Microsoft Visual Studio Code (User)    Microsoft.VisualStudioCode        1.95.3                       winget
Some Very Long Application Name That…  Vendor.LongApp                    1.0.0.12345                  winget
Old Tool                               ARP\Machine\X64\{AB12-CD34}       1.2
Notepad++ (64-bit x64)                 Notepad++.Notepad++               8.7.1          8.7.4         winget

2 upgrades available.
'@
        $r = @(ConvertFrom-VdWingetTable $list)
        $r.Count | Should -Be 5
        $r[0].Id | Should -Be '7zip.7zip'
        $r[0].Version | Should -Be '24.08'
        $r[0].Source | Should -Be 'winget'
        $r[2].Name | Should -Be 'Some Very Long Application Name That…'
        $r[2].Id | Should -Be 'Vendor.LongApp'
        $r[3].Id | Should -Be 'ARP\Machine\X64\{AB12-CD34}'
        $r[3].Source | Should -Be ''
        $r[4].Id | Should -Be 'Notepad++.Notepad++'
    }

    It 'parses winget search with a Match column (Source is the last column)' {
        $search = @'
Name                      Id                          Version  Match             Source
-----------------------------------------------------------------------------------------
Visual Studio Code        Microsoft.VisualStudioCode  1.95.3   Moniker: vscode   winget
VSCodium                  VSCodium.VSCodium           1.95.3.2 Tag: vscode       winget
'@
        $r = @(ConvertFrom-VdWingetTable $search)
        $r.Count | Should -Be 2
        $r[0].Id | Should -Be 'Microsoft.VisualStudioCode'
        $r[1].Version | Should -Be '1.95.3.2'
        $r[1].Source | Should -Be 'winget'
    }

    It 'handles localized headers' {
        $tr = @'
Ad                Kimlik             Sürüm    Kaynak
-----------------------------------------------------
Mozilla Firefox   Mozilla.Firefox    133.0    winget
'@
        @(ConvertFrom-VdWingetTable $tr)[0].Id | Should -Be 'Mozilla.Firefox'
    }

    It 'returns nothing when there is no table' {
        @(ConvertFrom-VdWingetTable 'No installed package found matching input criteria.').Count | Should -Be 0
    }
}

Describe 'Invoke-VdNative' {
    BeforeAll {
        if ($OnWindows) {
            $shell = 'cmd.exe'
            $mk = { param($cmd) @('/d', '/c', $cmd) }
        } else {
            $shell = '/bin/sh'
            $mk = { param($cmd) @('-c', $cmd) }
        }
    }

    It 'returns exit code, stdout and stderr' {
        $cmd = if ($OnWindows) { 'echo out& echo err 1>&2& exit /b 3' } else { 'echo out; echo err 1>&2; exit 3' }
        $r = Invoke-VdNative $shell (& $mk $cmd) 'UTF8'
        $r.ExitCode | Should -Be 3
        $r.Output.Trim() | Should -Be 'out'
        $r.Error.Trim() | Should -Be 'err'
    }

    It 'does not deadlock when a tool floods stderr' {
        $cmd = if ($OnWindows) {
            'powershell -NoProfile -Command "[Console]::Error.Write((''e'' * 262144)); ''done''"'
        } else { 'head -c 262144 /dev/zero | tr "\0" e 1>&2; echo done' }
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-VdNative $shell (& $mk $cmd) 'UTF8'
        $r.Output.Trim() | Should -Be 'done'
        $r.Error.Length | Should -BeGreaterOrEqual 262144
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 60
    }

    It 'quotes arguments with spaces, quotes and empty strings' -Skip:$OnWindows {
        $r = Invoke-VdNative '/usr/bin/printf' @('%s|', 'a b', 'say "hi"', '') 'UTF8'
        $r.Output | Should -Be 'a b|say "hi"||'
    }
}
