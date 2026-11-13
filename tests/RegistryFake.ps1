# In-memory registry/service/powercfg fakes for TweakState tests (portable, never touches the real system).
# Dot-source AFTER the library under test: these functions shadow the cmdlets for code in this scope.

function Reset-VdFakeSystem {
    $script:Reg = @{}
    $script:Svc = @{ DiagTrack = 'Running'; SysMain = 'Stopped' }
    $script:Active = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $script:Plans = @('381b4222-f694-41f0-9685-ff5bb260df2e')
}
function Get-VdFakeDump { ($script:Reg.Keys | Sort-Object | ForEach-Object { $k = $_; "$k :: " + (($script:Reg[$k].Keys | Sort-Object | ForEach-Object { "$_=" + $script:Reg[$k][$_].Kind + ":" + $script:Reg[$k][$_].Value }) -join ";") }) -join "`n" }
function Norm($p) { ($p -replace '^Microsoft\.PowerShell\.Core\\Registry::', '').ToLower() }
function Test-Path { param([Parameter(Position=0)]$Path, $LiteralPath) $p = if ($LiteralPath) { $LiteralPath } else { $Path }; $n = Norm $p; $script:Reg.ContainsKey($n) -or @($script:Reg.Keys | Where-Object { $_.StartsWith("$n\") }).Count -gt 0 }
function New-Item { param([Parameter(Position=0)]$Path, $ItemType, [switch]$Force) if (-not $script:Reg.ContainsKey((Norm $Path))) { $script:Reg[(Norm $Path)] = @{} } }
function Remove-Item { param($LiteralPath, $Path, [switch]$Recurse, [switch]$Force, $ErrorAction) $p = Norm $(if ($LiteralPath) { $LiteralPath } else { $Path }); foreach ($k in @($script:Reg.Keys)) { if ($k -eq $p -or $k.StartsWith("$p\")) { $script:Reg.Remove($k) } } }
function Get-Item { param([Parameter(Position=0)]$Path, $LiteralPath)
    $p = Norm $(if ($LiteralPath) { $LiteralPath } else { $Path }); $vals = $script:Reg[$p]
    $o = [pscustomobject]@{ V = $vals }
    $o | Add-Member ScriptMethod GetValueNames { @($this.V.Keys) }
    $o | Add-Member ScriptMethod GetValueKind { param($n) [Microsoft.Win32.RegistryValueKind]$this.V[$n].Kind }
    $o | Add-Member ScriptMethod GetValue { param($n, $d, $opt) if ($this.V.ContainsKey($n)) { $this.V[$n].Value } else { $d } }
    $o }
function New-ItemProperty { param($Path, $LiteralPath, $Name, $Value, $PropertyType, [switch]$Force, $ErrorAction)
    $p = Norm $(if ($LiteralPath) { $LiteralPath } else { $Path }); if (-not $script:Reg.ContainsKey($p)) { throw "key missing $p" }
    $v = switch ($PropertyType) { 'DWord' { [int]$Value } 'String' { [string]$Value } 'ExpandString' { [string]$Value } default { $Value } }
    $script:Reg[$p][$Name] = @{ Kind = $PropertyType; Value = $v } }
function Set-ItemProperty { param([Parameter(Position=0)]$Path, [Parameter(Position=1)]$Name, [Parameter(Position=2)]$Value)
    $p = Norm $Path; if (-not $script:Reg.ContainsKey($p)) { throw "key missing $p" }
    $kind = if ($Value -is [int]) { 'DWord' } else { 'String' }
    if ($script:Reg[$p].ContainsKey($Name)) { $kind = $script:Reg[$p][$Name].Kind }
    $script:Reg[$p][$Name] = @{ Kind = $kind; Value = $Value } }
function Remove-ItemProperty { param($Path, $LiteralPath, $Name, [switch]$Force, $ErrorAction) $p = Norm $(if ($LiteralPath) { $LiteralPath } else { $Path }); if ($script:Reg.ContainsKey($p)) { $script:Reg[$p].Remove($Name) } }
function Get-ItemProperty { param($Path, $Name, $ErrorAction) $p = Norm $Path; if ($script:Reg.ContainsKey($p) -and $script:Reg[$p].ContainsKey($Name)) { [pscustomobject]@{ $Name = $script:Reg[$p][$Name].Value } } }
function Get-Service { param($Name, $ErrorAction) if ($script:Svc.ContainsKey($Name)) { [pscustomobject]@{ Name = $Name; Status = $script:Svc[$Name] } } }
function Set-Service { param([Parameter(Position=0)]$Name, $StartupType) $v = @{ Disabled = 4; Automatic = 2; Manual = 3 }[$StartupType]; New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -Name Start -Value $v -PropertyType DWord }
function Stop-Service { param([Parameter(Position=0)]$Name) $script:Svc[$Name] = 'Stopped' }
function Start-Service { param([Parameter(Position=0)]$Name) $script:Svc[$Name] = 'Running' }
function powercfg { $a = $args
    switch -regex ($a[0]) {
        'getactivescheme' { "Power Scheme GUID: $($script:Active)  (Balanced)" }
        'list' { $script:Plans | ForEach-Object { "Power Scheme GUID: $_" } }
        'duplicatescheme' { $script:Plans += $a[2] }
        'setactive' { $script:Active = $a[1] }
        'delete' { $script:Plans = @($script:Plans | Where-Object { $_ -ne $a[1] }) }
        'hibernate' { $script:Hib = if ($a[1] -eq 'on') { 1 } else { 0 }; New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name HibernateEnabled -Value $script:Hib -PropertyType DWord }
    } }
function Set-Item { param([Parameter(Position=0)]$Path, $Value) $n = Norm $Path; if (-not $script:Reg.ContainsKey($n)) { throw "key missing $n" }; $script:Reg[$n]['(default)'] = @{ Kind = 'String'; Value = $Value } }
