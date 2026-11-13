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
        $missing = Get-VdXamlNames | Where-Object { $_ -ne 'bd' } | Where-Object { -not $Window.FindName($_) }
        $missing | Should -BeNullOrEmpty
    }

    It 'has the styles the script looks up at runtime' {
        foreach ($key in 'RoundedBtn', 'SubTabBtn', 'SidebarBtn') { $Window.FindResource($key) | Should -Not -BeNullOrEmpty }
    }
}
