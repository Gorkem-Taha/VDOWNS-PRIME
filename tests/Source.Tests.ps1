BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $text = Get-VdScriptText
}

Describe 'Generated script' {
    It 'is in sync with src/ (run tools/Merge-Source.ps1 after editing src/)' {
        { & (Join-Path $RepoRoot 'tools/Merge-Source.ps1') -Check } | Should -Not -Throw
    }

    It 'is saved as UTF-8 with BOM (Windows PowerShell 5.1)' {
        $b = [System.IO.File]::ReadAllBytes($ScriptPath)
        ($b[0], $b[1], $b[2]) -join ',' | Should -Be '239,187,191'
    }

    It 'parses: <_>' -ForEach @('VDOWNS_PRIME.ps1', 'build.ps1', 'vdowns.ps1', 'tools/Merge-Source.ps1') {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $RepoRoot $_), [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'every src/lib file parses on its own: <_>' -ForEach @(Get-ChildItem (Join-Path (Split-Path $PSScriptRoot -Parent) 'src/lib') -Filter *.ps1 | ForEach-Object Name) {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $SrcRoot "lib/$_"), [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

Describe 'XAML' {
    It 'is well-formed with unique element names' {
        $names = Get-VdXamlNames | Where-Object { $_ -ne 'bd' }
        @($names | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
        $names.Count | Should -BeGreaterThan 80
    }

    It 'has no named element the script never uses' {
        $unused = Get-VdXamlNames | Where-Object { $_ -notin 'bd', 'wingetProgressBar' } |
            Where-Object { ([regex]::Matches($text, "\b$_\b")).Count -le 1 }
        $unused | Should -BeNullOrEmpty
    }

    It 'has no script handler for a button that does not exist' {
        $names = Get-VdXamlNames
        $aliases = 'btnDebloat', 'btnSelectAll', 'btnDeselectAll', 'btnEnableFeatures', 'btnSfc', 'btnDism', 'btnNetReset', 'btnFixWU', 'btnSearchWingetRepo'
        $handled = [regex]::Matches($text, '(?m)^\s*if \(\$(btn\w+)\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        $handled | Where-Object { $_ -notin $names -and $_ -notin $aliases } | Should -BeNullOrEmpty
    }
}

Describe 'Code rules' {
    It 'never uses GetNewClosure (closures lose script functions under -File)' {
        $text | Should -Not -Match 'GetNewClosure'
    }
    It 'runs console tools only through Invoke-VdNative (no window flashes)' {
        $text | Should -Not -Match '& winget|& code|\breg (add|delete)\b'
    }
    It 'never forces a winget reinstall' {
        $text | Should -Not -Match "(?<!un)install --id[^\r\n]*--force"
        $text | Should -Not -Match "(?<!un)'install',[^\r\n]*'--force'"
    }
    It 'tweaks run with ErrorAction Stop' {
        $text | Should -Match "\`$ErrorActionPreference = 'Stop'\r?\n\s+\`$applied = 0"
    }
    It 'has no -SkipPublisherCheck in the app' {
        $text | Should -Not -Match 'SkipPublisherCheck'
    }
    It 'verifies OO ShutUp10 and PSWindowsUpdate signatures' {
        $text | Should -Match 'Get-AuthenticodeSignature -FilePath \$exe'
        $text | Should -Match '\[version\]"2\.2\.1\.5"'
        $text | Should -Match 'SignerCertificate\.Subject -notmatch "Michal Gajda"'
    }
    It 'Disk Cleanup allow-list never includes user or recovery data' {
        $block = [regex]::Match($text, '(?s)\$safeHandlers = @\((.*?)\)').Groups[1].Value
        $block | Should -Not -BeNullOrEmpty
        $block | Should -Not -Match 'DownloadsFolder|Recycle Bin|Previous Installations|Windows ESD|Language Pack'
    }
    It 'restore guards against zip-slip' {
        $text | Should -Not -Match 'Expand-Archive -Path \$srcZip'
        $text | Should -Match 'Unsafe path in archive'
    }
    It 'web links and wizard URLs are http(s) only' {
        ([regex]::Matches($text, [regex]::Escape("'^https?://[^\s""]+$'"))).Count | Should -BeGreaterOrEqual 2
    }
}

Describe 'Version and release plumbing' {
    BeforeAll {
        $version = [regex]::Match($text, '(?m)^\$script:VdownsVersion = "(\d+\.\d+\.\d+)"').Groups[1].Value
    }
    It 'defines the version once' {
        $version | Should -Match '^\d+\.\d+\.\d+$'
        ($text -replace '(?m)^\s*#.*$', '') | Should -Not -Match 'v3\.\d+\.\d+'
    }
    It 'CHANGELOG has an entry for the version' {
        Get-Content (Join-Path $RepoRoot 'CHANGELOG.md') -Raw | Should -Match "\[$([regex]::Escape($version))\]"
    }
    It 'README badge shows the version' {
        Get-Content (Join-Path $RepoRoot 'README.md') -Raw | Should -Match "v$([regex]::Escape($version))"
    }
    It 'pins every GitHub Action to a commit SHA: <_>' -ForEach @(Get-ChildItem (Join-Path (Split-Path $PSScriptRoot -Parent) '.github/workflows') -Filter *.yml | ForEach-Object Name) {
        $wf = Get-Content (Join-Path $RepoRoot ".github/workflows/$_") -Raw
        $uses = [regex]::Matches($wf, '(?m)^\s*(?:-\s*)?uses:\s*(\S+)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch '^\./' }
        $uses | Where-Object { $_ -notmatch '@[0-9a-f]{40}$' } | Should -BeNullOrEmpty
    }
    It 'pins ps2exe' {
        Get-Content (Join-Path $RepoRoot 'build.ps1') -Raw | Should -Match '\$ps2exeVersion = "\d+\.\d+\.\d+"'
    }
    It 'does not commit build outputs or duplicate sources' {
        Test-Path (Join-Path $RepoRoot 'VDOWNS_PRIME.exe') | Should -BeFalse
        Test-Path (Join-Path $RepoRoot 'Source') | Should -BeFalse
    }
}
