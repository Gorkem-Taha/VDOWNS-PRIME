# Code the app generates at runtime (unattended setup script, feature script, DNS benchmark)
# and pure UI logic (category filter), exercised with the real source and fake UI objects.

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $text = Get-VdScriptText
    foreach ($v in 'essentialTweaks', 'uiTweaks', 'perfTweaks', 'bloatItems') { . ([scriptblock]::Create((Get-VdAssignmentText $v))) }
    function New-Check($v) { [pscustomobject]@{ IsChecked = $v } }
}

Describe 'Unattended setup script generator' {
    BeforeAll {
        $script:TweakList = foreach ($t in $essentialTweaks + $uiTweaks + $perfTweaks) { @{ Check = (New-Check $true); Do = $t.Do; Name = $t.Name } }
        $script:DebloatList = foreach ($k in $bloatItems.Keys) { @{ Check = (New-Check $true); Pat = $bloatItems[$k][0]; Name = $k } }
        $script:InstallList = @(
            @{ Check = (New-Check $true); Id = 'Notepad++.Notepad++' },
            @{ Check = (New-Check $true); Id = "O'Brien.Test" },
            @{ Check = (New-Check $false); Id = 'Not.Selected' }
        )
        $script:VdownsVersion = '0.0.0-test'
        $m = [regex]::Match($text, '(?s)(\$selectedApps = @\(\$script:InstallList.*?)\r?\n\s*Set-Content -Path \$sfd\.FileName -Value \$scriptContent')
        $m.Success | Should -BeTrue
        . ([scriptblock]::Create($m.Groups[1].Value))
        $script:Generated = $scriptContent
    }

    It 'produces a script that parses' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseInput($Generated, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
    It 'emits every selected tweak in its own try block' {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Generated, [ref]$null, [ref]$null)
        @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TryStatementAst] }, $true)).Count | Should -BeGreaterOrEqual 19
    }
    It 'embeds the tweak code literally (no expansion at generation time)' {
        $Generated | Should -Match ([regex]::Escape('Join-Path $env:TEMP'))
        $Generated | Should -Match ([regex]::Escape('Start-Process -FilePath $exe'))
    }
    It 'uses real AppX patterns, not display labels' {
        $Generated | Should -Match "'\*BingNews\*'"
        $Generated | Should -Not -Match 'News, Weather & Money'
    }
    It 'exports only selected apps, safely quoted' {
        $Generated | Should -Match "'O''Brien\.Test'"
        $Generated | Should -Not -Match 'Not\.Selected'
        $Generated | Should -Match 'v0\.0\.0-test'
    }
}

Describe 'Windows features script' {
    It 'enables WSL 2 with Virtual Machine Platform and parses' {
        $script:FeatureList = @(
            @{ Check = (New-Check $true); WinName = 'Microsoft-Windows-Subsystem-Linux,VirtualMachinePlatform' },
            @{ Check = (New-Check $true); WinName = 'NetFx3' },
            @{ Check = (New-Check $false); WinName = 'Microsoft-Hyper-V-All' }
        )
        $fm = [regex]::Match($text, '(?s)(\$names = @\(\$script:FeatureList.*?\n"@)')
        . ([scriptblock]::Create(($fm.Groups[1].Value -replace '(?m)^\s*if \(\$names\.Count -eq 0\).*$', '')))
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseInput($featureScript, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
        $featureScript | Should -Match "@\('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform', 'NetFx3'\)"
    }
}

Describe 'DNS benchmark script' {
    It 'is a standalone script that parses' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $SrcRoot 'lib/DnsBenchmark.ps1'), [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

Describe 'App Center filter (category chips + search)' {
    BeforeAll {
        . ([scriptblock]::Create((Get-VdFunctionText 'Update-AppFilter')))
        function New-Vis { [pscustomobject]@{ Visibility = 'Visible' } }
        $script:searchBox = [pscustomobject]@{ Text = '' }
        $script:InstallList = @(
            @{ Name = 'Firefox'; Id = 'Mozilla.Firefox'; Category = 'Internet & Comms'; Card = (New-Vis) },
            @{ Name = 'Brave'; Id = 'Brave.Brave'; Category = 'Internet & Comms'; Card = (New-Vis) },
            @{ Name = 'VS Code'; Id = 'Microsoft.VisualStudioCode'; Category = 'Development'; Card = (New-Vis) },
            @{ Name = 'Steam'; Id = 'Valve.Steam'; Category = 'Multimedia & Gaming'; Card = (New-Vis) }
        )
        $script:CategorySections = [ordered]@{}
        foreach ($c in 'Internet & Comms', 'Development', 'Multimedia & Gaming') { $script:CategorySections[$c] = @{ Header = (New-Vis); Panel = (New-Vis) } }
        function Get-Visible { (@($script:InstallList | Where-Object { $_.Card.Visibility -eq 'Visible' } | ForEach-Object { $_.Name })) -join ',' }
    }

    It 'shows only the chosen category and hides other headers' {
        $script:ActiveCategory = 'Development'; $searchBox.Text = ''; Update-AppFilter
        Get-Visible | Should -Be 'VS Code'
        $CategorySections['Internet & Comms'].Header.Visibility | Should -Be 'Collapsed'
    }
    It 'search also matches package ids and hides empty sections' {
        $script:ActiveCategory = 'All'; $searchBox.Text = 'mozilla'; Update-AppFilter
        Get-Visible | Should -Be 'Firefox'
        $CategorySections['Development'].Panel.Visibility | Should -Be 'Collapsed'
    }
    It 'combines category and search' {
        $script:ActiveCategory = 'Development'; $searchBox.Text = 'steam'; Update-AppFilter
        Get-Visible | Should -Be ''
    }
    It 'All + empty search shows everything' {
        $script:ActiveCategory = 'All'; $searchBox.Text = ''; Update-AppFilter
        Get-Visible | Should -Be 'Firefox,Brave,VS Code,Steam'
    }
}
