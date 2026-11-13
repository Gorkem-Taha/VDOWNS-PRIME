function Get-VdProcessEncoding([string]$Encoding) {
    if ($Encoding -eq 'UTF8') { return (New-Object System.Text.UTF8Encoding($false)) }
    return [System.Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
}

function Invoke-VdNative {
    param([string]$File, [string[]]$ArgList = @(), [string]$Encoding = '')
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $File
    $psi.Arguments = (@($ArgList) | ForEach-Object { if ($_ -eq '' -or $_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $enc = Get-VdProcessEncoding $Encoding
    $psi.StandardOutputEncoding = $enc
    $psi.StandardErrorEncoding = $enc
    $proc = [System.Diagnostics.Process]::Start($psi)
    $errTask = $proc.StandardError.ReadToEndAsync()
    $out = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    [pscustomobject]@{ ExitCode = $proc.ExitCode; Output = ($out -replace "`0", ''); Error = ($errTask.Result -replace "`0", '') }
}

# Inside runspaces that load this library, `powercfg` resolves to this hidden wrapper.
function powercfg {
    $r = Invoke-VdNative 'powercfg.exe' ([string[]]$args)
    $global:LASTEXITCODE = $r.ExitCode
    if ($r.ExitCode -ne 0 -and $r.Error) { Write-Error ("powercfg: " + $r.Error.Trim()) }
    $r.Output -split "`r?`n" | Where-Object { $_ -ne '' }
}

# Parse winget's fixed-width tables (list/search) by the header's column offsets instead of
# splitting on runs of spaces, which broke on truncated names and adjacent columns.
function ConvertFrom-VdWingetTable([string]$Text) {
    $lines = @($Text -split "`n" | ForEach-Object { ($_ -split "`r")[-1] })
    $sep = -1
    for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*-{10,}\s*$') { $sep = $i; break } }
    if ($sep -lt 1) { return }
    $starts = @([regex]::Matches($lines[$sep - 1], '\S+') | ForEach-Object { $_.Index })
    if ($starts.Count -lt 3) { return }
    for ($i = $sep + 1; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($l)) { break }   # a blank line ends the table
        $cells = for ($c = 0; $c -lt $starts.Count; $c++) {
            $a = $starts[$c]
            $b = if ($c + 1 -lt $starts.Count) { $starts[$c + 1] } else { $l.Length }
            if ($a -ge $l.Length) { '' } else { $l.Substring($a, [math]::Min($b, $l.Length) - $a).Trim() }
        }
        $cells = @($cells)
        if (-not $cells[1]) { continue }
        @{ Name = $cells[0]; Id = $cells[1]; Version = $cells[2]; Source = $(if ($starts.Count -ge 4) { $cells[-1] } else { '' }) }
    }
}
