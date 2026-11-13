[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"
$ver = [version]"2.2.1.5"
$mod = Get-Module -ListAvailable -Name PSWindowsUpdate | Where-Object { $_.Version -eq $ver } | Select-Object -First 1
if (-not $mod) {
    Write-Host "Installing PSWindowsUpdate $ver from the PowerShell Gallery..."
    Install-Module -Name PSWindowsUpdate -RequiredVersion $ver -Scope AllUsers -Force -AllowClobber
    $mod = Get-Module -ListAvailable -Name PSWindowsUpdate | Where-Object { $_.Version -eq $ver } | Select-Object -First 1
}
if (-not $mod) { throw "PSWindowsUpdate $ver could not be installed." }
foreach ($f in @("PSWindowsUpdate.psd1", "PSWindowsUpdate.psm1", "PSWindowsUpdate.dll")) {
    $sig = Get-AuthenticodeSignature -FilePath (Join-Path $mod.ModuleBase $f)
    if ($sig.Status -ne "Valid" -or $sig.SignerCertificate.Subject -notmatch "Michal Gajda") {
        throw "PSWindowsUpdate signature check failed on $f ($($sig.Status)). Aborting without loading the module."
    }
}
Import-Module $mod.Path -Force
Write-Host "PSWindowsUpdate $ver loaded (signature verified)."
