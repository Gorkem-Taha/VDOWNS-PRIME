# Loads the real XAML with WPF and resolves every named element. Read-only; needs Windows and
# an STA thread (Windows PowerShell 5.1 is STA by default; pwsh 7 needs -STA).

BeforeDiscovery {
    $script:CanRun = ($env:OS -eq 'Windows_NT') -and ([System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA')
}

Describe 'WPF window' -Tag 'Windows' -Skip:(-not $CanRun) {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
        $xaml = Get-VdXaml
        $script:Window = [System.Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
    }

    It 'loads into a WPF Window' {
        $Window | Should -BeOfType [System.Windows.Window]
    }

    It 'resolves every named element' {
        $names = Get-VdXamlNames -ExcludeTemplates
        $names.Count | Should -BeGreaterThan 80
        $missing = $names | Where-Object { -not $Window.FindName($_) }
        $missing | Should -BeNullOrEmpty
    }

    It 'has the styles the script looks up at runtime' {
        foreach ($key in 'RoundedBtn', 'SubTabBtn', 'SidebarBtn') { $Window.FindResource($key) | Should -Not -BeNullOrEmpty }
    }
}

# The whole app logs from background runspaces through Window.Dispatcher. This exercises that
# exact path on a real WPF window: a task runspace writes to a TextBox while the UI thread pumps.
Describe 'Background task -> UI thread logging' -Tag 'Windows' -Skip:(-not $CanRun) {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
        $script:Box = New-Object System.Windows.Controls.TextBox
        $script:Win = New-Object System.Windows.Window
        $Win.Content = $Box
        $lib = (@('lib/VdNative.ps1', 'lib/TweakState.ps1', 'lib/Tasks.ps1') | ForEach-Object { Get-Content (Join-Path $SrcRoot $_) -Raw }) -join "`n"
        $bar = New-Object System.Windows.Controls.ProgressBar
        $label = New-Object System.Windows.Controls.TextBlock
        $SH = [hashtable]::Synchronized(@{ Window = $Win; LogBox = $Box; ProgressBar = $bar; ProgressText = $label })
        $rs = [runspacefactory]::CreateRunspace(); $rs.Open()
        $ps = [powershell]::Create(); $ps.Runspace = $rs
        [void]$ps.AddScript($lib)
        [void]$ps.AddStatement().AddScript({ param($SH) Write-VdTaskLog $SH 'from runspace' 'SUCCESS'; Set-VdTaskProgress $SH 'half' 50; 'done' }).AddArgument($SH)
        $h = $ps.BeginInvoke()
        $sw = [Diagnostics.Stopwatch]::StartNew()
        while (-not $h.IsCompleted -and $sw.Elapsed.TotalSeconds -lt 20) {
            # pump the UI thread so the runspace's Dispatcher.Invoke calls can run
            $Win.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
            Start-Sleep -Milliseconds 20
        }
        $script:Completed = $h.IsCompleted
        $script:Output = if ($Completed) { $ps.EndInvoke($h) }
        $script:Errors = @($ps.Streams.Error | ForEach-Object { $_.ToString() })
        $script:Bar = $bar; $script:Label = $label
        $ps.Dispose(); $rs.Close()
    }
    It 'completes without deadlocking the UI thread' { $Completed | Should -BeTrue }
    It 'raises no errors in the task' { $Errors | Should -BeNullOrEmpty }
    It 'appends the log line on the UI thread' { $Box.Text | Should -Match '\[SUCCESS\] from runspace' }
    It 'updates progress controls' { $Bar.Value | Should -Be 50; $Label.Text | Should -Be 'half' }
}
