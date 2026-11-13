<#
.SYNOPSIS
    VDOWNS PRIME build script.
.DESCRIPTION
    Verifies the catalog and the script, then compiles VDOWNS_PRIME.ps1 into VDOWNS_PRIME.exe
    with a pinned ps2exe version and writes SHA256SUMS for the release assets.
    The version is read from $script:VdownsVersion in VDOWNS_PRIME.ps1 (single source of truth).
.PARAMETER SkipCompile
    Run the checks only.
#>
[CmdletBinding()]
param(
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"
$rootDir      = $PSScriptRoot
$sourceScript = Join-Path $rootDir "VDOWNS_PRIME.ps1"
$outputExe    = Join-Path $rootDir "VDOWNS_PRIME.exe"
$appsJson     = Join-Path $rootDir "apps.json"
$sumsFile     = Join-Path $rootDir "SHA256SUMS"
$ps2exeVersion = "1.0.18"

# 0. Version
$versionMatch = Select-String -Path $sourceScript -Pattern '^\$script:VdownsVersion = "(\d+\.\d+\.\d+)"' | Select-Object -First 1
if (-not $versionMatch) { throw "Could not find `$script:VdownsVersion in $sourceScript" }
$version = $versionMatch.Matches[0].Groups[1].Value

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VDOWNS PRIME - Build v$version" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Encoding: Windows PowerShell 5.1 needs the BOM to read the non-ASCII UI text correctly
Write-Host "`n[1/5] Checking file encoding..." -ForegroundColor Yellow
$head = [System.IO.File]::ReadAllBytes($sourceScript)[0..2]
if (-not ($head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF)) {
    throw "VDOWNS_PRIME.ps1 must be saved as UTF-8 with BOM."
}
Write-Host "  -> UTF-8 BOM present." -ForegroundColor Green

# 2. Catalog integrity
Write-Host "`n[2/5] Verifying apps.json..." -ForegroundColor Yellow
$catalog = Get-Content $appsJson -Raw -Encoding UTF8 | ConvertFrom-Json
$ids = @(foreach ($cat in $catalog.PSObject.Properties) { foreach ($app in @($cat.Value)) { $app.Id } })
$dupes = @($ids | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
if ($dupes.Count) { throw "Duplicate package ids in apps.json: $($dupes -join ', ')" }
$badIds = @($ids | Where-Object { $_ -notmatch '^[a-zA-Z0-9_\-\.\+]+$' })
if ($badIds.Count) { throw "Invalid package ids in apps.json: $($badIds -join ', ')" }
$embedded = [regex]::Match((Get-Content $sourceScript -Raw -Encoding UTF8), "(?s)\`$script:DefaultAppsJson = @'\r?\n(.*?)\r?\n'@").Groups[1].Value | ConvertFrom-Json
$embeddedIds = @(foreach ($cat in $embedded.PSObject.Properties) { foreach ($app in @($cat.Value)) { $app.Id } })
if (($ids -join ',') -ne ($embeddedIds -join ',')) { throw "apps.json and the embedded fallback catalog in VDOWNS_PRIME.ps1 differ." }
Write-Host "  -> $($ids.Count) packages, no duplicates, embedded copy in sync." -ForegroundColor Green

# 3. Syntax
Write-Host "`n[3/5] Parsing PowerShell scripts..." -ForegroundColor Yellow
foreach ($f in @($sourceScript, (Join-Path $rootDir "vdowns.ps1"), $PSCommandPath)) {
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$parseErrors)
    if ($parseErrors) {
        $parseErrors | ForEach-Object { Write-Host "  $(Split-Path $f -Leaf):$($_.Extent.StartLineNumber) $($_.Message)" -ForegroundColor Red }
        throw "Syntax check failed for $f"
    }
}
Write-Host "  -> All scripts parse cleanly." -ForegroundColor Green

if ($SkipCompile) {
    Write-Host "`nCompilation skipped (-SkipCompile). Checks passed." -ForegroundColor Cyan
    return
}

# 4. Compile with a pinned ps2exe
Write-Host "`n[4/5] Compiling VDOWNS_PRIME.exe with ps2exe $ps2exeVersion..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name ps2exe | Where-Object { $_.Version -eq [version]$ps2exeVersion })) {
    Install-Module -Name ps2exe -RequiredVersion $ps2exeVersion -Scope CurrentUser -Force
}
Import-Module ps2exe -RequiredVersion $ps2exeVersion -Force

$ps2exeParams = @{
    inputFile    = $sourceScript
    outputFile   = $outputExe
    STA          = $true
    noConsole    = $true
    x64          = $true
    requireAdmin = $true
    title        = "VDOWNS PRIME"
    description  = "Windows 10/11 optimization, debloat and winget deployment suite"
    company      = "VDOWNS PRIME"
    product      = "VDOWNS PRIME"
    copyright    = "Copyright (c) 2025-2026 Gorkem Taha Canakci (MIT License)"
    version      = "$version.0"
    DPIAware     = $true
    supportOS    = $true
}
Invoke-ps2exe @ps2exeParams
if (-not (Test-Path $outputExe)) { throw "Build failed: $outputExe was not created." }

# 5. Checksums for every release asset
Write-Host "`n[5/5] Writing SHA256SUMS..." -ForegroundColor Yellow
$lines = foreach ($asset in @($outputExe, $appsJson)) {
    "{0}  {1}" -f (Get-FileHash -Path $asset -Algorithm SHA256).Hash.ToLower(), (Split-Path $asset -Leaf)
}
[System.IO.File]::WriteAllText($sumsFile, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
Get-Content $sumsFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

Write-Host "`nBUILD SUCCESSFUL: VDOWNS PRIME v$version" -ForegroundColor Green
