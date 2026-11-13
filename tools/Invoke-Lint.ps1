<#
.SYNOPSIS
    Runs PSScriptAnalyzer (settings: PSScriptAnalyzerSettings.psd1) over the app, the src/lib
    libraries (their code sits inside here-strings in the generated script, where the analyzer
    cannot see it), the tools and build.ps1. Exits 1 on any finding.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module PSScriptAnalyzer -RequiredVersion 1.25.0
$files = @('VDOWNS_PRIME.ps1', 'build.ps1', 'vdowns.ps1', 'tools/Merge-Source.ps1', 'tools/Invoke-Lint.ps1') | ForEach-Object { Join-Path $root $_ }
$files += (Get-ChildItem (Join-Path $root 'src/lib') -Filter *.ps1).FullName
$findings = foreach ($f in $files) { Invoke-ScriptAnalyzer -Path $f -Settings (Join-Path $root 'PSScriptAnalyzerSettings.psd1') }
foreach ($x in $findings) { Write-Output ('{0}:{1} [{2}] {3}' -f (Split-Path $x.ScriptPath -Leaf), $x.Line, $x.RuleName, $x.Message) }
if (@($findings).Count) { Write-Output "$(@($findings).Count) finding(s)."; exit 1 }
Write-Output "PSScriptAnalyzer: no findings in $($files.Count) files."
