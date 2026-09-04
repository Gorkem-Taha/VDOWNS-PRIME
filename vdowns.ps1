<#
.SYNOPSIS
    VDOWNS PRIME - Legacy entry point forwarder.
.DESCRIPTION
    Redirects execution to the canonical VDOWNS_PRIME.ps1 engine.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $RemainingArgs
)

$targetScript = Join-Path -Path $PSScriptRoot -ChildPath "VDOWNS_PRIME.ps1"
if (Test-Path -Path $targetScript) {
    & $targetScript @RemainingArgs
} else {
    Write-Error "VDOWNS_PRIME.ps1 not found: $targetScript"
}
