BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $catalog = Get-Content (Join-Path $RepoRoot 'apps.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $ids = Get-VdCatalogIds $catalog
    $wizardRegex = [regex]::Match((Get-VdScriptText), "\`$idVal -notmatch '([^']+)'").Groups[1].Value
}

Describe 'apps.json catalog' {
    It 'has 7 categories and 96 apps' {
        @($catalog.PSObject.Properties).Count | Should -Be 7
        $ids.Count | Should -Be 96
    }
    It 'has no duplicate ids' {
        @($ids | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
    }
    It 'every id passes the Add App wizard validation' {
        $wizardRegex | Should -Not -BeNullOrEmpty
        $ids | Where-Object { $_ -notmatch $wizardRegex } | Should -BeNullOrEmpty
    }
    It 'every entry has Name, Id, Desc and an http(s) Url' {
        foreach ($p in $catalog.PSObject.Properties) {
            foreach ($app in @($p.Value)) {
                $app.Name | Should -Not -BeNullOrEmpty
                $app.Desc | Should -Not -BeNullOrEmpty
                $app.Url  | Should -Match '^https?://'
            }
        }
    }
    It 'is embedded in the script as the offline fallback' {
        $embText = [regex]::Match((Get-VdScriptText), "(?s)\`$script:DefaultAppsJson = @'\r?\n(.*?)\r?\n'@").Groups[1].Value
        Get-VdCatalogIds ($embText | ConvertFrom-Json) | Should -Be $ids
    }
    It 'does not contain ids that were found invalid in winget (2026-11 review)' {
        $known = 'Signal.Signal', 'AnyDeskSoftwareGmbH.AnyDesk', 'Krita.Krita', 'ScottBrosius.Ditto', 'ImageGlass.ImageGlass',
                 'Python.Python.3', 'WhatsApp.WhatsApp', 'GamerSoftware.WallpaperEngine', 'mifi.LosslessCut', 'Razer.Synapse',
                 'Ryanoasis.NerdFonts.Meslo', 'RevoUninstaller.RevoUninstallerFree', 'Marticliment.UniGetUI'
        $ids | Where-Object { $_ -in $known } | Should -BeNullOrEmpty
    }
}
