<#
.SYNOPSIS
    VDOWNS PRIME Build & Compiler Script (v3.2.0)
.DESCRIPTION
    Validates syntax, verifies integrity, and compiles VDOWNS_PRIME.ps1 into a standalone executable.
#>
[CmdletBinding()]
param(
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"
$rootDir = $PSScriptRoot
$sourceScript = Join-Path $rootDir "VDOWNS_PRIME.ps1"
$outputExe = Join-Path $rootDir "VDOWNS_PRIME.exe"
$appsJson = Join-Path $rootDir "apps.json"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VDOWNS PRIME - Automated Build System (v3.2.0)         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Validate apps.json
Write-Host "`n[1/4] Verifying apps.json integrity..." -ForegroundColor Yellow
if (-not (Test-Path $appsJson)) {
    throw "apps.json not found at: $appsJson"
}
try {
    $appsContent = Get-Content $appsJson -Raw -Encoding UTF8 | ConvertFrom-Json
    $totalApps = 0
    foreach ($cat in $appsContent.PSObject.Properties) {
        if ($cat.Value -is [System.Collections.IEnumerable]) {
            $totalApps += @($cat.Value).Count
        }
    }
    Write-Host "  -> JSON syntax valid. Total software packages cataloged: $totalApps" -ForegroundColor Green
} catch {
    throw "Invalid JSON structure in apps.json: $_"
}

# 2. Syntax check VDOWNS_PRIME.ps1
Write-Host "`n[2/4] Validating PowerShell AST syntax for VDOWNS_PRIME.ps1..." -ForegroundColor Yellow
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourceScript, [ref]$null, [ref]$parseErrors)
if ($parseErrors -and $parseErrors.Count -gt 0) {
    foreach ($pe in $parseErrors) {
        Write-Host "  Error at line $($pe.Extent.StartLineNumber): $($pe.Message)" -ForegroundColor Red
    }
    throw "Syntax check failed for $sourceScript"
}
Write-Host "  -> VDOWNS_PRIME.ps1 syntax check PASSED (0 errors)." -ForegroundColor Green

# 3. Check ps2exe availability
if (-not $SkipCompile) {
    Write-Host "`n[3/4] Checking compiler requirements..." -ForegroundColor Yellow
    $cmd = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host "  ps2exe module not found. Installing for current user..." -ForegroundColor Cyan
        Install-Module -Name ps2exe -Scope CurrentUser -Force -SkipPublisherCheck
    }
    Write-Host "  -> Invoke-ps2exe is ready." -ForegroundColor Green

    # 4. Compile Standalone Executable
    Write-Host "`n[4/4] Compiling Standalone Executable (VDOWNS_PRIME.exe)..." -ForegroundColor Yellow
    
    $ps2exeParams = @{
        inputFile   = $sourceScript
        outputFile  = $outputExe
        STA         = $true
        noConsole   = $true
        title       = "VDOWNS PRIME"
        description = "Windows 10/11 Modern Optimization, Debloater & Winget Package Deployment Suite"
        company     = "VDOWNS Systems"
        product     = "VDOWNS PRIME"
        copyright   = "Copyright (c) 2026 VDOWNS PRIME Contributors"
        version     = "3.2.0.0"
        DPIAware    = $true
        supportOS   = $true
    }

    Invoke-ps2exe @ps2exeParams

    if (Test-Path $outputExe) {
        $fileInfo = Get-Item $outputExe
        $hash = (Get-FileHash -Path $outputExe -Algorithm SHA256).Hash
        Write-Host "`n==========================================================" -ForegroundColor Green
        Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "Binary: $($fileInfo.FullName)" -ForegroundColor Green
        Write-Host "Size:   $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Green
        Write-Host "SHA256: $hash" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
    } else {
        throw "Build failed: output executable was not generated."
    }
} else {
    Write-Host "`n[3/4 & 4/4] Compilation skipped as requested." -ForegroundColor Cyan
    Write-Host "Verification completed successfully." -ForegroundColor Green
}
