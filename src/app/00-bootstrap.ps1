<#
.SYNOPSIS
    VDOWNS PRIME - System Architect (WPF Edition). Version: see $script:VdownsVersion below.
.DESCRIPTION
    Advanced System Configuration Tool built with PowerShell + WPF.
    Features: App Center, System Tweaks, Windows Features, Debloater, Update & Repair Center, Backup & Restore Center, Winget Manager.
    
    Build the standalone exe with .\build.ps1 (pinned ps2exe, checks, SHA256SUMS).
#>

$ErrorActionPreference = "Continue"

# Single source of truth for the version (build.ps1 reads this line for the exe metadata)
$script:VdownsVersion = "3.4.0"

# CI smoke test: VDOWNS_SMOKE_TEST=1 loads the whole UI, writes a report and closes itself
# without any dialog (see .github/workflows/ci.yml). Inert in normal use.
$script:SmokeTest = ($env:VDOWNS_SMOKE_TEST -eq '1')
$script:SmokeReport = if ($env:VDOWNS_SMOKE_REPORT) { $env:VDOWNS_SMOKE_REPORT } else { Join-Path $env:TEMP 'vdowns-smoke.txt' }

# =============================================================================
# 1. ADMINISTRATION AND SECURITY CONTROL
# =============================================================================

if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $ScriptPath = [System.AppDomain]::CurrentDomain.BaseDirectory
} else {
    $ScriptPath = $PSScriptRoot
}
$ScriptPath = $ScriptPath.TrimEnd('\')

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ([string]::IsNullOrEmpty($PSCommandPath)) {
        try {
            $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            Start-Process $exePath -Verb RunAs
        } catch {
            Write-Host "ERROR: Please run as Administrator." -ForegroundColor Red
            # Read-Host removed for noConsole GUI
        }
    } else {
        Start-Process powershell.exe "-STA -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    Exit
}

# =============================================================================
# 2. LOAD ASSEMBLIES
# =============================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# High-Performance Native Win32 Telemetry Subsystem (Zero-blocking, 0.05ms execution)
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class NativeSysInfo {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public class MEMORYSTATUSEX {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
        public MEMORYSTATUSEX() { this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetSystemTimes(out long lpIdleTime, out long lpKernelTime, out long lpUserTime);

    private static long _prevIdle = 0;
    private static long _prevKernel = 0;
    private static long _prevUser = 0;

    public static int GetCpuLoad() {
        long idle, kernel, user;
        if (!GetSystemTimes(out idle, out kernel, out user)) return 0;
        if (_prevIdle == 0) {
            _prevIdle = idle; _prevKernel = kernel; _prevUser = user;
            return 3;
        }
        long usr = user - _prevUser;
        long ker = kernel - _prevKernel;
        long idl = idle - _prevIdle;
        _prevIdle = idle; _prevKernel = kernel; _prevUser = user;
        long sys = usr + ker;
        if (sys <= 0) return 0;
        int load = (int)((sys - idl) * 100 / sys);
        return Math.Max(0, Math.Min(100, load));
    }

    public static MEMORYSTATUSEX GetMemory() {
        MEMORYSTATUSEX mem = new MEMORYSTATUSEX();
        GlobalMemoryStatusEx(mem);
        return mem;
    }
}
'@ -ErrorAction SilentlyContinue

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {

