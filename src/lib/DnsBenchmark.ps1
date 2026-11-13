$targets = [ordered]@{ 'Cloudflare' = '1.1.1.1'; 'Google' = '8.8.8.8'; 'Quad9' = '9.9.9.9'; 'AdGuard' = '94.140.14.14' }
$names = @('example.com', 'microsoft.com', 'wikipedia.org', 'github.com')
$rows = foreach ($k in $targets.Keys) {
    $ip = $targets[$k]; $times = @()
    foreach ($n in $names) {
        try {
            $sw = [Diagnostics.Stopwatch]::StartNew()
            $null = Resolve-DnsName -Name $n -Server $ip -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop
            $sw.Stop(); $times += $sw.Elapsed.TotalMilliseconds
        } catch {}
    }
    if ($times.Count -gt 0) {
        $avg = [math]::Round(($times | Measure-Object -Average).Average, 1)
        Write-Host ("{0,-11} {1,-15} {2,7} ms  ({3}/{4} lookups ok)" -f $k, $ip, $avg, $times.Count, $names.Count)
        [pscustomobject]@{ Name = $k; Avg = $avg }
    } else {
        Write-Host ("{0,-11} {1,-15}  no response" -f $k, $ip)
    }
}
$best = $rows | Sort-Object Avg | Select-Object -First 1
if ($best) { Write-Output "Fastest resolver from this network: $($best.Name)" }
