# =============================================================================
# 13C. DNS OPTIMIZER & LATENCY BENCHMARK
# =============================================================================
function Get-ActivePhysicalAdapter {
    @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Virtual|Hyper-V|Loopback|WSL|VPN|TAP|PANGP|WireGuard|Tailscale|ZeroTier" })
}

# IPv4 + IPv6 pairs: setting only IPv4 left the router's IPv6 resolver in use on dual-stack networks
$script:DnsProviders = [ordered]@{
    "Cloudflare (1.1.1.1 / 1.0.0.1) - Privacy & Low Latency"        = @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001")
    "Google Public DNS (8.8.8.8 / 8.8.4.4) - Fast & Reliable"        = @("8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844")
    "AdGuard DNS (94.140.14.14 / 94.140.15.15) - Ad & Tracker Block" = @("94.140.14.14", "94.140.15.15", "2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff")
    "Quad9 (9.9.9.9 / 149.112.112.112) - Malware Threat Protection"  = @("9.9.9.9", "149.112.112.112", "2620:fe::fe", "2620:fe::9")
}

if ($cbDnsProvider) {
    $cbDnsProvider.Items.Clear()
    foreach ($k in $script:DnsProviders.Keys) { [void]$cbDnsProvider.Items.Add($k) }
    $cbDnsProvider.SelectedIndex = 0
}

try {
    $actAdapters = Get-ActivePhysicalAdapter
    if ($actAdapters.Count -gt 0 -and $lblActiveDnsAdapter) {
        $lblActiveDnsAdapter.Text = "Active: " + (($actAdapters | ForEach-Object { $_.Name }) -join ", ")
    }
} catch { Write-Verbose "Active adapter label not updated: $($_.Exception.Message)" }

if ($btnApplyDns) {
    $btnApplyDns.Add_Click({
        $adapters = Get-ActivePhysicalAdapter
        if ($adapters.Count -eq 0) {
            Write-AppLog "No active physical network adapter detected." "ERROR"
            return
        }
        $selectedKey = $cbDnsProvider.SelectedItem
        $servers = $script:DnsProviders[$selectedKey]
        if (-not $servers) { return }
        $ok = @(); $failed = @()
        foreach ($a in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $servers -ErrorAction Stop
                $ok += $a.Name
            } catch {
                $failed += "$($a.Name): $($_.Exception.Message)"
            }
        }
        try { Clear-DnsClientCache -ErrorAction Stop } catch { Write-AppLog "Could not flush the DNS cache: $($_.Exception.Message)" "WARN" }
        if ($ok.Count -gt 0) { Write-AppLog "DNS set to $selectedKey on: $($ok -join ', ') (IPv4 + IPv6)." "SUCCESS" }
        foreach ($f in $failed) { Write-AppLog "DNS change failed on $f" "ERROR" }
        $summary = if ($failed.Count -eq 0) { "DNS updated on: $($ok -join ', ')" } else { "Updated: $($ok -join ', ')`nFailed: $($failed.Count) adapter(s) - see the log." }
        [System.Windows.MessageBox]::Show("$summary`n`nServers:`n$($servers -join "`n")", "DNS", "OK", $(if ($failed.Count -eq 0) { "Information" } else { "Warning" })) | Out-Null
    })
}

if ($btnResetDns) {
    $btnResetDns.Add_Click({
        $adapters = Get-ActivePhysicalAdapter
        if ($adapters.Count -eq 0) { Write-AppLog "No active physical network adapter detected." "ERROR"; return }
        foreach ($a in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ResetServerAddresses -ErrorAction Stop
                Write-AppLog "DNS on '$($a.Name)' reset to automatic (DHCP)." "SUCCESS"
            } catch {
                Write-AppLog "DNS reset failed on '$($a.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
        try { Clear-DnsClientCache -ErrorAction Stop } catch { Write-AppLog "Could not flush the DNS cache: $($_.Exception.Message)" "WARN" }
    })
}

if ($btnPingDns) {
    $btnPingDns.Add_Click({
        # Measures real DNS lookups against each resolver (ping only measured ICMP round-trip) and
        # runs in a separate process so slow or blocked resolvers cannot freeze the window.
        Write-AppLog "Starting DNS lookup benchmark in the background..." "ACTION"
        Start-PSStreamingCommand @'
#@include lib/DnsBenchmark.ps1
'@
    })
}

