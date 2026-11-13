<#
.SYNOPSIS
    Builds VDOWNS_PRIME.ps1 from the files under src/.
.DESCRIPTION
    VDOWNS_PRIME.ps1 stays a single file because ps2exe compiles one script and users run it
    directly. The source of truth lives in src/:

      src/app/NN-*.ps1   fragments of the one script scope, concatenated in file-name order
      src/lib/*.ps1      self-contained helper libraries (loaded into runspaces, unit-tested)
      src/ui/*.xaml      WPF markup
      apps.json          catalog, embedded as the offline fallback

    A line consisting only of  #@include <path>  (path relative to src/, or ../ for the repo
    root) is replaced by that file's content. Includes always sit inside a here-string in the
    fragment, so the included file is pasted verbatim.

    Run without arguments to regenerate VDOWNS_PRIME.ps1 (UTF-8 with BOM, LF line endings).
    -Check fails if the committed VDOWNS_PRIME.ps1 is not what src/ produces (used by CI/build).
#>
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root   = Split-Path $PSScriptRoot -Parent
$srcDir = Join-Path $root 'src'
$target = Join-Path $root 'VDOWNS_PRIME.ps1'
$utf8   = New-Object System.Text.UTF8Encoding($false)

function Read-Normalized([string]$Path) {
    $t = [System.IO.File]::ReadAllText($Path, $utf8)
    if ($t.Length -gt 0 -and $t[0] -eq [char]0xFEFF) { $t = $t.Substring(1) }
    $t = $t -replace "`r`n", "`n"
    if ($t.EndsWith("`n")) { $t = $t.Substring(0, $t.Length - 1) }
    return $t
}

$parts = foreach ($f in Get-ChildItem -Path (Join-Path $srcDir 'app') -Filter '*.ps1' | Sort-Object Name) {
    $lines = (Read-Normalized $f.FullName) -split "`n"
    $out = foreach ($line in $lines) {
        if ($line -match '^#@include (\S+)$') {
            $rel = $Matches[1]
            $inc = Join-Path $srcDir $rel
            if (-not (Test-Path $inc)) { throw "$($f.Name): include not found: $rel" }
            $body = Read-Normalized $inc
            if ($body -match "(?m)^'@") { throw "$rel contains a line starting with '@ and would end the here-string early" }
            $body
        } else { $line }
    }
    $out -join "`n"
}
$merged = ($parts -join "`n") + "`n"

if ($Check) {
    $current = [System.IO.File]::ReadAllText($target, $utf8)
    if ($current.Length -gt 0 -and $current[0] -eq [char]0xFEFF) { $current = $current.Substring(1) }
    if ($current -ne $merged) {
        throw "VDOWNS_PRIME.ps1 is out of date with src/. Run: pwsh ./tools/Merge-Source.ps1"
    }
    Write-Host "VDOWNS_PRIME.ps1 is in sync with src/." -ForegroundColor Green
    return
}

[System.IO.File]::WriteAllText($target, $merged, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Wrote $target" -ForegroundColor Green
