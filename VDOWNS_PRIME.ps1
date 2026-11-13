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

# =============================================================================
# 3. XAML INTERFACE DEFINITION
# =============================================================================
[xml]$xaml = @'
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="VDOWNS PRIME | Fluent System Architect"
    Width="1320" Height="820"
    WindowStartupLocation="CenterScreen"
    WindowState="Maximized"
    Background="#0D1117"
    Foreground="#E6EDF3"
    FontFamily="Segoe UI"
    MinWidth="980" MinHeight="680">

    <Window.Resources>

        <!-- MODERN SIDEBAR BUTTON WITH SVG PATH -->
        <Style x:Key="SidebarBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#8B949E"/>
            <Setter Property="FontSize" Value="13.5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Margin" Value="8,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="bd" Background="Transparent" CornerRadius="8" Padding="12,10">
                                <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                            </Border>
                            <Border x:Name="activeIndicator" Width="3" Height="20" Background="#58A6FF" 
                                    CornerRadius="1.5" HorizontalAlignment="Left" VerticalAlignment="Center" 
                                    Margin="2,0,0,0" Visibility="Collapsed"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#161B22"/>
                                <Setter Property="Foreground" Value="#E6EDF3"/>
                            </Trigger>
                            <Trigger Property="Tag" Value="Active">
                                <Setter TargetName="bd" Property="Background" Value="#1C2128"/>
                                <Setter TargetName="activeIndicator" Property="Visibility" Value="Visible"/>
                                <Setter Property="Foreground" Value="#58A6FF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ROUNDED ACTION BUTTON -->
        <Style x:Key="RoundedBtn" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="bg" Background="{TemplateBinding Background}" 
                                    CornerRadius="8" Padding="{TemplateBinding Padding}"/>
                            <Border x:Name="hoverOverlay" Background="White" CornerRadius="8" Opacity="0"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" 
                                              Margin="{TemplateBinding Padding}"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="hoverOverlay" Property="Opacity" Value="0.1"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="hoverOverlay" Property="Opacity" Value="0.2"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bg" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- SUB-TAB BUTTON -->
        <Style x:Key="SubTabBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#8B949E"/>
            <Setter Property="Background" Value="#161B22"/>
            <Setter Property="FontSize" Value="12.5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="14,6"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" 
                                CornerRadius="6" BorderBrush="#30363D" BorderThickness="1" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#21262D"/>
                                <Setter Property="Foreground" Value="#E6EDF3"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#58A6FF"/>
                            </Trigger>
                            <Trigger Property="Tag" Value="Active">
                                <Setter TargetName="bd" Property="Background" Value="#1F6FEB"/>
                                <Setter Property="Foreground" Value="White"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#58A6FF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="235"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ==================== SIDEBAR ==================== -->
        <Border Grid.Column="0" Background="#090D13" BorderBrush="#21262D" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Brand Header -->
                <StackPanel Grid.Row="0" Margin="0,22,0,16" HorizontalAlignment="Center">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <TextBlock Text="VDOWNS" FontSize="24" FontWeight="Bold" Foreground="#58A6FF" VerticalAlignment="Center"/>
                        <Border Background="#1F2937" CornerRadius="4" Padding="6,2" Margin="8,0,0,0" VerticalAlignment="Center">
                            <TextBlock x:Name="lblVersionBadge" Text="v3" FontSize="10" FontWeight="Bold" Foreground="#22D3EE"/>
                        </Border>
                    </StackPanel>
                    <TextBlock Text="FLUENT SYSTEM ARCHITECT" FontSize="10" FontWeight="Bold" Foreground="#484F58" HorizontalAlignment="Center" Margin="0,3,0,0"/>
                    <Border Height="1" Background="#21262D" Margin="16,14,16,0"/>
                </StackPanel>

                <!-- Navigation Menu -->
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel Margin="4,2,4,0">
                        <Button x:Name="btnMenuInstall" Style="{StaticResource SidebarBtn}" Tag="Active">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M3 4a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm8 0a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1V4zM3 12a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1v-4zm8 0a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="Applications" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuWinget" Style="{StaticResource SidebarBtn}" Visibility="Collapsed">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 1a1 1 0 00-.5.13L1.5 4.38A1 1 0 001 5.25v5.5a1 1 0 00.5.87l6 3.25a1 1 0 001 0l6-3.25a1 1 0 00.5-.87v-5.5a1 1 0 00-.5-.87L8.5 1.13A1 1 0 008 1zM2.5 5.5l5.5-3 5.5 3-5.5 3-5.5-3zm6 4.14l5.5-3v4.72l-5.5 2.98V9.64zm-1 0v4.72l-5.5-2.98V6.64l5.5 3z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="Winget Manager" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuTweaks" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M9.13 1.07a1 1 0 00-1.04.14L1.3 7.07A1 1 0 002 8.75h4.25L4.87 14.93a1 1 0 001.7.94l6.79-5.86a1 1 0 00-.7-1.76H8.41l1.38-6.18a1 1 0 00-.66-1z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="System Tweaks" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuConfig" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 0a2 2 0 00-2 2v.26A5 5 0 004.26 3.4l-.18-.18a2 2 0 00-2.83 2.83l.18.18A5 5 0 001.26 8H1a2 2 0 00-2 2 2 2 0 002 2h.26a5 5 0 001.14 1.74l-.18.18a2 2 0 002.83 2.83l.18-.18A5 5 0 008 17.74V18a2 2 0 002 2 2 2 0 002-2v-.26a5 5 0 001.74-1.14l.18.18a2 2 0 002.83-2.83l-.18-.18A5 5 0 0017.74 12H18a2 2 0 002-2 2 2 0 00-2-2h-.26a5 5 0 00-1.14-1.74l.18-.18a2 2 0 00-2.83-2.83l-.18.18A5 5 0 0012 2.26V2a2 2 0 00-2-2zm0 6a4 4 0 110 8 4 4 0 010-8z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="Features &amp; Maintenance" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuDebloat" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 0c-.8 0-4.5 1.5-7.5 2.5C.2 2.6 0 2.9 0 3.3c0 7.2 4.4 12 8 13.7 3.6-1.7 8-6.5 8-13.7 0-.4-.2-.7-.5-.8C12.5 1.5 8.8 0 8 0zm0 1.5c.6 0 3.8 1.3 6.5 2.2C14.2 8.7 10.7 13 8 14.6 5.3 13 1.8 8.7 1.5 3.7 4.2 2.8 7.4 1.5 8 1.5z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="OS Debloater" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuUpdates" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 1.5a6.5 6.5 0 106.18 4.5h-1.57A5 5 0 118 3v2l4-2.5L8 0v1.5z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="Repair &amp; Updates" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuBackup" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M4 4a4 4 0 017.9-1A3.5 3.5 0 0115 6.5a3.5 3.5 0 01-3.5 3.5H4a4 4 0 010-8zm4 1v3.5h2L7.5 11 5 8.5h2V5h1z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}"/>
                                </Viewbox>
                                <TextBlock Text="Backup &amp; Deploy" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>
                    </StackPanel>
                </ScrollViewer>

                <!-- Live Hardware Telemetry Panel -->
                <Border Grid.Row="2" Background="#161B22" CornerRadius="8" BorderBrush="#21262D" BorderThickness="1" Margin="10,4" Padding="10,8">
                    <StackPanel>
                        <Grid Margin="0,0,0,4">
                            <TextBlock x:Name="lblOsInfo" Text="Windows 11 x64" Foreground="#8B949E" FontSize="10" FontWeight="SemiBold" TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"/>
                            <TextBlock Text="● LIVE" FontSize="9" FontWeight="Bold" Foreground="#3FB950" HorizontalAlignment="Right"/>
                        </Grid>

                        <!-- CPU Load -->
                        <Grid Margin="0,3,0,2">
                            <TextBlock Text="CPU" FontSize="9.5" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblCpuPct" Text="-- %" FontSize="9.5" Foreground="#58A6FF" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbCpu" Height="3" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#58A6FF" BorderThickness="0"/>

                        <!-- RAM Usage -->
                        <Grid Margin="0,3,0,2">
                            <TextBlock Text="Memory" FontSize="9.5" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblRamPct" Text="-- GB" FontSize="9.5" Foreground="#3FB950" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbRam" Height="3" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#3FB950" BorderThickness="0"/>

                        <!-- Disk Space -->
                        <Grid Margin="0,3,0,2">
                            <TextBlock Text="Storage (C:)" FontSize="9.5" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblDiskPct" Text="-- GB" FontSize="9.5" Foreground="#A855F7" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbDisk" Height="3" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#A855F7" BorderThickness="0"/>
                    </StackPanel>
                </Border>

                <!-- Terminate Application -->
                <Button Grid.Row="3" x:Name="btnExit" Style="{StaticResource SidebarBtn}" Margin="8,4,8,10">
                    <StackPanel Orientation="Horizontal">
                        <Viewbox Width="14" Height="14" Margin="0,0,8,0">
                            <Path Data="M3.72 3.72a.75.75 0 011.06 0L8 6.94l3.22-3.22a.75.75 0 111.06 1.06L9.06 8l3.22 3.22a.75.75 0 11-1.06 1.06L8 9.06l-3.22 3.22a.75.75 0 01-1.06-1.06L6.94 8 3.72 4.78a.75.75 0 010-1.06z" Fill="#F85149"/>
                        </Viewbox>
                        <TextBlock Text="Exit VDOWNS" Foreground="#8B949E" FontWeight="SemiBold" FontSize="12.5"/>
                    </StackPanel>
                </Button>
            </Grid>
        </Border>

        <!-- ==================== MAIN CONTENT ==================== -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <!-- 0: Top Health & Optimization Banner -->
                <RowDefinition Height="*"/>    <!-- 1: Page Views Container -->
                <RowDefinition Height="Auto"/> <!-- 2: Collapsible Console Drawer -->
            </Grid.RowDefinitions>

            <!-- ===== TOP DASHBOARD & PC HEALTH BANNER ===== -->
            <Border Grid.Row="0" Background="#0C1017" BorderBrush="#21262D" BorderThickness="0,0,0,1" Padding="18,8">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                        <Border Background="#161B22" CornerRadius="6" BorderBrush="#30363D" BorderThickness="1" Padding="10,4" Margin="0,0,10,0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="🛡️ " FontSize="11" VerticalAlignment="Center"/>
                                <TextBlock Text="PC Health: " FontSize="11.5" Foreground="#8B949E" VerticalAlignment="Center"/>
                                <TextBlock x:Name="lblHealthScore" Text="Analyzing..." FontSize="11.5" FontWeight="Bold" Foreground="#3FB950" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                        <Button x:Name="btnRefreshHealth" Content="🔄 Refresh" Background="#21262D" Foreground="#8B949E" FontSize="11" FontWeight="SemiBold" Padding="10,4" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>

                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button x:Name="btnPrimeBoost" Content="⚡ Quick Boost" Background="#238636" Foreground="White" FontSize="12" FontWeight="Bold" Padding="16,6" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- ===== PAGE: APPLICATIONS & PACKAGES ===== -->
            <Grid x:Name="pageInstall" Grid.Row="1" Margin="25,16,25,12">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <!-- 0: Header -->
                    <RowDefinition Height="Auto"/> <!-- 1: SubTab Switcher -->
                    <RowDefinition Height="*"/>    <!-- 2: View Container -->
                </Grid.RowDefinitions>

                <!-- Header -->
                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Applications &amp; Packages" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Curated software catalog, online Winget repository search, and local package manager" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>

                <!-- Sub-Tab Switcher -->
                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,12">
                    <Button x:Name="btnTabCurated" Content="📦 Curated Catalog (96 Apps)" Style="{StaticResource SubTabBtn}" Tag="Active"/>
                    <Button x:Name="btnTabWinget" Content="⚡ Winget Store &amp; Installed" Style="{StaticResource SubTabBtn}"/>
                </StackPanel>

                <!-- Views Container -->
                <Grid Grid.Row="2">
                    <!-- VIEW 1: CURATED CATALOG -->
                    <Grid x:Name="viewCurated">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/> <!-- Search & Controls -->
                            <RowDefinition Height="Auto"/> <!-- Category Filter Chips -->
                            <RowDefinition Height="*"/>    <!-- Cards Container -->
                            <RowDefinition Height="Auto"/> <!-- Progress Panel -->
                            <RowDefinition Height="Auto"/> <!-- Main Action Buttons -->
                        </Grid.RowDefinitions>

                        <!-- Search and Controls bar -->
                        <Grid Grid.Row="0" Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="10"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="6"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="6"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <Grid Grid.Column="0">
                                <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="2">
                                    <TextBox x:Name="searchBox" Background="Transparent" Foreground="#E6EDF3" 
                                             BorderThickness="0" FontSize="13" Padding="12,7" CaretBrush="#E6EDF3"/>
                                </Border>
                                <TextBlock x:Name="searchPlaceholder" Text="  🔍  Search 96 software packages by name, keyword, or Winget ID..." 
                                           Foreground="#484F58" FontSize="12" VerticalAlignment="Center" 
                                           Margin="12,0" IsHitTestVisible="False"/>
                            </Grid>

                            <Button x:Name="btnAddCustomApp" Grid.Column="2" Content="➕ Add App" 
                                    Background="#1F6FEB" Foreground="White" FontSize="12" FontWeight="SemiBold" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                            <Button x:Name="btnAppSelectAll" Grid.Column="4" Content="Select All" 
                                    Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                            <Button x:Name="btnAppDeselectAll" Grid.Column="6" Content="Deselect All" 
                                    Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                        </Grid>

                        <!-- Category Filter Chips -->
                        <ScrollViewer Grid.Row="1" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled" Margin="0,0,0,10">
                            <StackPanel x:Name="filterChipsPanel" Orientation="Horizontal"/>
                        </ScrollViewer>

                        <!-- App Cards View -->
                        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel x:Name="appContainer"/>
                        </ScrollViewer>

                        <!-- Progress Panel -->
                        <Border x:Name="progressPanel" Grid.Row="3" Visibility="Collapsed" 
                                Background="#161B22" CornerRadius="8" Padding="12" Margin="0,10,0,0" 
                                BorderBrush="#30363D" BorderThickness="1">
                            <StackPanel>
                                <TextBlock x:Name="progressText" Text="" Foreground="#E6EDF3" FontSize="13" FontWeight="SemiBold" Margin="0,0,0,6"/>
                                <ProgressBar x:Name="progressBar" Height="6" Minimum="0" Maximum="100" Value="0" 
                                             Foreground="#58A6FF" Background="#21262D" BorderThickness="0"/>
                            </StackPanel>
                        </Border>

                        <!-- Batch Action Buttons -->
                        <Grid Grid.Row="4" Margin="0,10,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="12"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Button x:Name="btnInstall" Grid.Column="0" Content="Install Selected" 
                                    Background="#238636" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                            <Button x:Name="btnUninstall" Grid.Column="2" Content="Uninstall Selected" 
                                    Background="#DA3633" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                        </Grid>
                    </Grid>

                    <!-- VIEW 2: WINGET STORE & INSTALLED -->
                    <Grid x:Name="viewWinget" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <!-- Controls & Search Bar -->
                        <Grid Grid.Row="0" Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="10"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="6"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="6"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <Grid Grid.Column="0">
                                <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="2">
                                    <TextBox x:Name="wingetSearchBox" Background="Transparent" Foreground="#E6EDF3" 
                                             BorderThickness="0" FontSize="13" Padding="12,7" CaretBrush="#E6EDF3"/>
                                </Border>
                                <TextBlock x:Name="wingetSearchPlaceholder" Text="  🔍  Search thousands of packages on Microsoft Winget repo..." 
                                           Foreground="#484F58" FontSize="12" VerticalAlignment="Center" 
                                           Margin="12,0" IsHitTestVisible="False"/>
                            </Grid>

                            <Button x:Name="btnWingetSearch" Grid.Column="2" Content="Search Online" 
                                    Background="#1F6FEB" Foreground="White" FontSize="12" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                            <Button x:Name="btnScanWingetInstalled" Grid.Column="4" Content="Scan Installed" 
                                    Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                            <Button x:Name="btnWingetUpgradeAll" Grid.Column="6" Content="Upgrade All" 
                                    Background="#238636" Foreground="White" FontSize="12" Padding="14,7" Style="{StaticResource RoundedBtn}"/>
                        </Grid>

                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="wingetResultsContainer"/>
                        </ScrollViewer>

                        <Border x:Name="wingetProgressPanel" Grid.Row="2" Visibility="Collapsed" 
                                Background="#161B22" CornerRadius="8" Padding="12" Margin="0,10,0,0" 
                                BorderBrush="#30363D" BorderThickness="1">
                            <StackPanel>
                                <TextBlock x:Name="wingetProgressText" Text="Loading Winget Data..." Foreground="#E6EDF3" FontSize="13" FontWeight="SemiBold" Margin="0,0,0,6"/>
                                <ProgressBar x:Name="wingetProgressBar" Height="6" IsIndeterminate="True" 
                                             Foreground="#58A6FF" Background="#21262D" BorderThickness="0"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Grid>
            </Grid>

            <!-- Backwards-compatibility dummy placeholder -->
            <Grid x:Name="pageWinget" Visibility="Collapsed"/>

            <!-- ===== PAGE: SYSTEM TWEAKS ===== -->
            <Grid x:Name="pageTweaks" Grid.Row="1" Margin="25,16,25,12" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="System Tweaks" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Safe, reversible performance, privacy, and interface optimizations for Windows 10 and 11" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <WrapPanel x:Name="tweakContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnApplyTweaks" Grid.Column="0" Content="Apply Selected Tweaks" 
                            Background="#238636" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnRevertTweaks" Grid.Column="2" Content="Revert Selected Tweaks" 
                            Background="#DA3633" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: FEATURES & CONFIG ===== -->
            <Grid x:Name="pageConfig" Grid.Row="1" Margin="25,16,25,12" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Windows Features &amp; Maintenance" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Enable optional Windows subsystems and optimize background startup programs" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <StackPanel x:Name="featureContainer"/>

                        <!-- Windows Startup Programs Optimizer -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16" Margin="0,14,0,0">
                            <StackPanel>
                                <Grid Margin="0,0,0,8">
                                    <TextBlock Text="Windows Startup Programs" FontSize="15" FontWeight="SemiBold" Foreground="#A855F7"/>
                                    <Button x:Name="btnScanStartup" Content="🔄 Scan Startup Items" HorizontalAlignment="Right" Background="#21262D" Foreground="#E6EDF3" FontSize="11" FontWeight="SemiBold" Padding="12,4" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <TextBlock Text="Manage background applications that launch automatically when Windows boots." Foreground="#8B949E" FontSize="11.5" Margin="0,0,0,10"/>
                                <ScrollViewer MaxHeight="220" VerticalScrollBarVisibility="Auto" Margin="0,0,0,10">
                                    <StackPanel x:Name="startupContainer"/>
                                </ScrollViewer>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnDisableStartup" Grid.Column="0" Content="Disable Selected Items" Background="#DA3633" FontSize="12" Padding="0,8" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnEnableStartup" Grid.Column="2" Content="Re-enable Selected Items" Background="#238636" FontSize="12" Padding="0,8" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnInstallFeatures" Grid.Column="0" Content="Enable Selected Features" 
                            Background="#238636" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnDeepClean" Grid.Column="2" Content="Clean System Junk" 
                            Background="#58A6FF" FontSize="14" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: DEBLOATER ===== -->
            <Grid x:Name="pageDebloat" Grid.Row="1" Margin="25,16,25,12" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Windows Debloater" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Safely remove pre-installed Windows UWP apps and telemetry packages to free RAM" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                    <CheckBox x:Name="chkDebloatProvisioned" Margin="0,8,0,0" Foreground="#E6EDF3" FontSize="12"
                              Content="Also remove for new user accounts (provisioned packages - prevents the apps from coming back for new users)"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <WrapPanel x:Name="debloatContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid Grid.Column="0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="btnDebloatSelectAll" Grid.Column="0" Content="Select Recommended" 
                                Background="#21262D" FontSize="13.5" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnDebloatClear" Grid.Column="2" Content="Clear Selection" 
                                Background="#21262D" FontSize="13.5" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                    </Grid>
                    <Button x:Name="btnRemoveBloat" Grid.Column="2" Content="Remove Selected Bloat" 
                            Background="#DA3633" FontSize="13.5" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: UPDATES & REPAIR ===== -->
            <Grid x:Name="pageUpdates" Grid.Row="1" Margin="25,16,25,12" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Update &amp; System Repair Center" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Update software, scan and repair Windows image corruptions, and reset network stack" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <!-- Update Cards -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Text="Update Modules" FontSize="15" FontWeight="SemiBold" Foreground="#58A6FF" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="8"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <Button x:Name="btnUpdateApps" Grid.Row="0" Grid.Column="0" Content="Update All Apps (Winget)" Background="#238636" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateWindows" Grid.Row="0" Grid.Column="2" Content="Update Windows (OS)" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateDrivers" Grid.Row="2" Grid.Column="0" Content="Update Drivers Only" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateStore" Grid.Row="2" Grid.Column="2" Content="Update Store Apps" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Grid Margin="0,8,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnPauseUpdates" Grid.Column="0" Content="Pause Updates (35 Days)" Background="#D29922" Foreground="Black" FontWeight="SemiBold" FontSize="12" Padding="0,9" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResumeUpdates" Grid.Column="2" Content="Resume Automatic Updates" Background="#21262D" FontSize="12" Padding="0,9" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- Repair Cards -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16">
                            <StackPanel>
                                <TextBlock Text="System Repair &amp; Diagnostics" FontSize="15" FontWeight="SemiBold" Foreground="#A855F7" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="8"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <Button x:Name="btnRepairSfc" Grid.Row="0" Grid.Column="0" Content="Scan System Integrity (SFC)" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnRepairDism" Grid.Row="0" Grid.Column="2" Content="Repair Windows Image (DISM)" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResetNetwork" Grid.Row="2" Grid.Column="0" Content="Reset Network Stack" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnFixUpdates" Grid.Row="2" Grid.Column="2" Content="Purge Update Cache" Background="#DA3633" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- DNS Optimizer & Latency Benchmark -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16" Margin="0,12,0,0">
                            <StackPanel>
                                <Grid Margin="0,0,0,8">
                                    <TextBlock Text="DNS Optimizer &amp; Latency Benchmark" FontSize="15" FontWeight="SemiBold" Foreground="#22D3EE"/>
                                    <TextBlock x:Name="lblActiveDnsAdapter" Text="Active Adapter: Detecting..." Foreground="#8B949E" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                                </Grid>
                                <TextBlock Text="Switch your DNS provider to reduce latency and eliminate tracking." Foreground="#8B949E" FontSize="11.5" Margin="0,0,0,10"/>
                                <Grid Margin="0,0,0,10">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <ComboBox x:Name="cbDnsProvider" Grid.Column="0" Height="34" Background="#21262D" Foreground="#E6EDF3" FontSize="12.5" VerticalContentAlignment="Center" Padding="8,0"/>
                                    <Button x:Name="btnApplyDns" Grid.Column="2" Content="Apply DNS Provider" Background="#238636" FontSize="12.5" Padding="0,9" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnPingDns" Grid.Column="0" Content="⚡ Benchmark DNS Latencies" Background="#1F6FEB" FontSize="12" Padding="0,9" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResetDns" Grid.Column="2" Content="Reset to Default (DHCP)" Background="#21262D" FontSize="12" Padding="0,9" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ===== PAGE: BACKUP & RESTORE ===== -->
            <Grid x:Name="pageBackup" Grid.Row="1" Margin="25,16,25,12" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Backup &amp; Deployment Center" FontSize="20" FontWeight="SemiBold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Export configurations, generate unattended bare-metal deployment scripts, and archive developer environments" Foreground="#8B949E" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <!-- SECTION 1: SYSTEM PROFILE BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Text="1. VDOWNS System Profile &amp; Unattended Script" FontSize="15" FontWeight="SemiBold" Foreground="#58A6FF" Margin="0,0,0,4"/>
                                <TextBlock Text="Export selected apps, tweaks, and debloat settings, or generate a standalone provisioning script." Foreground="#8B949E" FontSize="11.5" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnExportProfile" Grid.Column="0" Content="Export Profile (.vdowns)" Background="#58A6FF" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnImportProfile" Grid.Column="2" Content="Import Profile &amp; Apply" Background="#238636" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Button x:Name="btnExportUnattendedScript" Margin="0,8,0,0" Content="⚡ Generate Unattended Setup Script (.ps1)" Background="#1F6FEB" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 2: APPDATA CONFIG BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Text="2. Developer Environment &amp; AppData Snapshot (.zip)" FontSize="15" FontWeight="SemiBold" Foreground="#A855F7" Margin="0,0,0,4"/>
                                <TextBlock Text="Archive developer configurations (VS Code, Cursor, Git, Terminal, SSH) into a portable compressed archive." Foreground="#8B949E" FontSize="11.5" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnBackupConfig" Grid.Column="0" Content="Create Developer Backup (.zip)" Background="#8957E5" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnRestoreConfig" Grid.Column="2" Content="Restore Developer Backup (.zip)" Background="#D29922" Foreground="Black" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 3: WINGET BUNDLE BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="16">
                            <StackPanel>
                                <TextBlock Text="3. Winget Installed Packages List" FontSize="15" FontWeight="SemiBold" Foreground="#22D3EE" Margin="0,0,0,4"/>
                                <TextBlock Text="Export installed applications via native Winget manifest, or restore missing packages on clean installations." Foreground="#8B949E" FontSize="11.5" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="10"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnWingetExport" Grid.Column="0" Content="Export Winget Manifest" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnWingetImport" Grid.Column="2" Content="Import Winget Manifest" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ===== COLLAPSIBLE LIVE LOG PANEL ===== -->
            <Border Grid.Row="2" Background="#0D1117" BorderBrush="#21262D" BorderThickness="0,1,0,0">
                <Grid x:Name="logPanelGrid" Height="32">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="14,4,14,4">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="ACTIVITY CONSOLE" Foreground="#8B949E" FontSize="10" FontWeight="Bold"/>
                            <Border Background="#161B22" CornerRadius="4" Padding="6,1" Margin="8,0,0,0">
                                <TextBlock x:Name="lblLogCount" Text="READY" Foreground="#58A6FF" FontSize="9" FontWeight="SemiBold"/>
                            </Border>
                        </StackPanel>

                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button x:Name="btnCopyLog" Content="📋 Copy" Background="Transparent" Foreground="#8B949E" FontSize="11" Padding="8,3" Style="{StaticResource RoundedBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="btnClearLog" Content="🧹 Clear" Background="Transparent" Foreground="#8B949E" FontSize="11" Padding="8,3" Style="{StaticResource RoundedBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="btnToggleLog" Content="▲ Expand" Background="#161B22" Foreground="#C9D1D9" FontSize="10.5" FontWeight="SemiBold" Padding="10,3" Style="{StaticResource RoundedBtn}"/>
                        </StackPanel>
                    </Grid>

                    <TextBox x:Name="logBox" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap" 
                             VerticalScrollBarVisibility="Auto" Background="#090D13" Foreground="#8B949E" 
                             FontFamily="Consolas" FontSize="11" BorderThickness="0" Padding="14,4"
                             AcceptsReturn="True" Visibility="Collapsed"/>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
'@

# =============================================================================
# 4. PARSE XAML AND FIND ELEMENTS
# =============================================================================
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$script:window = $window
$window.Title = "VDOWNS PRIME v$($script:VdownsVersion) | Fluent System Architect"

# Auto-discover all named elements and register globally across scopes
$global:window = $window
$script:window = $window
$global:Controls = @{}
$script:Controls = @{}

$nsmgr = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$nsmgr.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
$nodes = $xaml.SelectNodes('//*[@x:Name]', $nsmgr)
foreach ($node in $nodes) {
    $elName = $node.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
    if ($elName) {
        $el = $window.FindName($elName)
        if ($el) {
            Set-Variable -Name $elName -Value $el -Scope Script -Force
            Set-Variable -Name $elName -Value $el -Scope Global -Force
            Set-Variable -Name $elName -Value $el -Force
            $global:Controls[$elName] = $el
            $script:Controls[$elName] = $el
        }
    }
}

function Get-UIElement {
    param([string]$Name)
    if ($global:Controls -and $global:Controls.ContainsKey($Name) -and $global:Controls[$Name]) { return $global:Controls[$Name] }
    if ($script:Controls -and $script:Controls.ContainsKey($Name) -and $script:Controls[$Name]) { return $script:Controls[$Name] }
    if ($window) { $c = $window.FindName($Name); if ($c) { return $c } }
    if ($script:window) { $c = $script:window.FindName($Name); if ($c) { return $c } }
    if ($global:window) { $c = $global:window.FindName($Name); if ($c) { return $c } }
    $v = Get-Variable -Name $Name -Scope Script -ErrorAction SilentlyContinue
    if ($v -and $v.Value) { return $v.Value }
    $v = Get-Variable -Name $Name -Scope Global -ErrorAction SilentlyContinue
    if ($v -and $v.Value) { return $v.Value }
    return $null
}

if ($lblVersionBadge) { $lblVersionBadge.Text = "v$($script:VdownsVersion)" }

# Explicit aliases for XAML to script element compatibility
$script:tweaksContainer = $script:tweakContainer; $tweaksContainer = $tweakContainer; $global:tweaksContainer = $tweakContainer
$script:configContainer = $script:featureContainer; $configContainer = $featureContainer; $global:configContainer = $featureContainer
$script:wingetItemsContainer = $script:wingetResultsContainer; $wingetItemsContainer = $wingetResultsContainer; $global:wingetItemsContainer = $wingetResultsContainer
$script:btnDebloat = $script:btnRemoveBloat; $btnDebloat = $btnRemoveBloat; $global:btnDebloat = $btnRemoveBloat
$script:btnSelectAll = $script:btnDebloatSelectAll; $btnSelectAll = $btnDebloatSelectAll; $global:btnSelectAll = $btnDebloatSelectAll
$script:btnDeselectAll = $script:btnDebloatClear; $btnDeselectAll = $btnDebloatClear; $global:btnDeselectAll = $btnDebloatClear
$script:btnEnableFeatures = $script:btnInstallFeatures; $btnEnableFeatures = $btnInstallFeatures; $global:btnEnableFeatures = $btnInstallFeatures
$script:btnSfc = $script:btnRepairSfc; $btnSfc = $btnRepairSfc; $global:btnSfc = $btnRepairSfc
$script:btnDism = $script:btnRepairDism; $btnDism = $btnRepairDism; $global:btnDism = $btnRepairDism
$script:btnNetReset = $script:btnResetNetwork; $btnNetReset = $btnResetNetwork; $global:btnNetReset = $btnResetNetwork
$script:btnFixWU = $script:btnFixUpdates; $btnFixWU = $btnFixUpdates; $global:btnFixWU = $btnFixUpdates
$script:btnSearchWingetRepo = $script:btnWingetSearch; $btnSearchWingetRepo = $btnWingetSearch; $global:btnSearchWingetRepo = $btnWingetSearch
$script:outputBox = $script:logBox; $outputBox = $logBox; $global:outputBox = $logBox

# Brush references
$converter = New-Object System.Windows.Media.BrushConverter
$accentBrush  = $converter.ConvertFrom("#58A6FF")
$successBrush = $converter.ConvertFrom("#3FB950")
$dangerBrush  = $converter.ConvertFrom("#F85149")
$warningBrush = $converter.ConvertFrom("#D29922")
$textBrush    = $converter.ConvertFrom("#E6EDF3")
$textDimBrush = $converter.ConvertFrom("#8B949E")
$surfaceBrush = $converter.ConvertFrom("#161B22")
$borderBrush  = $converter.ConvertFrom("#30363D")
$hoverBrush   = $converter.ConvertFrom("#1F2937")

# =============================================================================
# 5. DATA STORES AND HELPER FUNCTIONS
# =============================================================================
$script:DefaultAppsJson = @'
{"Internet & Comms": [{"Name": "Brave", "Id": "Brave.Brave", "Desc": "Privacy focused browser", "Url": "https://brave.com"}, {"Name": "Chrome", "Id": "Google.Chrome", "Desc": "Standard web browser", "Url": "https://google.com/chrome"}, {"Name": "Firefox", "Id": "Mozilla.Firefox", "Desc": "Open source browser", "Url": "https://mozilla.org/firefox"}, {"Name": "LibreWolf", "Id": "LibreWolf.LibreWolf", "Desc": "Hardened Firefox Fork", "Url": "https://librewolf.net"}, {"Name": "Tor Browser", "Id": "TorProject.TorBrowser", "Desc": "Anonymous browsing", "Url": "https://torproject.org"}, {"Name": "Opera GX", "Id": "Opera.OperaGX", "Desc": "Gaming Browser", "Url": "https://opera.com/gx"}, {"Name": "Cloudflare Warp", "Id": "Cloudflare.Warp", "Desc": "VPN and DNS Utility", "Url": "https://1.1.1.1"}, {"Name": "Proton VPN", "Id": "Proton.ProtonVPN", "Desc": "Secure VPN Service", "Url": "https://protonvpn.com"}, {"Name": "WhatsApp", "Id": "9NKSQGP7F2NH", "Desc": "Messaging App (Microsoft Store)", "Url": "https://whatsapp.com"}, {"Name": "Telegram", "Id": "Telegram.TelegramDesktop", "Desc": "Fast & Secure Messaging", "Url": "https://desktop.telegram.org"}, {"Name": "Discord", "Id": "Discord.Discord", "Desc": "Voice & Text Chat", "Url": "https://discord.com"}, {"Name": "Signal", "Id": "OpenWhisperSystems.Signal", "Desc": "Encrypted Messenger", "Url": "https://signal.org"}, {"Name": "Zoom", "Id": "Zoom.Zoom", "Desc": "Video Conferencing", "Url": "https://zoom.us"}, {"Name": "LocalSend", "Id": "LocalSend.LocalSend", "Desc": "AirDrop alternative", "Url": "https://localsend.org"}, {"Name": "Free Download Mgr", "Id": "SoftDeluxe.FreeDownloadManager", "Desc": "Fast download manager", "Url": "https://freedownloadmanager.org"}, {"Name": "qBittorrent", "Id": "qBittorrent.qBittorrent", "Desc": "Open Source Torrent Client", "Url": "https://qbittorrent.org"}], "Development": [{"Name": "VS Code", "Id": "Microsoft.VisualStudioCode", "Desc": "Code Editor by Microsoft", "Url": "https://code.visualstudio.com"}, {"Name": "Visual Studio 2022", "Id": "Microsoft.VisualStudio.2022.Community", "Desc": "Full IDE (.NET/C++)", "Url": "https://visualstudio.microsoft.com"}, {"Name": "Cursor AI", "Id": "Anysphere.Cursor", "Desc": "AI-powered Code Editor", "Url": "https://cursor.com"}, {"Name": "Sublime Text", "Id": "SublimeHQ.SublimeText.4", "Desc": "Fast Text Editor", "Url": "https://sublimetext.com"}, {"Name": "Notepad++", "Id": "Notepad++.Notepad++", "Desc": "Lightweight Text Editor", "Url": "https://notepad-plus-plus.org"}, {"Name": "Git", "Id": "Git.Git", "Desc": "Version Control System", "Url": "https://git-scm.com"}, {"Name": "GitHub Desktop", "Id": "GitHub.GitHubDesktop", "Desc": "GUI for Git", "Url": "https://desktop.github.com"}, {"Name": "Node.js LTS", "Id": "OpenJS.NodeJS.LTS", "Desc": "JavaScript Runtime", "Url": "https://nodejs.org"}, {"Name": "Python 3.13", "Id": "Python.Python.3.13", "Desc": "Python Programming Language", "Url": "https://python.org"}, {"Name": "GoLang", "Id": "GoLang.Go", "Desc": "Go Programming Language", "Url": "https://go.dev"}, {"Name": "Rust", "Id": "Rustlang.Rustup", "Desc": "Rust Toolchain", "Url": "https://rust-lang.org"}, {"Name": "Docker Desktop", "Id": "Docker.DockerDesktop", "Desc": "Container Platform", "Url": "https://docker.com"}, {"Name": "PowerShell 7", "Id": "Microsoft.PowerShell", "Desc": "Cross-platform PowerShell", "Url": "https://github.com/PowerShell/PowerShell"}, {"Name": "Oh My Posh", "Id": "JanDeDobbeleer.OhMyPosh", "Desc": "Terminal Theme Engine", "Url": "https://ohmyposh.dev"}, {"Name": "JetBrainsMono Nerd Font", "Id": "DEVCOM.JetBrainsMonoNerdFont", "Desc": "Icons for Terminal", "Url": "https://nerdfonts.com"}, {"Name": "Postman", "Id": "Postman.Postman", "Desc": "API Testing Tool", "Url": "https://postman.com"}], "Office & Productivity": [{"Name": "LibreOffice", "Id": "TheDocumentFoundation.LibreOffice", "Desc": "Free Office Suite", "Url": "https://libreoffice.org"}, {"Name": "OnlyOffice", "Id": "ONLYOFFICE.DesktopEditors", "Desc": "Clean Office Alternative", "Url": "https://onlyoffice.com"}, {"Name": "Adobe Acrobat Reader", "Id": "Adobe.Acrobat.Reader.64-bit", "Desc": "PDF Viewer", "Url": "https://get.adobe.com/reader"}, {"Name": "SumatraPDF", "Id": "SumatraPDF.SumatraPDF", "Desc": "Fast PDF Reader", "Url": "https://sumatrapdfreader.org"}, {"Name": "Notion", "Id": "Notion.Notion", "Desc": "Notes & Workspace", "Url": "https://notion.so"}, {"Name": "Obsidian", "Id": "Obsidian.Obsidian", "Desc": "Knowledge Base (Markdown)", "Url": "https://obsidian.md"}, {"Name": "AnyDesk", "Id": "AnyDesk.AnyDesk", "Desc": "Remote Desktop", "Url": "https://anydesk.com"}, {"Name": "TeamViewer", "Id": "TeamViewer.TeamViewer", "Desc": "Remote Support", "Url": "https://teamviewer.com"}], "Creativity & Design": [{"Name": "GIMP", "Id": "GIMP.GIMP", "Desc": "Free Photoshop Alternative", "Url": "https://gimp.org"}, {"Name": "Paint.NET", "Id": "dotPDN.PaintDotNet", "Desc": "Simple Image Editor", "Url": "https://getpaint.net"}, {"Name": "Inkscape", "Id": "Inkscape.Inkscape", "Desc": "Vector Graphics Editor", "Url": "https://inkscape.org"}, {"Name": "Blender", "Id": "BlenderFoundation.Blender", "Desc": "3D Modeling Suite", "Url": "https://blender.org"}, {"Name": "Figma", "Id": "Figma.Figma", "Desc": "UI/UX Design Tool", "Url": "https://figma.com"}, {"Name": "Krita", "Id": "KDE.Krita", "Desc": "Digital Painting", "Url": "https://krita.org"}, {"Name": "HandBrake", "Id": "HandBrake.HandBrake", "Desc": "Video Transcoder", "Url": "https://handbrake.fr"}], "Utilities & Tools": [{"Name": "PowerToys", "Id": "Microsoft.PowerToys", "Desc": "Essential Windows Utilities", "Url": "https://github.com/microsoft/PowerToys"}, {"Name": "7-Zip", "Id": "7zip.7zip", "Desc": "Classic Archive tool", "Url": "https://7-zip.org"}, {"Name": "WinRAR", "Id": "RARLab.WinRAR", "Desc": "Popular Archive Manager", "Url": "https://rarlab.com"}, {"Name": "NanaZip", "Id": "M2Team.NanaZip", "Desc": "Modern 7-Zip for Win11", "Url": "https://github.com/M2Team/NanaZip"}, {"Name": "Rufus", "Id": "Rufus.Rufus", "Desc": "Bootable USB tool", "Url": "https://rufus.ie"}, {"Name": "Ventoy", "Id": "Ventoy.Ventoy", "Desc": "Multi-boot USB Creator", "Url": "https://ventoy.net"}, {"Name": "CPU-Z", "Id": "CPUID.CPU-Z", "Desc": "Hardware info", "Url": "https://cpuid.com/softwares/cpu-z.html"}, {"Name": "GPU-Z", "Id": "TechPowerUp.GPU-Z", "Desc": "Graphics Card Info", "Url": "https://techpowerup.com/gpuz"}, {"Name": "CrystalDiskMark", "Id": "CrystalDewWorld.CrystalDiskMark", "Desc": "Disk Benchmark", "Url": "https://crystalmark.info"}, {"Name": "Files App", "Id": "FilesCommunity.Files", "Desc": "Modern File Explorer Alternative", "Url": "https://files.community"}, {"Name": "ModernFlyouts", "Id": "ModernFlyouts.ModernFlyouts", "Desc": "Better Volume/Brightness UI", "Url": "https://github.com/ModernFlyouts-Community/ModernFlyouts"}, {"Name": "Ditto", "Id": "Ditto.Ditto", "Desc": "Advanced Clipboard Manager", "Url": "https://ditto-cp.sourceforge.io"}, {"Name": "Rainmeter", "Id": "Rainmeter.Rainmeter", "Desc": "Desktop Customization Tool", "Url": "https://rainmeter.net"}, {"Name": "Lively Wallpaper", "Id": "rocksdanister.LivelyWallpaper", "Desc": "Free & open source live wallpapers", "Url": "https://rocksdanister.github.io/lively"}, {"Name": "TeraCopy", "Id": "CodeSector.TeraCopy", "Desc": "Faster File Copying", "Url": "https://codesector.com/teracopy"}, {"Name": "Everything", "Id": "voidtools.Everything", "Desc": "Instant File Search", "Url": "https://voidtools.com"}, {"Name": "WizTree", "Id": "AntibodySoftware.WizTree", "Desc": "Disk Space Analyzer", "Url": "https://diskanalyzer.com"}, {"Name": "BleachBit", "Id": "BleachBit.BleachBit", "Desc": "System Cleaner", "Url": "https://bleachbit.org"}, {"Name": "Revo Uninstaller", "Id": "RevoUninstaller.RevoUninstaller", "Desc": "Deep Uninstall Tool", "Url": "https://revouninstaller.com"}, {"Name": "Bitwarden", "Id": "Bitwarden.Bitwarden", "Desc": "Password Manager", "Url": "https://bitwarden.com"}, {"Name": "KeePassXC", "Id": "KeePassXCTeam.KeePassXC", "Desc": "Offline Password Manager", "Url": "https://keepassxc.org"}, {"Name": "HWiNFO", "Id": "REALiX.HWiNFO", "Desc": "Hardware Monitoring", "Url": "https://hwinfo.com"}, {"Name": "Process Explorer", "Id": "Microsoft.Sysinternals.ProcessExplorer", "Desc": "Advanced Task Manager", "Url": "https://learn.microsoft.com/sysinternals/downloads/process-explorer"}, {"Name": "ShareX", "Id": "ShareX.ShareX", "Desc": "Screenshot and Recording Tool", "Url": "https://getsharex.com"}, {"Name": "UniGetUI", "Id": "Devolutions.UniGetUI", "Desc": "GUI for Winget", "Url": "https://github.com/marticliment/UniGetUI"}], "Multimedia & Gaming": [{"Name": "VLC", "Id": "VideoLAN.VLC", "Desc": "Universal Video Player", "Url": "https://videolan.org"}, {"Name": "PotPlayer", "Id": "Daum.PotPlayer", "Desc": "Advanced Video Player", "Url": "https://potplayer.daum.net"}, {"Name": "MPC-HC", "Id": "clsid2.mpc-hc", "Desc": "Lightweight Video Player", "Url": "https://github.com/clsid2/mpc-hc"}, {"Name": "OBS Studio", "Id": "OBSProject.OBSStudio", "Desc": "Streaming Software", "Url": "https://obsproject.com"}, {"Name": "Audacity", "Id": "Audacity.Audacity", "Desc": "Audio Editor", "Url": "https://audacityteam.org"}, {"Name": "Spotify", "Id": "Spotify.Spotify", "Desc": "Music Streaming", "Url": "https://spotify.com"}, {"Name": "iTunes", "Id": "Apple.iTunes", "Desc": "Apple Media Player", "Url": "https://apple.com/itunes"}, {"Name": "Steam", "Id": "Valve.Steam", "Desc": "Gaming Platform", "Url": "https://store.steampowered.com"}, {"Name": "Epic Games", "Id": "EpicGames.EpicGamesLauncher", "Desc": "Game Store", "Url": "https://epicgames.com"}, {"Name": "GOG Galaxy", "Id": "GOG.Galaxy", "Desc": "DRM-free Games", "Url": "https://gog.com/galaxy"}, {"Name": "Ubisoft Connect", "Id": "Ubisoft.Connect", "Desc": "Ubisoft Games", "Url": "https://ubisoftconnect.com"}, {"Name": "EA App", "Id": "ElectronicArts.EADesktop", "Desc": "EA Games Client", "Url": "https://ea.com"}, {"Name": "ImageGlass", "Id": "DuongDieuPhap.ImageGlass", "Desc": "Fast & Modern Photo Viewer", "Url": "https://imageglass.org"}, {"Name": "Shotcut", "Id": "Meltytech.Shotcut", "Desc": "Free open source video editor", "Url": "https://shotcut.org"}, {"Name": "SteelSeries GG", "Id": "SteelSeries.GG", "Desc": "Audio and Peripheral Driver", "Url": "https://steelseries.gg"}, {"Name": "Logitech G Hub", "Id": "Logitech.GHUB", "Desc": "Logitech Gear Driver", "Url": "https://logitechg.com"}, {"Name": "Razer Synapse 4", "Id": "RazerInc.RazerInstaller.Synapse4", "Desc": "Razer Gear Driver", "Url": "https://razer.com"}, {"Name": "EarTrumpet", "Id": "File-New-Project.EarTrumpet", "Desc": "Advanced Volume Control", "Url": "https://eartrumpet.app"}], "Runtimes (Essential)": [{"Name": ".NET 6 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.6", "Desc": "Required for many apps", "Url": "https://dotnet.microsoft.com"}, {"Name": ".NET 7 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.7", "Desc": "Required for newer apps", "Url": "https://dotnet.microsoft.com"}, {"Name": ".NET 8 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.8", "Desc": "Latest LTS Runtime", "Url": "https://dotnet.microsoft.com"}, {"Name": "VC++ Redist 2015-2022", "Id": "Microsoft.VCRedist.2015+.x64", "Desc": "Critical for games/apps", "Url": "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist"}, {"Name": "Java Runtime (JRE)", "Id": "Oracle.JavaRuntimeEnvironment", "Desc": "Java applications runner", "Url": "https://java.com"}, {"Name": "DirectX Web Runtime", "Id": "Microsoft.DirectX", "Desc": "Older Game Support", "Url": "https://microsoft.com/download/details.aspx?id=35"}]}
'@

$script:InstallList  = [System.Collections.ArrayList]::new()
$script:TweakList    = [System.Collections.ArrayList]::new()
$script:FeatureList  = [System.Collections.ArrayList]::new()
$script:DebloatList  = [System.Collections.ArrayList]::new()
$script:WingetList   = [System.Collections.ArrayList]::new()

function Write-AppLog {
    param([string]$Text, [string]$Type = "INFO")
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $script:logBox.AppendText("[$timestamp] [$Type] $Text`r`n")
    $script:logBox.ScrollToEnd()
}

function Switch-AppTab {
    param([string]$TabName)
    $vCur = Get-UIElement "viewCurated"; $vWin = Get-UIElement "viewWinget"
    $bCur = Get-UIElement "btnTabCurated"; $bWin = Get-UIElement "btnTabWinget"
    if ($TabName -eq "winget") {
        if ($vCur) { $vCur.Visibility = "Collapsed" }
        if ($vWin) { $vWin.Visibility = "Visible" }
        if ($bCur) { $bCur.Tag = $null }
        if ($bWin) { $bWin.Tag = "Active" }
    } else {
        if ($vCur) { $vCur.Visibility = "Visible" }
        if ($vWin) { $vWin.Visibility = "Collapsed" }
        if ($bCur) { $bCur.Tag = "Active" }
        if ($bWin) { $bWin.Tag = $null }
    }
}

function Show-Page {
    param([string]$PageName)
    $pInst = Get-UIElement "pageInstall"; if ($pInst) { $pInst.Visibility = "Collapsed" }
    $pTwk  = Get-UIElement "pageTweaks";  if ($pTwk)  { $pTwk.Visibility  = "Collapsed" }
    $pCfg  = Get-UIElement "pageConfig";  if ($pCfg)  { $pCfg.Visibility  = "Collapsed" }
    $pDeb  = Get-UIElement "pageDebloat"; if ($pDeb)  { $pDeb.Visibility  = "Collapsed" }
    $pUpd  = Get-UIElement "pageUpdates"; if ($pUpd)  { $pUpd.Visibility  = "Collapsed" }
    $pBak  = Get-UIElement "pageBackup";  if ($pBak)  { $pBak.Visibility  = "Collapsed" }
    $pWin  = Get-UIElement "pageWinget";  if ($pWin)  { $pWin.Visibility  = "Collapsed" }

    $bInst = Get-UIElement "btnMenuInstall"; if ($bInst) { $bInst.Tag = $null }
    $bTwk  = Get-UIElement "btnMenuTweaks";  if ($bTwk)  { $bTwk.Tag  = $null }
    $bCfg  = Get-UIElement "btnMenuConfig";  if ($bCfg)  { $bCfg.Tag  = $null }
    $bDeb  = Get-UIElement "btnMenuDebloat"; if ($bDeb)  { $bDeb.Tag  = $null }
    $bUpd  = Get-UIElement "btnMenuUpdates"; if ($bUpd)  { $bUpd.Tag  = $null }
    $bBak  = Get-UIElement "btnMenuBackup";  if ($bBak)  { $bBak.Tag  = $null }
    $bWin  = Get-UIElement "btnMenuWinget";  if ($bWin)  { $bWin.Tag  = $null }

    switch ($PageName) {
        "install" {
            if ($pInst) { $pInst.Visibility = "Visible" }
            if ($bInst) { $bInst.Tag = "Active" }
            Switch-AppTab "curated"
        }
        "winget"  {
            if ($pInst) { $pInst.Visibility = "Visible" }
            if ($bInst) { $bInst.Tag = "Active" }
            Switch-AppTab "winget"
        }
        "tweaks"  { if ($pTwk)  { $pTwk.Visibility  = "Visible" }; if ($bTwk)  { $bTwk.Tag  = "Active" } }
        "config"  { if ($pCfg)  { $pCfg.Visibility  = "Visible" }; if ($bCfg)  { $bCfg.Tag  = "Active" } }
        "debloat" { if ($pDeb)  { $pDeb.Visibility  = "Visible" }; if ($bDeb)  { $bDeb.Tag  = "Active" } }
        "updates" { if ($pUpd)  { $pUpd.Visibility  = "Visible" }; if ($bUpd)  { $bUpd.Tag  = "Active" } }
        "backup"  { if ($pBak)  { $pBak.Visibility  = "Visible" }; if ($bBak)  { $bBak.Tag  = "Active" } }
    }
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        [System.Windows.MessageBox]::Show(
            "Winget (Windows Package Manager) is not installed.`nPlease install it from the Microsoft Store or GitHub.",
            "Winget Not Found", "OK", "Warning")
        return $false
    }
}

# Hidden native-process runner shared by the UI thread and every background runspace.
# CreateNoWindow keeps console tools (winget, powercfg, code) from flashing a window in the
# -noConsole exe; stderr is drained asynchronously so a full stderr pipe cannot deadlock stdout.
$script:VdNativeLib = @'
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
'@
. ([scriptblock]::Create($script:VdNativeLib))

# Completion watcher for background runspaces. Deliberately no closure: the tick handler and
# OnComplete run in the script's scope, so script functions (Write-AppLog, Get-UIElement, ...)
# resolve both in the compiled .exe and when the .ps1 is started with -File.
function Watch-Runspace {
    param($PS, $Handle, $Runspace, [scriptblock]$OnComplete)
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds(400)
    $t.Tag = @{ PS = $PS; Handle = $Handle; Runspace = $Runspace; OnComplete = $OnComplete }
    $t.Add_Tick({
        $st = $this.Tag
        if (-not $st.Handle.IsCompleted) { return }
        $this.Stop()
        $result = $null
        try { $result = $st.PS.EndInvoke($st.Handle) } catch { Write-AppLog "Background task failed: $($_.Exception.Message)" "ERROR" }
        foreach ($e in @($st.PS.Streams.Error)) { Write-AppLog "Background task error: $($e.Exception.Message)" "ERROR" }
        $st.PS.Dispose()
        $st.Runspace.Close()
        if ($st.OnComplete) {
            try { & $st.OnComplete $result } catch { Write-AppLog "Completion handler failed: $($_.Exception.Message)" "ERROR" }
        }
    })
    $t.Start()
}

function Start-StreamingCommand {
    param([string]$FileName, [string]$Arguments)

    $targetLogBox = Get-UIElement "logBox"
    if ($targetLogBox) {
        $shown = if ($FileName -eq "powershell.exe" -and $Arguments -match '-EncodedCommand') { "powershell.exe (script)" } else { "$FileName $Arguments" }
        $targetLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [CMD] $shown`r`n")
        $targetLogBox.ScrollToEnd()
    }

    $targetWin = if ($window) { $window } elseif ($script:window) { $script:window } else { $global:window }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $targetWin
        LogBox = $targetLogBox
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($FN, $Args, $SH, $Lib)
        . ([scriptblock]::Create($Lib))
        function Push-Line([string]$text) {
            if ($SH.LogBox -and $SH.Window) {
                try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText("$text`r`n"); $SH.LogBox.ScrollToEnd() }) } catch {}
            }
        }
        $exitCode = $null
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $FN
            $psi.Arguments = $Args
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            # winget writes UTF-8; classic tools use the OEM code page (sfc emits UTF-16, NULs stripped below)
            $enc = Get-VdProcessEncoding $(if ($FN -match '^winget(\.exe)?$') { 'UTF8' } else { '' })
            $psi.StandardOutputEncoding = $enc
            $psi.StandardErrorEncoding = $enc

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null
            $errTask = $proc.StandardError.ReadToEndAsync()

            while ($null -ne ($line = $proc.StandardOutput.ReadLine())) {
                $line = ($line -replace "`0", '').TrimEnd()
                # drop empty lines and winget/dism progress animation
                if ($line.Trim() -eq '' -or $line.Trim() -match '^[-\\|/]$' -or $line -match '[▀-▟]') { continue }
                Push-Line $line
            }
            $proc.WaitForExit()
            $errOut = ($errTask.Result -replace "`0", '').Trim()
            if ($errOut) { Push-Line $errOut }
            $exitCode = $proc.ExitCode
        } catch {
            Push-Line "ERROR: $($_.Exception.Message)"
        }
        $status = if ($null -eq $exitCode) { "FAILED TO START" } elseif ($exitCode -eq 0) { "COMPLETED (exit code 0)" } else { "FINISHED WITH ERRORS (exit code $exitCode)" }
        Push-Line "`r`n--- PROCESS $status ---"
    })
    [void]$ps.AddParameter("FN", $FileName)
    [void]$ps.AddParameter("Args", $Arguments)
    [void]$ps.AddParameter("SH", $syncHash)
    [void]$ps.AddParameter("Lib", $script:VdNativeLib)

    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
    }
}

function Start-PSStreamingCommand {
    param([string]$PSScript)
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($PSScript)
    $encoded = [Convert]::ToBase64String($bytes)
    Start-StreamingCommand "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
}

# =============================================================================
# 6. NAVIGATION
# =============================================================================
if ($btnMenuInstall) { $btnMenuInstall.Add_Click({ Show-Page "install" }) }
if ($btnMenuWinget) { $btnMenuWinget.Add_Click({ Show-Page "winget" }) }
if ($btnMenuTweaks) { $btnMenuTweaks.Add_Click({ Show-Page "tweaks" }) }
if ($btnMenuConfig) { $btnMenuConfig.Add_Click({ Show-Page "config" }) }
if ($btnMenuDebloat) { $btnMenuDebloat.Add_Click({ Show-Page "debloat" }) }
if ($btnMenuUpdates) { $btnMenuUpdates.Add_Click({ Show-Page "updates" }) }
if ($btnMenuBackup) { $btnMenuBackup.Add_Click({ Show-Page "backup" }) }
if ($btnExit) { $btnExit.Add_Click({ if ($window) { $window.Close() } }) }
if ($btnClearLog -and $logBox) { $btnClearLog.Add_Click({ $logBox.Clear() }) }

$btnTabCurated = Get-UIElement "btnTabCurated"
$btnTabWinget  = Get-UIElement "btnTabWinget"
if ($btnTabCurated) { $btnTabCurated.Add_Click({ Switch-AppTab "curated" }) }
if ($btnTabWinget)  { $btnTabWinget.Add_Click({ Switch-AppTab "winget" }) }

# =============================================================================
# 7. APP CENTER
# =============================================================================
try {
    $jsonPath = Join-Path $ScriptPath "apps.json"
    if (-not (Test-Path $jsonPath)) {
        $parentDir = Split-Path $ScriptPath -Parent
        if ($parentDir) { $jsonPath = Join-Path $parentDir "apps.json" }
    }
    $jsonContent = $null
    if (Test-Path $jsonPath) {
        try {
            $jsonContent = Get-Content -Path $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-AppLog "apps.json on disk is corrupted. Falling back to embedded catalog." "WARN"
        }
    }
    if (-not $jsonContent) {
        Write-AppLog "apps.json not found on disk. Initializing resilient embedded catalog (96 apps)..." "INFO"
        $jsonContent = $script:DefaultAppsJson | ConvertFrom-Json
        try {
            $targetSave = Join-Path $ScriptPath "apps.json"
            Set-Content -Path $targetSave -Value $script:DefaultAppsJson -Encoding UTF8 -Force -ErrorAction SilentlyContinue
            Write-AppLog "Restored default apps.json to: $targetSave" "SUCCESS"
        } catch {}
    }
    if ($jsonContent) {
        $script:CatalogCategories = @($jsonContent.PSObject.Properties.Name)
        $script:CategorySections = [ordered]@{}
        
        foreach ($categoryName in $jsonContent.PSObject.Properties.Name) {
            # Category header
            $catHeader = New-Object System.Windows.Controls.TextBlock
            $catHeader.Text = $categoryName
            $catHeader.FontSize = 16
            $catHeader.FontWeight = "Bold"
            $catHeader.Foreground = $accentBrush
            $catHeader.Margin = [System.Windows.Thickness]::new(5, 20, 0, 8)
            [void]$appContainer.Children.Add($catHeader)
            
            $wrapPanel = New-Object System.Windows.Controls.WrapPanel
            $apps = $jsonContent.$categoryName
            
            foreach ($app in $apps) {
                $card = New-Object System.Windows.Controls.Border
                $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
                $card.Background = $surfaceBrush
                $card.BorderBrush = $borderBrush
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $card.Margin = [System.Windows.Thickness]::new(4)
                $card.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
                $card.Width = 220
                $card.Cursor = [System.Windows.Input.Cursors]::Hand
                
                # CheckBox with name + description + URL content
                $cb = New-Object System.Windows.Controls.CheckBox
                $cb.Foreground = $textBrush
                $cb.FontSize = 13
                $cb.VerticalContentAlignment = "Top"
                
                $cbContent = New-Object System.Windows.Controls.StackPanel
                $nameText = New-Object System.Windows.Controls.TextBlock
                $nameText.Text = $app.Name
                $nameText.FontWeight = "SemiBold"
                $nameText.FontSize = 13
                
                $descText = New-Object System.Windows.Controls.TextBlock
                $descText.Text = if ($app.Desc) { $app.Desc } else { $app.Id }
                $descText.Foreground = $textDimBrush
                $descText.FontSize = 11
                $descText.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
                $descText.TextTrimming = "CharacterEllipsis"
                
                [void]$cbContent.Children.Add($nameText)
                [void]$cbContent.Children.Add($descText)
                
                # Web / GitHub Link Button
                if ($app.Url) {
                    $urlBtn = New-Object System.Windows.Controls.Button
                    $urlBtn.Content = "🌐 Web / GitHub"
                    $urlBtn.Foreground = $accentBrush
                    $urlBtn.Background = [System.Windows.Media.Brushes]::Transparent
                    $urlBtn.BorderThickness = [System.Windows.Thickness]::new(0)
                    $urlBtn.FontSize = 10
                    $urlBtn.Cursor = [System.Windows.Input.Cursors]::Hand
                    $urlBtn.HorizontalAlignment = "Left"
                    $urlBtn.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
                    $urlBtn.Tag = "$($app.Url)"
                    $urlBtn.Add_Click({
                        # Catalog entries can be user-added: only ever open web links, never local paths/programs
                        $u = "$($this.Tag)"
                        if ($u -match '^https?://[^\s"]+$') { try { Start-Process -FilePath $u } catch {} }
                        else { Write-AppLog "Blocked non-web link: $u" "WARN" }
                    })
                    [void]$cbContent.Children.Add($urlBtn)
                }

                $cb.Content = $cbContent
                $card.Child = $cb
                
                # Hover effect on card
                $card.Add_MouseEnter({ $this.Background = $hoverBrush })
                $card.Add_MouseLeave({ $this.Background = $surfaceBrush })
                
                # Selection border highlight (the checkbox is the card's direct child)
                $cb.Add_Checked({ $this.Parent.BorderBrush = $accentBrush })
                $cb.Add_Unchecked({ $this.Parent.BorderBrush = $borderBrush })
                
                [void]$wrapPanel.Children.Add($card)
                [void]$script:InstallList.Add(@{Check=$cb; Id=$app.Id; Name=$app.Name; Card=$card; WrapPanel=$wrapPanel; Category=$categoryName})
            }
            [void]$appContainer.Children.Add($wrapPanel)
            $script:CategorySections[$categoryName] = @{ Header = $catHeader; Panel = $wrapPanel }
        }
    } else {
        Write-AppLog "apps.json not found at: $jsonPath" "ERROR"
    }
} catch {
    Write-AppLog "Failed to load apps.json: $($_.Exception.Message)" "ERROR"
}

# Select All / Deselect All for App Center
if ($btnAppSelectAll) { $btnAppSelectAll.Add_Click({ foreach ($item in $script:InstallList) { if ($item.Card.Visibility -ne "Collapsed") { $item.Check.IsChecked = $true } } }) }
if ($btnAppDeselectAll) { $btnAppDeselectAll.Add_Click({ foreach ($item in $script:InstallList) { $item.Check.IsChecked = $false } }) }

# Search + category filter: a card is shown when it matches both; empty sections are hidden
$script:ActiveCategory = "All"
function Update-AppFilter {
    $query = if ($searchBox) { $searchBox.Text.Trim().ToLower() } else { "" }
    foreach ($item in $script:InstallList) {
        $inCategory = ($script:ActiveCategory -eq "All") -or ($item.Category -eq $script:ActiveCategory)
        $hit = ($query.Length -eq 0) -or $item.Name.ToLower().Contains($query) -or "$($item.Id)".ToLower().Contains($query)
        $item.Card.Visibility = if ($inCategory -and $hit) { "Visible" } else { "Collapsed" }
    }
    if ($script:CategorySections) {
        foreach ($name in $script:CategorySections.Keys) {
            $sec = $script:CategorySections[$name]
            $any = @($script:InstallList | Where-Object { $_.Category -eq $name -and $_.Card.Visibility -eq "Visible" }).Count -gt 0
            $vis = if ($any) { "Visible" } else { "Collapsed" }
            $sec.Header.Visibility = $vis
            $sec.Panel.Visibility = $vis
        }
    }
}

$searchBox.Add_TextChanged({
    $searchPlaceholder.Visibility = if ($searchBox.Text.Length -gt 0) { "Collapsed" } else { "Visible" }
    Update-AppFilter
})

$chipPanel = Get-UIElement "filterChipsPanel"
if ($chipPanel -and $script:CategorySections) {
    $chipStyle = try { $window.FindResource("SubTabBtn") } catch { $null }
    foreach ($chipName in @("All") + @($script:CategorySections.Keys)) {
        $chip = New-Object System.Windows.Controls.Button
        $chip.Content = if ($chipName -eq "All") { "All ($($script:InstallList.Count))" } else { "$chipName ($(@($script:InstallList | Where-Object { $_.Category -eq $chipName }).Count))" }
        if ($chipStyle) { $chip.Style = $chipStyle }
        # Tag drives the "Active" highlight in SubTabBtn; the category name rides in the Uid
        $chip.Uid = $chipName
        if ($chipName -eq "All") { $chip.Tag = "Active" }
        $chip.Add_Click({
            $script:ActiveCategory = $this.Uid
            foreach ($c in (Get-UIElement "filterChipsPanel").Children) { $c.Tag = if ($c.Uid -eq $script:ActiveCategory) { "Active" } else { $null } }
            Update-AppFilter
        })
        [void]$chipPanel.Children.Add($chip)
    }
}

# INSTALL (Async with Runspace)
if ($btnInstall) {
    $btnInstall.Add_Click({
        if (-not (Test-WingetAvailable)) { return }

        $selected = @($script:InstallList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No applications selected.", "Info", "OK", "Information")
            return
        }

        $bInst = Get-UIElement "btnInstall"
        $bUninst = Get-UIElement "btnUninstall"
        $pPanel = Get-UIElement "progressPanel"
        $pBar = Get-UIElement "progressBar"
        $pText = Get-UIElement "progressText"
        $lBox = Get-UIElement "logBox"
        $targetWin = if ($window) { $window } elseif ($script:window) { $script:window } else { $global:window }

        if ($bInst) { $bInst.IsEnabled = $false }
        if ($bUninst) { $bUninst.IsEnabled = $false }
        if ($pPanel) { $pPanel.Visibility = "Visible" }
        if ($pBar) { $pBar.Value = 0 }

        $appsData = @()
        foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }

        $syncHash = [hashtable]::Synchronized(@{
            Window = $targetWin
            ProgressBar = $pBar
            ProgressText = $pText
            LogBox = $lBox
            Total = $appsData.Count
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Apps, $SH, $Lib)
            . ([scriptblock]::Create($Lib))
            $current = 0
            foreach ($app in $Apps) {
                $current++
                $n = $app.Name; $id = $app.Id; $t = $SH.Total
                try { $SH.Window.Dispatcher.Invoke([action]{
                    if ($SH.ProgressText) { $SH.ProgressText.Text = "Installing: $n ($current / $t)" }
                    if ($SH.ProgressBar) { $SH.ProgressBar.Value = [math]::Round(($current / $t) * 100) }
                }) } catch {}

                try {
                    $r = Invoke-VdNative 'winget.exe' @('install', '--id', $id, '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') 'UTF8'
                    $code = $r.ExitCode
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        if ($SH.LogBox) {
                            if ($code -eq 0) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Installed: $n`r`n") }
                            elseif ($code -eq -1978335189) { $SH.LogBox.AppendText("[$ts] [INFO] Already installed: $n`r`n") }
                            else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed: $n (Code: $code)`r`n") }
                            $SH.LogBox.ScrollToEnd()
                        }
                    }) } catch {}
                } catch {
                    $msg = $_.Exception.Message
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        if ($SH.LogBox) {
                            $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n")
                            $SH.LogBox.ScrollToEnd()
                        }
                    }) } catch {}
                }
            }
            try { $SH.Window.Dispatcher.Invoke([action]{
                if ($SH.ProgressText) { $SH.ProgressText.Text = "All installations completed!" }
                if ($SH.ProgressBar) { $SH.ProgressBar.Value = 100 }
                if ($SH.LogBox) {
                    $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [INFO] Installation cycle complete.`r`n")
                    $SH.LogBox.ScrollToEnd()
                }
            }) } catch {}
        })
        [void]$ps.AddParameter("Apps", $appsData)
        [void]$ps.AddParameter("SH", $syncHash)
        [void]$ps.AddParameter("Lib", $script:VdNativeLib)
        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            $curInst = Get-UIElement "btnInstall"
            $curUninst = Get-UIElement "btnUninstall"
            if ($curInst) { $curInst.IsEnabled = $true }
            if ($curUninst) { $curUninst.IsEnabled = $true }
        }
        Write-AppLog "Installation started for $($appsData.Count) apps..." "ACTION"
    })
}

# UNINSTALL (Async with Runspace)
if ($btnUninstall) {
    $btnUninstall.Add_Click({
        if (-not (Test-WingetAvailable)) { return }

        $selected = @($script:InstallList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No applications selected.", "Info", "OK", "Information")
            return
        }

        $result = [System.Windows.MessageBox]::Show("Selected apps will be REMOVED. Continue?", "Confirm Uninstall", "YesNo", "Warning")
        if ($result -ne "Yes") { return }

        $bInst = Get-UIElement "btnInstall"
        $bUninst = Get-UIElement "btnUninstall"
        $pPanel = Get-UIElement "progressPanel"
        $pBar = Get-UIElement "progressBar"
        $pText = Get-UIElement "progressText"
        $lBox = Get-UIElement "logBox"
        $targetWin = if ($window) { $window } elseif ($script:window) { $script:window } else { $global:window }

        if ($bInst) { $bInst.IsEnabled = $false }
        if ($bUninst) { $bUninst.IsEnabled = $false }
        if ($pPanel) { $pPanel.Visibility = "Visible" }
        if ($pBar) { $pBar.Value = 0 }

        $appsData = @()
        foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }

        $syncHash = [hashtable]::Synchronized(@{
            Window = $targetWin
            ProgressBar = $pBar
            ProgressText = $pText
            LogBox = $lBox
            Total = $appsData.Count
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Apps, $SH, $Lib)
            . ([scriptblock]::Create($Lib))
            $current = 0
            foreach ($app in $Apps) {
                $current++
                $n = $app.Name; $id = $app.Id; $t = $SH.Total
                try { $SH.Window.Dispatcher.Invoke([action]{
                    if ($SH.ProgressText) { $SH.ProgressText.Text = "Uninstalling: $n ($current / $t)" }
                    if ($SH.ProgressBar) { $SH.ProgressBar.Value = [math]::Round(($current / $t) * 100) }
                }) } catch {}

                try {
                    $r = Invoke-VdNative 'winget.exe' @('uninstall', '--id', $id, '-e', '--silent', '--accept-source-agreements', '--disable-interactivity', '--force') 'UTF8'
                    $code = $r.ExitCode
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        if ($SH.LogBox) {
                            if ($code -eq 0) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Uninstalled: $n`r`n") }
                            else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed to uninstall: $n (Code: $code)`r`n") }
                            $SH.LogBox.ScrollToEnd()
                        }
                    }) } catch {}
                } catch {
                    $msg = $_.Exception.Message
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        if ($SH.LogBox) {
                            $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n")
                            $SH.LogBox.ScrollToEnd()
                        }
                    }) } catch {}
                }
            }
            try { $SH.Window.Dispatcher.Invoke([action]{
                if ($SH.ProgressText) { $SH.ProgressText.Text = "All uninstallations completed!" }
                if ($SH.ProgressBar) { $SH.ProgressBar.Value = 100 }
                if ($SH.LogBox) {
                    $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [INFO] Uninstallation cycle complete.`r`n")
                    $SH.LogBox.ScrollToEnd()
                }
            }) } catch {}
        })
        [void]$ps.AddParameter("Apps", $appsData)
        [void]$ps.AddParameter("SH", $syncHash)
        [void]$ps.AddParameter("Lib", $script:VdNativeLib)
        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            $curInst = Get-UIElement "btnInstall"
            $curUninst = Get-UIElement "btnUninstall"
            if ($curInst) { $curInst.IsEnabled = $true }
            if ($curUninst) { $curUninst.IsEnabled = $true }
        }
        Write-AppLog "Uninstallation started for $($appsData.Count) apps..." "WARN"
    })
}

# =============================================================================
# 8. WINGET MANAGER MODULE
# =============================================================================
function Set-WingetBusy([string]$Message) {
    $panel = Get-UIElement "wingetProgressPanel"
    $txt = Get-UIElement "wingetProgressText"
    if ($Message) {
        if ($txt) { $txt.Text = $Message }
        if ($panel) { $panel.Visibility = "Visible" }
    } elseif ($panel) { $panel.Visibility = "Collapsed" }
}

function Render-WingetCards {
    param([array]$Items)
    if (-not $wingetItemsContainer) { return }
    $wingetItemsContainer.Children.Clear()
    [void]$script:WingetList.Clear()

    $wrapPanel = New-Object System.Windows.Controls.WrapPanel

    foreach ($item in $Items) {
        $card = New-Object System.Windows.Controls.Border
        $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $card.Background = $surfaceBrush
        $card.BorderBrush = $borderBrush
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.Margin = [System.Windows.Thickness]::new(4)
        $card.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
        $card.Width = 280
        $card.Cursor = [System.Windows.Input.Cursors]::Hand

        $cbContent = New-Object System.Windows.Controls.StackPanel
        
        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $item.Name
        $nameText.FontWeight = "SemiBold"
        $nameText.FontSize = 13
        $nameText.TextTrimming = "CharacterEllipsis"

        $idText = New-Object System.Windows.Controls.TextBlock
        $idText.Text = "ID: $($item.Id)"
        $idText.Foreground = $accentBrush
        $idText.FontSize = 11
        $idText.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
        $idText.TextTrimming = "CharacterEllipsis"

        $verText = New-Object System.Windows.Controls.TextBlock
        $verText.Text = "Version: $(if ($item.Version) { $item.Version } else { 'N/A' }) | Source: $(if ($item.Source) { $item.Source } else { 'Local' })"
        $verText.Foreground = $textDimBrush
        $verText.FontSize = 10
        $verText.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)

        [void]$cbContent.Children.Add($nameText)
        [void]$cbContent.Children.Add($idText)
        [void]$cbContent.Children.Add($verText)

        # Quick Action Buttons per card
        $btnGrid = New-Object System.Windows.Controls.Grid
        $btnGrid.Margin = [System.Windows.Thickness]::new(0, 8, 0, 2)
        $cDef1 = New-Object System.Windows.Controls.ColumnDefinition
        $cDef1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $cDefSep = New-Object System.Windows.Controls.ColumnDefinition
        $cDefSep.Width = New-Object System.Windows.GridLength(6, [System.Windows.GridUnitType]::Pixel)
        $cDef2 = New-Object System.Windows.Controls.ColumnDefinition
        $cDef2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        [void]$btnGrid.ColumnDefinitions.Add($cDef1)
        [void]$btnGrid.ColumnDefinitions.Add($cDefSep)
        [void]$btnGrid.ColumnDefinitions.Add($cDef2)

        $roundedStyle = try { $window.FindResource("RoundedBtn") } catch { $null }

        $instCardBtn = New-Object System.Windows.Controls.Button
        $instCardBtn.Content = "Install"
        $instCardBtn.Background = $successBrush
        $instCardBtn.Foreground = [System.Windows.Media.Brushes]::White
        $instCardBtn.FontSize = 11
        $instCardBtn.Padding = [System.Windows.Thickness]::new(0, 5, 0, 5)
        $instCardBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        if ($roundedStyle) { $instCardBtn.Style = $roundedStyle }
        [System.Windows.Controls.Grid]::SetColumn($instCardBtn, 0)

        $uninstCardBtn = New-Object System.Windows.Controls.Button
        $uninstCardBtn.Content = "Uninstall"
        $uninstCardBtn.Background = $dangerBrush
        $uninstCardBtn.Foreground = [System.Windows.Media.Brushes]::White
        $uninstCardBtn.FontSize = 11
        $uninstCardBtn.Padding = [System.Windows.Thickness]::new(0, 5, 0, 5)
        $uninstCardBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        if ($roundedStyle) { $uninstCardBtn.Style = $roundedStyle }
        [System.Windows.Controls.Grid]::SetColumn($uninstCardBtn, 2)

        [void]$btnGrid.Children.Add($instCardBtn)
        [void]$btnGrid.Children.Add($uninstCardBtn)
        [void]$cbContent.Children.Add($btnGrid)

        $instCardBtn.Tag = @{ Id = "$($item.Id)"; Name = "$($item.Name)" }
        $uninstCardBtn.Tag = $instCardBtn.Tag

        $instCardBtn.Add_Click({
            $pkg = $this.Tag
            if (-not (Test-WingetAvailable)) { return }
            if ($pkg.Id -match '"' -or [string]::IsNullOrWhiteSpace($pkg.Id)) { Write-AppLog "Refusing unexpected package id: $($pkg.Id)" "ERROR"; return }
            Write-AppLog "Installing package: $($pkg.Name) ($($pkg.Id))..." "ACTION"
            Start-StreamingCommand "winget" "install --id `"$($pkg.Id)`" -e --silent --accept-package-agreements --accept-source-agreements"
        })

        $uninstCardBtn.Add_Click({
            $pkg = $this.Tag
            if (-not (Test-WingetAvailable)) { return }
            if ($pkg.Id -match '"' -or [string]::IsNullOrWhiteSpace($pkg.Id)) { Write-AppLog "Refusing unexpected package id: $($pkg.Id)" "ERROR"; return }
            $res = [System.Windows.MessageBox]::Show("Uninstall $($pkg.Name)?`n($($pkg.Id))", "Confirm Uninstall", "YesNo", "Warning")
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
            Write-AppLog "Uninstalling package: $($pkg.Name) ($($pkg.Id))..." "WARN"
            Start-StreamingCommand "winget" "uninstall --id `"$($pkg.Id)`" -e --silent --accept-source-agreements --force"
        })

        $card.Child = $cbContent
        $card.Add_MouseEnter({ $this.Background = $hoverBrush; $this.BorderBrush = $accentBrush })
        $card.Add_MouseLeave({ $this.Background = $surfaceBrush; $this.BorderBrush = $borderBrush })

        [void]$wrapPanel.Children.Add($card)
        [void]$script:WingetList.Add(@{Id=$item.Id; Name=$item.Name; Card=$card})
    }
    [void]$wingetItemsContainer.Children.Add($wrapPanel)
}

# Search Installed Filter
if ($wingetSearchBox) {
    $wingetSearchBox.Add_TextChanged({
        $query = $wingetSearchBox.Text.ToLower()
        if ($wingetSearchPlaceholder) {
            $wingetSearchPlaceholder.Visibility = if ($query.Length -gt 0) { "Collapsed" } else { "Visible" }
        }
        foreach ($item in $script:WingetList) {
            $visible = ($query.Length -eq 0) -or ($item.Name.ToLower().Contains($query)) -or ($item.Id.ToLower().Contains($query))
            $item.Card.Visibility = if ($visible) { "Visible" } else { "Collapsed" }
        }
    })
}

# Scan Installed Packages
if ($btnScanWingetInstalled) {
    $btnScanWingetInstalled.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        Write-AppLog "Scanning installed packages via Winget..." "ACTION"
        Set-WingetBusy "Scanning installed packages..."
        
        $syncHash = [hashtable]::Synchronized(@{
            Window = $window
            LogBox = $logBox
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($SH, $Lib)
            . ([scriptblock]::Create($Lib))
            $r = Invoke-VdNative 'winget.exe' @('list', '--accept-source-agreements', '--disable-interactivity') 'UTF8'
            return @(ConvertFrom-VdWingetTable $r.Output)
        })
        [void]$ps.AddParameter("SH", $syncHash)
        [void]$ps.AddParameter("Lib", $script:VdNativeLib)
        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            $results = @($result)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Set-WingetBusy $null
            Render-WingetCards $results
            Write-AppLog "Winget Scan complete: $($results.Count) packages found." "SUCCESS"
        }
    })
}

# Search Online Repository
if ($btnSearchWingetRepo) {
    $btnSearchWingetRepo.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $query = $wingetSearchBox.Text.Trim()
        if ($query.Length -eq 0) {
            [System.Windows.MessageBox]::Show("Please enter a keyword to search online repo.", "Info", "OK", "Information")
            return
        }

        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        Write-AppLog "Searching online Winget repository for: $query..." "ACTION"
        Set-WingetBusy "Searching the Winget repository for '$query'..."

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Q, $Lib)
            . ([scriptblock]::Create($Lib))
            $r = Invoke-VdNative 'winget.exe' @('search', $Q, '--accept-source-agreements', '--disable-interactivity') 'UTF8'
            return @(ConvertFrom-VdWingetTable $r.Output)
        })
        [void]$ps.AddParameter("Q", $query)
        [void]$ps.AddParameter("Lib", $script:VdNativeLib)
        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            $results = @($result)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Set-WingetBusy $null
            Render-WingetCards $results
            Write-AppLog "Winget Online Search complete: $($results.Count) matching packages found." "SUCCESS"
        }
    })
}

# Upgrade All Installed Winget Packages
if ($btnWingetUpgradeAll) {
    $btnWingetUpgradeAll.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $res = [System.Windows.MessageBox]::Show("Upgrade all installed Winget applications to their latest available versions?", "Upgrade All Apps", "YesNo", "Question")
        if ($res -ne "Yes") { return }
        Write-AppLog "Starting bulk upgrade of all installed packages via Winget..." "ACTION"
        Start-StreamingCommand "winget" "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
    })
}

# =============================================================================
# 9. SYSTEM TWEAKS
# =============================================================================
function Add-TweakGroup {
    param([string]$Title, [array]$Tweaks, [string]$Color = "#58A6FF")
    
    $group = New-Object System.Windows.Controls.Border
    $group.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $group.Background = $surfaceBrush
    $group.BorderBrush = $borderBrush
    $group.BorderThickness = [System.Windows.Thickness]::new(1)
    $group.Padding = [System.Windows.Thickness]::new(18, 14, 18, 16)
    $group.Margin = [System.Windows.Thickness]::new(5)
    $group.MinWidth = 320
    $group.MaxWidth = 420
    
    $innerStack = New-Object System.Windows.Controls.StackPanel
    
    $headerText = New-Object System.Windows.Controls.TextBlock
    $headerText.Text = $Title
    $headerText.FontSize = 16
    $headerText.FontWeight = "Bold"
    $headerText.Foreground = $converter.ConvertFrom($Color)
    $headerText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
    [void]$innerStack.Children.Add($headerText)
    
    $sep = New-Object System.Windows.Controls.Border
    $sep.Height = 1
    $sep.Background = $borderBrush
    $sep.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    [void]$innerStack.Children.Add($sep)
    
    foreach ($t in $Tweaks) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $t.Name
        $cb.Foreground = $textBrush
        $cb.FontSize = 13
        $cb.Margin = [System.Windows.Thickness]::new(0, 5, 0, 5)
        $cb.Cursor = [System.Windows.Input.Cursors]::Hand
        [void]$innerStack.Children.Add($cb)
        [void]$script:TweakList.Add(@{Check=$cb; Do=$t.Do; Undo=$t.Undo; Name=$t.Name; Tag=$t.Tag; State=$t.State})
    }
    
    $group.Child = $innerStack
        $targetTweakBox = if ($script:tweakContainer) { $script:tweakContainer } elseif ($tweaksContainer) { $tweaksContainer } else { $script:tweaksContainer }
    if ($targetTweakBox) { [void]$targetTweakBox.Children.Add($group) }
}

# Tweak state library: loaded into the apply/revert runspaces. Before a tweak runs for the
# first time, every value it touches is snapshotted to HKCU:\Software\VDOWNS\TweakState so
# "Revert" can put back exactly what was there (including "value did not exist").
$script:TweakStateLib = @'
$VdStateRoot = 'HKCU:\Software\VDOWNS\TweakState'
$VdUltimatePlanGuid = 'c4e0702f-b217-4220-b268-5cbd645bac82'

function Get-VdRegSnapshot([string]$Path, [string]$Name) {
    $snap = @{ Path = $Path; Name = $Name; Exists = $false }
    if (Test-Path -LiteralPath $Path) {
        $key = Get-Item -LiteralPath $Path
        if ($key.GetValueNames() -contains $Name) {
            $snap.Exists = $true
            $snap.Kind = $key.GetValueKind($Name).ToString()
            $val = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
            if ($val -is [byte[]]) { $snap.Value = [Convert]::ToBase64String($val); $snap.IsBase64 = $true } else { $snap.Value = $val }
        }
    }
    $snap
}

function Restore-VdRegSnapshot($Snap) {
    if (-not $Snap) { return }
    if ($Snap.Exists) {
        if (-not (Test-Path -LiteralPath $Snap.Path)) { New-Item -Path $Snap.Path -Force | Out-Null }
        $v = $Snap.Value
        if ($Snap.IsBase64) { $v = [Convert]::FromBase64String($v) }
        elseif ($Snap.Kind -eq 'MultiString') { $v = [string[]]@($v) }
        New-ItemProperty -LiteralPath $Snap.Path -Name $Snap.Name -Value $v -PropertyType $Snap.Kind -Force -ErrorAction Stop | Out-Null
    } elseif (Test-Path -LiteralPath $Snap.Path) {
        Remove-ItemProperty -LiteralPath $Snap.Path -Name $Snap.Name -Force -ErrorAction SilentlyContinue
    }
}

function Save-VdTweakState([string]$TweakName, $Spec) {
    if (-not $Spec) { return }
    if (-not (Test-Path $VdStateRoot)) { New-Item -Path $VdStateRoot -Force | Out-Null }
    # Keep the very first snapshot: re-applying must not overwrite the true original
    if ((Get-Item -Path $VdStateRoot).GetValueNames() -contains $TweakName) { return }
    $items = foreach ($e in $Spec) {
        if ($e.Reg) {
            @{ Type = 'Reg'; Snap = (Get-VdRegSnapshot $e.Reg $e.Name) }
        } elseif ($e.Svc) {
            $svcKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($e.Svc)"
            $svc = Get-Service -Name $e.Svc -ErrorAction SilentlyContinue
            @{ Type = 'Svc'; Name = $e.Svc; WasRunning = [bool]($svc -and $svc.Status -eq 'Running')
               Start = (Get-VdRegSnapshot $svcKey 'Start'); Delayed = (Get-VdRegSnapshot $svcKey 'DelayedAutostart') }
        } elseif ($e.Key) {
            @{ Type = 'Key'; Path = $e.Key; Existed = [bool](Test-Path -LiteralPath $e.Key) }
        } elseif ($e.Hibernate) {
            $h = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name HibernateEnabled -ErrorAction SilentlyContinue).HibernateEnabled
            @{ Type = 'Hibernate'; Enabled = ($h -eq 1) }
        } elseif ($e.PowerPlan) {
            $m = [regex]::Match((powercfg /getactivescheme | Out-String), '[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')
            @{ Type = 'PowerPlan'; ActiveGuid = $m.Value }
        }
    }
    $json = ConvertTo-Json -InputObject @($items) -Depth 6 -Compress
    New-ItemProperty -Path $VdStateRoot -Name $TweakName -Value $json -PropertyType String -Force -ErrorAction Stop | Out-Null
}

function Restore-VdTweakState([string]$TweakName) {
    if (-not (Test-Path $VdStateRoot)) { return $false }
    $json = (Get-Item -Path $VdStateRoot).GetValue($TweakName)
    if (-not $json) { return $false }
    foreach ($it in ($json | ConvertFrom-Json)) {
        switch ($it.Type) {
            'Reg' { Restore-VdRegSnapshot $it.Snap }
            'Svc' {
                Restore-VdRegSnapshot $it.Start
                Restore-VdRegSnapshot $it.Delayed
                if ($it.WasRunning) { Start-Service -Name $it.Name -ErrorAction SilentlyContinue }
            }
            'Key' { if (-not $it.Existed -and (Test-Path -LiteralPath $it.Path)) { Remove-Item -LiteralPath $it.Path -Recurse -Force -ErrorAction Stop } }
            'Hibernate' { if ($it.Enabled) { powercfg /hibernate on | Out-Null } else { powercfg /hibernate off | Out-Null } }
            'PowerPlan' {
                if ($it.ActiveGuid) { powercfg /setactive $it.ActiveGuid | Out-Null }
                if ($it.ActiveGuid -ne $VdUltimatePlanGuid) { powercfg /delete $VdUltimatePlanGuid 2>$null | Out-Null }
            }
        }
    }
    Remove-ItemProperty -Path $VdStateRoot -Name $TweakName -Force -ErrorAction SilentlyContinue
    return $true
}
'@

# The OO ShutUp10 binary only runs if Windows reports a valid Authenticode signature from O&O Software.
$essentialTweaks = @(
    @{Name="Create Restore Point"; Tag="Essential"; 
      Do={ Checkpoint-Computer -Description "VDOWNSPrimeRestore" -RestorePointType "MODIFY_SETTINGS" }; 
      Undo={ throw "Restore points are not removed automatically; use System Protection to manage them." } },
    @{Name="Run OO ShutUp10"; Tag="Essential"; 
      Do={ $url = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"; $dir = Join-Path $env:TEMP ("VDOWNS_OOSU_" + [guid]::NewGuid().ToString("N")); New-Item -ItemType Directory -Path $dir -Force | Out-Null; $exe = Join-Path $dir "OOSU10.exe"; Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing -ErrorAction Stop; $sig = Get-AuthenticodeSignature -FilePath $exe; if ($sig.Status -ne "Valid" -or $sig.SignerCertificate.Subject -notmatch "O&O Software") { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue; throw "OOSU10.exe signature check failed ($($sig.Status)); file deleted, not executed." }; Start-Process -FilePath $exe }; 
      Undo={ throw "Open O&O ShutUp10 and use its own undo to revert its settings." } },
    @{Name="Disable Telemetry"; Tag="Essential"; State=@(@{Svc="DiagTrack"});
      Do={ Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue; Stop-Service DiagTrack -EA SilentlyContinue }; 
      Undo={ Set-Service DiagTrack -StartupType Automatic; Start-Service DiagTrack } },
    @{Name="Disable Ad ID"; Tag="Essential"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 1 } }
)

$uiTweaks = @(
    @{Name="Dark Mode (System)"; Tag="UI"; State=@(@{Reg="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="SystemUsesLightTheme"});
      Do={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1 } },
    @{Name="Dark Mode (Apps)"; Tag="UI"; State=@(@{Reg="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="AppsUseLightTheme"});
      Do={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1 } },
    @{Name="Show Hidden Files"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="Hidden"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 2 } },
    @{Name="Show File Extensions"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="HideFileExt"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 1 } },
    @{Name="Launch to 'This PC'"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="LaunchTo"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 2 } },
    @{Name="Classic Context Menu"; Tag="UI"; State=@(@{Key="HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"});
      Do={ $k = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"; New-Item -Path $k -Force | Out-Null; Set-Item -Path $k -Value "" }; 
      Undo={ Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue } },
    @{Name="Align Taskbar Left"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarAl"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1 } },
    @{Name="Hide Search Icon"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name="SearchboxTaskbarMode"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 } },
    @{Name="Clipboard History"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard"; Name="EnableClipboardHistory"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" "EnableClipboardHistory" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" "EnableClipboardHistory" 0 } }
)

$perfTweaks = @(
    @{Name="Disable Sticky Keys"; Tag="Power"; State=@(@{Reg="HKCU:\Control Panel\Accessibility\StickyKeys"; Name="Flags"});
      Do={ Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" }; 
      Undo={ Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "510" } },
    @{Name="Enable Hibernate"; Tag="Power"; State=@(@{Hibernate=$true});
      Do={ powercfg /hibernate on }; 
      Undo={ powercfg /hibernate off } },
    @{Name="Storage Sense"; Tag="Power"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"; Name="01"});
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0 } },
    @{Name="Ultimate Performance"; Tag="Power"; State=@(@{PowerPlan=$true});
      Do={ $g = "c4e0702f-b217-4220-b268-5cbd645bac82"; if ((powercfg /list | Out-String) -notmatch $g) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $g | Out-Null }; powercfg /setactive $g }; 
      Undo={ powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e; powercfg /delete c4e0702f-b217-4220-b268-5cbd645bac82 } },
    @{Name="Disable SysMain"; Tag="Power"; State=@(@{Svc="SysMain"});
      Do={ Set-Service SysMain -StartupType Disabled -EA SilentlyContinue; Stop-Service SysMain -EA SilentlyContinue }; 
      Undo={ Set-Service SysMain -StartupType Automatic; Start-Service SysMain } },
    @{Name="Disable Game DVR"; Tag="Power"; State=@(@{Reg="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"});
      Do={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1 } }
)

Add-TweakGroup "Essential Privacy" $essentialTweaks "#F85149"
Add-TweakGroup "Interface Explorer" $uiTweaks "#58A6FF"
Add-TweakGroup "Performance Power" $perfTweaks "#3FB950"

# Apply Tweaks (Async Runspace to prevent UI freezing)
$btnApplyTweaks.Add_Click({
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected.", "Info", "OK", "Information")
        return
    }

    Write-AppLog "Applying $($selected.Count) selected tweaks asynchronously..." "ACTION"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $false }
    if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $false }

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Do.ToString(); State = $t.State }
    }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnApply = $btnApplyTweaks
        BtnRevert = $btnRevertTweaks
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Tweaks, $SH, $Lib)
        . ([scriptblock]::Create($Lib))
        # Any error inside a tweak is a failure (it used to be logged as SUCCESS)
        $ErrorActionPreference = 'Stop'
        $applied = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                # Snapshot first; if that fails the tweak is skipped so Revert can always restore
                Save-VdTweakState $tName $item.State
                # Registry tweaks write into keys that may not exist yet on a fresh profile
                foreach ($e in @($item.State)) { if ($e -and $e.Reg -and -not (Test-Path -LiteralPath $e.Reg)) { New-Item -Path $e.Reg -Force | Out-Null } }
                $global:LASTEXITCODE = 0
                $null = & $sBlock
                if ($LASTEXITCODE -ne 0) { throw "command exited with code $LASTEXITCODE" }
                $applied++
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [SUCCESS] Applied: $tName`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $err = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [ERROR] Failed: $tName - $err`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            }
        }

        if ($applied -gt 0) {
            try { $SH.Window.Dispatcher.Invoke([action]{
                $ts = Get-Date -Format 'HH:mm:ss'
                $SH.LogBox.AppendText("[$ts] [INFO] Refreshing Windows Explorer...`r`n")
                $SH.LogBox.ScrollToEnd()
            }) } catch {}
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }

        return $applied
    })
    [void]$ps.AddParameter("Tweaks", $tweakData)
    [void]$ps.AddParameter("SH", $syncHash)
    [void]$ps.AddParameter("Lib", ($script:VdNativeLib + "`r`n" + $script:TweakStateLib))
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
        $count = @($result) | Select-Object -Last 1
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $true }
        if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $true }
        Write-AppLog "Tweak deployment completed ($count applied)." "SUCCESS"
    }
})

# Revert Tweaks (Async Runspace to prevent UI freezing)
$btnRevertTweaks.Add_Click({
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected to revert.", "Info", "OK", "Information")
        return
    }

    Write-AppLog "Reverting $($selected.Count) selected tweaks asynchronously..." "WARN"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $false }
    if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $false }

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Undo.ToString(); State = $t.State }
    }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnApply = $btnApplyTweaks
        BtnRevert = $btnRevertTweaks
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Tweaks, $SH, $Lib)
        . ([scriptblock]::Create($Lib))
        $ErrorActionPreference = 'Stop'
        $reverted = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                # Prefer the exact pre-tweak snapshot; fall back to the generic Undo block
                $global:LASTEXITCODE = 0
                $how = if (Restore-VdTweakState $tName) { "original state restored" } else { $null = & $sBlock; "default undo applied (no snapshot)" }
                if ($LASTEXITCODE -ne 0) { throw "command exited with code $LASTEXITCODE" }
                $reverted++
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [SUCCESS] Reverted: $tName - $how`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $err = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [ERROR] Failed to revert: $tName - $err`r`n")
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            }
        }

        if ($reverted -gt 0) {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }

        return $reverted
    })
    [void]$ps.AddParameter("Tweaks", $tweakData)
    [void]$ps.AddParameter("SH", $syncHash)
    [void]$ps.AddParameter("Lib", ($script:VdNativeLib + "`r`n" + $script:TweakStateLib))
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
        $count = @($result) | Select-Object -Last 1
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($btnApplyTweaks) { $btnApplyTweaks.IsEnabled = $true }
        if ($btnRevertTweaks) { $btnRevertTweaks.IsEnabled = $true }
        Write-AppLog "Tweak reversion completed ($count reverted)." "INFO"
    }
})

# =============================================================================
# 10. FEATURES & CONFIGURATION
# =============================================================================
function Add-FeatureCard {
    param([string]$Name, [string]$WinName, [string]$Description)
    
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $card.Background = $surfaceBrush
    $card.BorderBrush = $borderBrush
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.Padding = [System.Windows.Thickness]::new(18, 14, 18, 14)
    $card.Margin = [System.Windows.Thickness]::new(0, 5, 0, 5)
    
    $dockPanel = New-Object System.Windows.Controls.DockPanel
    
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.VerticalAlignment = "Center"
    $cb.Margin = [System.Windows.Thickness]::new(0, 0, 15, 0)
    [System.Windows.Controls.DockPanel]::SetDock($cb, "Right")
    
    $info = New-Object System.Windows.Controls.StackPanel
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $Name
    $nameText.FontSize = 15
    $nameText.FontWeight = "SemiBold"
    $nameText.Foreground = $textBrush
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $Description
    $descText.FontSize = 12
    $descText.Foreground = $textDimBrush
    $descText.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)
    [void]$info.Children.Add($nameText)
    [void]$info.Children.Add($descText)
    
    [void]$dockPanel.Children.Add($cb)
    [void]$dockPanel.Children.Add($info)
    $card.Child = $dockPanel
    
        $targetConfigBox = if ($script:featureContainer) { $script:featureContainer } elseif ($configContainer) { $configContainer } else { $script:configContainer }
    if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($card) }
    [void]$script:FeatureList.Add(@{Check=$cb; WinName=$WinName; Name=$Name})
}

# Script-scope target for the section headers ($targetConfigBox inside Add-FeatureCard is function-local)
$targetConfigBox = if ($featureContainer) { $featureContainer } else { Get-UIElement "featureContainer" }

$featHeader = New-Object System.Windows.Controls.TextBlock
$featHeader.Text = "Windows Optional Features"
$featHeader.FontSize = 18
$featHeader.FontWeight = "SemiBold"
$featHeader.Foreground = $accentBrush
$featHeader.Margin = [System.Windows.Thickness]::new(0, 5, 0, 15)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($featHeader) }

Add-FeatureCard "Hyper-V Platform" "Microsoft-Hyper-V-All" "Hardware virtualization for VMs and Docker (Pro/Enterprise/Education)"
Add-FeatureCard "WSL 2 (Linux)" "Microsoft-Windows-Subsystem-Linux,VirtualMachinePlatform" "Windows Subsystem for Linux + Virtual Machine Platform (required for WSL 2)"
Add-FeatureCard "Windows Sandbox" "Containers-DisposableClientVM" "Isolated desktop environment for safe testing (Pro/Enterprise/Education)"
Add-FeatureCard ".NET Framework 3.5" "NetFx3" "Required by legacy applications and games"

# Maintenance header
$maintHeader = New-Object System.Windows.Controls.TextBlock
$maintHeader.Text = "System Maintenance"
$maintHeader.FontSize = 18
$maintHeader.FontWeight = "SemiBold"
$maintHeader.Foreground = $dangerBrush
$maintHeader.Margin = [System.Windows.Thickness]::new(0, 25, 0, 10)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($maintHeader) }

$maintDesc = New-Object System.Windows.Controls.TextBlock
$maintDesc.Text = "Deep System Clean configures all cleanup categories and runs the extended Disk Cleanup utility in the background."
$maintDesc.Foreground = $textDimBrush
$maintDesc.FontSize = 13
$maintDesc.TextWrapping = "Wrap"
$maintDesc.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
if ($targetConfigBox) { [void]$targetConfigBox.Children.Add($maintDesc) }

if ($btnEnableFeatures) { $btnEnableFeatures.Add_Click({
    # DISM can take minutes: run it in a separate process and stream the output instead of freezing the UI
    $names = @($script:FeatureList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.WinName -split ',' } | Where-Object { $_ -match '^[A-Za-z0-9\-\.]+$' })
    if ($names.Count -eq 0) { [System.Windows.MessageBox]::Show("No features selected.", "Info", "OK", "Information"); return }
    $list = ($names | ForEach-Object { "'$_'" }) -join ', '
    $featureScript = @"
`$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name EditionID -ErrorAction SilentlyContinue).EditionID
if (`$edition -match 'Core') { Write-Output "Note: Windows `$edition (Home) does not include Hyper-V or Windows Sandbox." }
`$restart = `$false
foreach (`$f in @($list)) {
    Write-Output "Enabling `$f ..."
    try {
        `$r = Enable-WindowsOptionalFeature -Online -FeatureName `$f -All -NoRestart -ErrorAction Stop
        if (`$r.RestartNeeded) { `$restart = `$true }
        Write-Output "  OK: `$f"
    } catch {
        Write-Output "  FAILED: `$f - `$(`$_.Exception.Message)"
    }
}
if (`$restart) { Write-Output 'A RESTART is required to finish enabling the selected features.' }
"@
    Write-AppLog "Enabling $($names.Count) Windows feature(s) in the background..." "ACTION"
    Start-PSStreamingCommand $featureScript
}) }

if ($btnDeepClean) { $btnDeepClean.Add_Click({
    $result = [System.Windows.MessageBox]::Show("This will run Disk Cleanup in the background for a safe set of categories:`ntemporary files, caches, logs, crash dumps, Delivery Optimization files and superseded Windows Update files.`n`nNot touched: Downloads, Recycle Bin, previous Windows installations (rollback), Windows ESD files (Reset this PC) and language packs.`nNote: after Update Cleanup, already installed updates can no longer be uninstalled.`n`nContinue?", "Confirm Deep Clean", "YesNo", "Warning")
    if ($result -ne "Yes") { return }
    Write-AppLog "Starting Deep System Clean..." "ACTION"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        # Allow-list only: user data (Downloads, Recycle Bin) and recovery data (previous
        # installations, ESD files used by "Reset this PC", language packs) are never selected.
        # Every other handler gets its flag removed, which also clears flags set by v3.3.1.
        $safeHandlers = @(
            "Active Setup Temp Folders", "BranchCache", "D3D Shader Cache", "Delivery Optimization Files",
            "Diagnostic Data Viewer database files", "Downloaded Program Files", "Feedback Hub Archive log files",
            "Internet Cache Files", "Old ChkDsk Files", "RetailDemo Offline Content", "Setup Log Files",
            "System error memory dump files", "System error minidump files", "Temporary Files",
            "Temporary Setup Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files",
            "Windows Error Reporting Files", "Windows Upgrade Log Files"
        )
        $enabled = 0
        Get-ChildItem $regPath | ForEach-Object {
            if ($safeHandlers -contains $_.PSChildName) {
                New-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -PropertyType DWORD -Force | Out-Null
                $enabled++
            } else {
                Remove-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Force -ErrorAction SilentlyContinue
            }
        }
        Write-AppLog "Disk Cleanup categories selected: $enabled (safe allow-list)." "INFO"
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden
        Write-AppLog "Deep Clean started in background." "SUCCESS"
    } catch { Write-AppLog "Clean Error: $($_.Exception.Message)" "ERROR" }
}) }

# =============================================================================
# 11. DEBLOATER
# =============================================================================
$bloatItems = [ordered]@{
    "News, Weather & Money" = @(@("*BingNews*","*BingWeather*","*BingFinance*"), "Removes Bing News, Weather, and Money apps", $true)
    "Microsoft Solitaire"   = @(@("*MicrosoftSolitaireCollection*"), "Removes the pre-installed Solitaire game", $true)
    "Get Help & Tips"       = @(@("*GetHelp*","*Getstarted*"), "Removes Get Help and Tips bloatware", $true)
    "Feedback Hub"          = @(@("*WindowsFeedbackHub*"), "Removes the Feedback/Telemetry Hub", $true)
    "Cortana"               = @(@("*Cortana*"), "Removes the legacy Cortana assistant", $true)
    "People App"            = @(@("*Microsoft.People*"), "Removes People/Contacts integration", $false)
    "Groove Music"          = @(@("*ZuneMusic*"), "Removes legacy Groove Music player", $false)
    "Movies & TV"           = @(@("*ZuneVideo*"), "Removes Movies and TV app", $false)
    "Disney+"               = @(@("*Disney*"), "Removes pre-provisioned Disney+ app", $false)
    "3D Viewer & Paint 3D"  = @(@("*Microsoft3DViewer*","*MSPaint*"), "Removes 3D Viewer and Paint 3D", $false)
    "Office Hub"            = @(@("*MicrosoftOfficeHub*"), "Removes My Office promotional app", $false)
    "OneNote"               = @(@("*Office.OneNote*"), "Removes UWP OneNote app", $false)
    "Skype"                 = @(@("*SkypeApp*"), "Removes consumer Skype", $false)
    "Teams (Personal)"      = @(@("*Teams*"), "Removes personal Microsoft Teams", $false)
    "Sticky Notes"          = @(@("*MicrosoftStickyNotes*"), "Removes Sticky Notes widget", $false)
    "Voice Recorder"        = @(@("*WindowsSoundRecorder*"), "Removes Voice Recorder", $false)
    "Calculator"            = @(@("*WindowsCalculator*"), "Removes Calculator (caution!)", $false)
    "Windows Camera"        = @(@("*WindowsCamera*"), "Removes default Camera app", $false)
    "Alarms & Clock"        = @(@("*WindowsAlarms*"), "Removes Alarms and Timer app", $false)
    "Windows Maps"          = @(@("*WindowsMaps*"), "Removes offline Maps", $false)
    "To-Do"                 = @(@("*Todos*"), "Removes Microsoft To-Do", $false)
    "Mail & Calendar"       = @(@("*windowscommunicationsapps*"), "Removes Mail and Calendar", $false)
    "Xbox Game Bar"         = @(@("*XboxGamingOverlay*","*XboxGameOverlay*"), "Removes Win+G Game Bar", $false)
    "Xbox App & Identity"   = @(@("*XboxApp*","*XboxIdentityProvider*"), "Removes Xbox App", $false)
    "Your Phone"            = @(@("*YourPhone*","*PhoneLink*"), "Removes Phone Link", $false)
    "Mixed Reality"         = @(@("*MixedReality.Portal*"), "Removes VR/MR Portal", $false)
    "Quick Assist"          = @(@("*QuickAssist*"), "Removes remote support tool", $false)
    "Wallet / Pay"          = @(@("*Wallet*"), "Removes Microsoft Pay/Wallet", $false)
}

foreach ($k in $bloatItems.Keys) {
    $data = $bloatItems[$k]
    $patterns = $data[0]; $desc = $data[1]; $defaultChecked = $data[2]
    
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $card.Background = $surfaceBrush
    $card.BorderBrush = $borderBrush
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
    $card.Margin = [System.Windows.Thickness]::new(4)
    $card.Width = 280
    $card.Cursor = [System.Windows.Input.Cursors]::Hand
    
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.IsChecked = $defaultChecked
    $cb.Foreground = $textBrush
    $cb.FontSize = 13
    $cb.VerticalContentAlignment = "Top"
    
    $cbContent = New-Object System.Windows.Controls.StackPanel
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $k
    $nameText.FontWeight = "SemiBold"
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $desc
    $descText.Foreground = $textDimBrush
    $descText.FontSize = 11
    $descText.TextWrapping = "Wrap"
    $descText.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)
    [void]$cbContent.Children.Add($nameText)
    [void]$cbContent.Children.Add($descText)
    $cb.Content = $cbContent
    $card.Child = $cb
    
    $card.Add_MouseEnter({ $this.Background = $hoverBrush })
    $card.Add_MouseLeave({ $this.Background = $surfaceBrush })
    
    [void]$debloatContainer.Children.Add($card)
    [void]$script:DebloatList.Add(@{Check=$cb; Pat=$patterns; Name=$k; Recommended=[bool]$defaultChecked})
}

if ($btnSelectAll) { $btnSelectAll.Add_Click({ foreach ($i in $script:DebloatList) { $i.Check.IsChecked = $i.Recommended } }) }
if ($btnDeselectAll) { $btnDeselectAll.Add_Click({ foreach ($i in $script:DebloatList) { $i.Check.IsChecked = $false } }) }

if ($btnDebloat) { $btnDebloat.Add_Click({
    $selected = @($script:DebloatList | Where-Object { $_.Check.IsChecked -eq $true })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No items selected.", "Info", "OK", "Information"); return
    }
    $result = [System.Windows.MessageBox]::Show(
        "Selected apps will be PERMANENTLY removed from your user profile.`nSome system apps cannot be easily restored without PowerShell.`n`nAre you sure?",
        "Confirm Debloat", "YesNo", "Warning")
    if ($result -ne "Yes") { return }

    Write-AppLog "Starting Debloat Process asynchronously..." "ACTION"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    if ($btnDebloat) { $btnDebloat.IsEnabled = $false }

    $debloatData = @()
    foreach ($item in $selected) {
        $debloatData += @{ Name = $item.Name; Patterns = $item.Pat }
    }
    $chkProv = Get-UIElement "chkDebloatProvisioned"
    $alsoProvisioned = [bool]($chkProv -and $chkProv.IsChecked)

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnDebloat = $btnDebloat
        Provisioned = $alsoProvisioned
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Items, $SH)
        $removedCount = 0
        # Enumerate once instead of once per pattern
        $allPkgs = @(Get-AppxPackage)
        $allProv = if ($SH.Provisioned) { @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) } else { @() }
        foreach ($item in $Items) {
            foreach ($p in $item.Patterns) {
                try {
                    $pkgs = $allPkgs | Where-Object { $_.Name -like $p }
                    foreach ($pkg in $pkgs) {
                        $pName = $pkg.Name
                        try {
                            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                            $removedCount++
                            try { $SH.Window.Dispatcher.Invoke([action]{
                                $ts = Get-Date -Format 'HH:mm:ss'
                                $SH.LogBox.AppendText("[$ts] [SUCCESS] Removed Bloatware: $pName`r`n")
                                $SH.LogBox.ScrollToEnd()
                            }) } catch {}
                        } catch {
                            $m = $_.Exception.Message
                            try { $SH.Window.Dispatcher.Invoke([action]{
                                $ts = Get-Date -Format 'HH:mm:ss'
                                $SH.LogBox.AppendText("[$ts] [WARN] Could not remove $pName : $m`r`n")
                                $SH.LogBox.ScrollToEnd()
                            }) } catch {}
                        }
                    }
                } catch {
                    $m = $_.Exception.Message
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $SH.LogBox.AppendText("[$ts] [ERROR] Scan error for $p : $m`r`n")
                        $SH.LogBox.ScrollToEnd()
                    }) } catch {}
                }
                if ($SH.Provisioned) {
                    try {
                        foreach ($prov in @($allProv | Where-Object { $_.DisplayName -like $p })) {
                            $pvName = $prov.DisplayName
                            try {
                                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
                                $removedCount++
                                $msg = "[SUCCESS] Removed provisioned package (new users): $pvName"
                            } catch { $msg = "[WARN] Could not remove provisioned $pvName : $($_.Exception.Message)" }
                            try { $SH.Window.Dispatcher.Invoke([action]{
                                $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $msg`r`n"); $SH.LogBox.ScrollToEnd()
                            }) } catch {}
                        }
                    } catch {}
                }
            }
        }
        return $removedCount
    })
    [void]$ps.AddParameter("Items", $debloatData)
    [void]$ps.AddParameter("SH", $syncHash)
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
        param($result)
        $totalRemoved = @($result) | Select-Object -Last 1
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($btnDebloat) { $btnDebloat.IsEnabled = $true }
        Write-AppLog "Debloat sequence completed ($totalRemoved packages removed)!" "SUCCESS"
        [System.Windows.MessageBox]::Show("Cleanup operation complete! Total removed: $totalRemoved packages.", "Done", "OK", "Information")
    }
}) }

# =============================================================================
# 12. UPDATE & REPAIR CENTER
# =============================================================================
if ($btnUpdateApps) {
    $btnUpdateApps.Add_Click({
        Write-AppLog "Starting: Update All Apps..." "ACTION"
        Start-StreamingCommand "winget" "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
    })
}

# PSWindowsUpdate: pinned version, Authenticode-verified before import (runs in the child powershell.exe)
$script:PSWUBootstrap = @'
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
'@

if ($btnUpdateWindows) {
    $btnUpdateWindows.Add_Click({
        Write-AppLog "Starting: Windows Update..." "ACTION"
        Start-PSStreamingCommand ($script:PSWUBootstrap + "`r`nGet-WindowsUpdate -Install -AcceptAll -IgnoreReboot")
    })
}

if ($btnUpdateDrivers) {
    $btnUpdateDrivers.Add_Click({
        Write-AppLog "Starting: Driver Updates..." "ACTION"
        Start-PSStreamingCommand ($script:PSWUBootstrap + "`r`nGet-WindowsUpdate -UpdateType Driver -Install -AcceptAll -IgnoreReboot")
    })
}

if ($btnUpdateStore) {
    $btnUpdateStore.Add_Click({
        Write-AppLog "Starting: MS Store Updates..." "ACTION"
        Start-StreamingCommand "winget" "upgrade --all --accept-package-agreements --accept-source-agreements --source msstore --include-unknown"
    })
}

if ($btnSfc) {
    $btnSfc.Add_Click({
        Write-AppLog "Starting: SFC Scan..." "ACTION"
        Start-StreamingCommand "sfc" "/scannow"
    })
}

if ($btnDism) {
    $btnDism.Add_Click({
        Write-AppLog "Starting: DISM Repair..." "ACTION"
        Start-StreamingCommand "dism" "/Online /Cleanup-Image /RestoreHealth"
    })
}

if ($btnNetReset) {
    $btnNetReset.Add_Click({
        Write-AppLog "Starting: Network Reset..." "ACTION"
        Start-PSStreamingCommand 'ipconfig /flushdns; netsh winsock reset; netsh int ip reset; Write-Host "Network stack reset complete. Please reboot."'
    })
}

if ($btnFixWU) {
    $btnFixWU.Add_Click({
        $result = [System.Windows.MessageBox]::Show("This will forcibly reset Windows Update components.`nContinue?", "Emergency Fix", "YesNo", "Warning")
        if ($result -ne "Yes") { return }
        Write-AppLog "Starting: Emergency WU Fix..." "WARN"
        Start-PSStreamingCommand 'Stop-Service wuauserv -Force; Stop-Service cryptSvc -Force; Stop-Service bits -Force; Remove-Item "C:\\Windows\\SoftwareDistribution" -Recurse -Force; Start-Service wuauserv; Start-Service cryptSvc; Start-Service bits; Write-Host "WU components successfully purged and reset."'
    })
}

# =============================================================================
# 13. BACKUP & RESTORE CENTER
# =============================================================================

# Export .vdowns System Profile
if ($btnExportProfile) {
    $btnExportProfile.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "VDOWNS Profile (*.vdowns)|*.vdowns|JSON Files (*.json)|*.json"
        $sfd.FileName = "VDOWNS_Profile_$(Get-Date -Format 'yyyyMMdd').vdowns"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $profileObj = @{
                    Version = "3.1"
                    Date = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    SelectedApps = @($script:InstallList | Where-Object { $_.Check.IsChecked } | ForEach-Object { @{ Id = $_.Id; Name = $_.Name } })
                    SelectedTweaks = @($script:TweakList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                    SelectedDebloat = @($script:DebloatList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                }
                $jsonStr = $profileObj | ConvertTo-Json -Depth 5
                Set-Content -Path $sfd.FileName -Value $jsonStr -Encoding UTF8
                Write-AppLog "Profile exported to: $($sfd.FileName)" "SUCCESS"
                [System.Windows.MessageBox]::Show("Profile saved successfully!`nPath: $($sfd.FileName)", "Profile Saved", "OK", "Information")
            } catch {
                Write-AppLog "Failed to export profile: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Import .vdowns System Profile
if ($btnImportProfile) {
    $btnImportProfile.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "VDOWNS Profile (*.vdowns)|*.vdowns|JSON Files (*.json)|*.json"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $rawJson = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
                
                # Check matching apps (support both raw ID list and object list)
                $importedApps = @($rawJson.SelectedApps | ForEach-Object { if ($_.Id) { $_.Id } else { $_ } })
                $appCount = 0
                foreach ($item in $script:InstallList) {
                    if ($importedApps -contains $item.Id) {
                        $item.Check.IsChecked = $true
                        $appCount++
                    }
                }

                # Check matching tweaks
                $importedTweaks = @($rawJson.SelectedTweaks)
                foreach ($t in $script:TweakList) {
                    if ($importedTweaks -contains $t.Name) { $t.Check.IsChecked = $true }
                }

                # Check matching debloat
                $importedDebloat = @($rawJson.SelectedDebloat)
                foreach ($d in $script:DebloatList) {
                    if ($importedDebloat -contains $d.Name) { $d.Check.IsChecked = $true }
                }

                Write-AppLog "Profile imported from: $($ofd.FileName) ($appCount apps selected)" "SUCCESS"
                Show-Page "install"
                [System.Windows.MessageBox]::Show("Profile imported successfully!`n$appCount apps and corresponding tweaks/debloat selected.`nClick INSTALL SELECTED to begin installation.", "Profile Loaded", "OK", "Information")
            } catch {
                Write-AppLog "Failed to import profile: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Generate Unattended Standalone Setup Script (.ps1)
if ($btnExportUnattendedScript) {
    $btnExportUnattendedScript.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "PowerShell Script (*.ps1)|*.ps1"
        $sfd.FileName = "VDOWNS_Unattended_Setup_$(Get-Date -Format 'yyyyMMdd').ps1"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $selectedApps = @($script:InstallList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Id })
                $selectedTweakItems = @($script:TweakList | Where-Object { $_.Check.IsChecked })
                $selectedDebloatItems = @($script:DebloatList | Where-Object { $_.Check.IsChecked })

                # Single-quoted literals in the generated script: nothing in the data gets expanded there
                $appsLines = ($selectedApps | ForEach-Object { "    '" + ($_ -replace "'", "''") + "'" }) -join "`r`n"
                $debloatPatterns = @($selectedDebloatItems | ForEach-Object { $_.Pat } | ForEach-Object { $_ })
                $debloatLines = ($debloatPatterns | ForEach-Object { "    '" + ($_ -replace "'", "''") + "'" }) -join "`r`n"

                # Embed the exact Do block the GUI runs for every selected tweak
                $tweakBlocks = foreach ($t in $selectedTweakItems) {
                    $tn = $t.Name -replace "'", "''"
                    $body = $t.Do.ToString().Trim()
@"
try {
    Write-Host 'Applying: $tn' -ForegroundColor Cyan
    & {
        `$ErrorActionPreference = 'Stop'
        $body
    }
    `$tweaksApplied++
} catch {
    Write-Host ('Failed: $tn - ' + `$_.Exception.Message) -ForegroundColor Red
}
"@
                }
                $tweaksBlock = if ($tweakBlocks) { ($tweakBlocks -join "`r`n") } else { "Write-Host 'No tweaks selected.' -ForegroundColor DarkGray" }

                $scriptContent = @"
<#
.SYNOPSIS
    VDOWNS PRIME v$($script:VdownsVersion) - Automated Standalone Unattended Deployment Script
    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
#>
# Self-elevation check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"`$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VDOWNS PRIME - Standalone Unattended Deployment Engine  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Restore Point
try {
    Write-Host "`n[1/4] Creating System Restore Point..." -ForegroundColor Yellow
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "VDOWNS_Automated_Setup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Write-Host "Restore point initiated." -ForegroundColor Green
} catch {
    Write-Host "Restore point skipped: `$(`$_.Exception.Message)" -ForegroundColor DarkGray
}

# 2. Batch Winget Installations
Write-Host "`n[2/4] Installing Applications via Winget..." -ForegroundColor Yellow
`$appsToInstall = @(
$appsLines
)
foreach (`$appId in `$appsToInstall) {
    if ([string]::IsNullOrWhiteSpace(`$appId)) { continue }
    Write-Host "Installing `$appId..." -ForegroundColor Cyan
    winget install --id `$appId -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
}

# 3. System Tweaks Execution
Write-Host "`n[3/4] Applying System Tweaks..." -ForegroundColor Yellow
`$tweaksApplied = 0
$tweaksBlock

# 4. Debloater Execution
Write-Host "`n[4/4] Removing Selected Bloatware Packages..." -ForegroundColor Yellow
`$debloatPatterns = @(
$debloatLines
)
foreach (`$pattern in `$debloatPatterns) {
    `$found = @(Get-AppxPackage -AllUsers -Name `$pattern -EA SilentlyContinue)
    foreach (`$pkg in `$found) {
        Write-Host "Removing: `$(`$pkg.Name)" -ForegroundColor Cyan
        try { Remove-AppxPackage -Package `$pkg.PackageFullName -AllUsers -ErrorAction Stop }
        catch { Write-Host "Could not remove `$(`$pkg.Name): `$(`$_.Exception.Message)" -ForegroundColor Red }
    }
}

# Explorer Refresh
if (`$tweaksApplied -gt 0) { Stop-Process -Name explorer -Force -EA SilentlyContinue }
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
"@
                Set-Content -Path $sfd.FileName -Value $scriptContent -Encoding UTF8
                Write-AppLog "Unattended setup script generated: $($sfd.FileName)" "SUCCESS"
                [System.Windows.MessageBox]::Show("Standalone setup script generated successfully!`nPath: $($sfd.FileName)", "Script Generated", "OK", "Information")
            } catch {
                Write-AppLog "Failed to generate script: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Backup AppData Configurations (.zip) (Asynchronous Runspace)
if ($btnBackupConfig) {
    $btnBackupConfig.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "Zip Files (*.zip)|*.zip"
        $sfd.FileName = "VDOWNS_ConfigBackup_$(Get-Date -Format 'yyyyMMdd').zip"
        if ($sfd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $destZip = $sfd.FileName

        Write-AppLog "Starting AppData Configuration Backup in background..." "ACTION"
        $btnBackupConfig.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("destZip", $destZip)
        $runspace.SessionStateProxy.SetVariable("btnBackupConfig", $btnBackupConfig)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

            try {
                $tempDir = Join-Path $env:TEMP "VDOWNS_Backup_Temp"
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

                # 1. VS Code Settings & Extensions Manifest
                $vscodePath = Join-Path $env:APPDATA "Code\User"
                if (Test-Path $vscodePath) {
                    $vsTarget = Join-Path $tempDir "VSCode_User"
                    New-Item -ItemType Directory -Path $vsTarget -Force | Out-Null
                    Get-ChildItem -Path $vscodePath -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $vsTarget -Recurse -Force -EA SilentlyContinue
                    Log-Msg "Backed up VS Code user configurations." "INFO"
                }
                try {
                    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
                    if ($codeCmd) {
                        $r = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--list-extensions') 'UTF8'
                        Set-Content -Path (Join-Path $tempDir "vscode_extensions.txt") -Value $r.Output -Encoding UTF8
                        Log-Msg "Exported VS Code extensions manifest." "INFO"
                    }
                } catch {}

                # 2. Cursor Settings
                $cursorPath = Join-Path $env:APPDATA "Cursor\User"
                if (Test-Path $cursorPath) {
                    $curTarget = Join-Path $tempDir "Cursor_User"
                    New-Item -ItemType Directory -Path $curTarget -Force | Out-Null
                    Get-ChildItem -Path $cursorPath -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $curTarget -Recurse -Force -EA SilentlyContinue
                    Log-Msg "Backed up Cursor user configurations." "INFO"
                }

                # 3. Git Config
                $gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
                if (Test-Path $gitConfig) {
                    Copy-Item $gitConfig -Destination (Join-Path $tempDir ".gitconfig") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Git configuration (.gitconfig)." "INFO"
                }

                # 4. PowerShell Profiles ($PROFILE is not set inside a background runspace)
                $docsDir = [Environment]::GetFolderPath('MyDocuments')
                $winPsProfile = Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
                $pwshProfile  = Join-Path $docsDir "PowerShell\Microsoft.PowerShell_profile.ps1"
                if (Test-Path $winPsProfile) {
                    Copy-Item $winPsProfile -Destination (Join-Path $tempDir "Microsoft.PowerShell_profile.ps1") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Windows PowerShell profile." "INFO"
                }
                if (Test-Path $pwshProfile) {
                    Copy-Item $pwshProfile -Destination (Join-Path $tempDir "PowerShell7_profile.ps1") -Force -EA SilentlyContinue
                    Log-Msg "Backed up PowerShell 7 profile." "INFO"
                }

                # 5. Windows Terminal
                $wtPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
                if (Test-Path $wtPath) {
                    Copy-Item $wtPath -Destination (Join-Path $tempDir "Terminal_settings.json") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Windows Terminal settings." "INFO"
                }

                # 6. Notepad++
                $nppPath = Join-Path $env:APPDATA "Notepad++"
                if (Test-Path $nppPath) {
                    Copy-Item $nppPath -Destination (Join-Path $tempDir "NotepadPlusPlus") -Recurse -Force -EA SilentlyContinue
                    Log-Msg "Backed up Notepad++ settings." "INFO"
                }

                # 7. SSH Config (host mappings only, keys excluded for safety)
                $sshConfig = Join-Path $env:USERPROFILE ".ssh\config"
                if (Test-Path $sshConfig) {
                    $sshTarget = Join-Path $tempDir "SSH_Config"
                    New-Item -ItemType Directory -Path $sshTarget -Force | Out-Null
                    Copy-Item $sshConfig -Destination (Join-Path $sshTarget "config") -Force -EA SilentlyContinue
                    Log-Msg "Backed up SSH host mappings." "INFO"
                }

                # Compress
                Log-Msg "Compressing developer backup snapshot into ZIP..." "ACTION"
                if (Test-Path $destZip) { Remove-Item $destZip -Force }
                Compress-Archive -Path "$tempDir\*" -DestinationPath $destZip -Force
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

                Log-Msg "AppData Developer Backup completed successfully: $destZip" "SUCCESS"
                $window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show("AppData configurations backup complete!`nFile: $destZip", "Backup Complete", "OK", "Information")
                })
            } catch {
                Log-Msg "Backup failed: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnBackupConfig) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnBackupConfig.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
        }
    })
}

# Restore AppData Configurations (.zip) (Asynchronous Runspace)
if ($btnRestoreConfig) {
    $btnRestoreConfig.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Zip Files (*.zip)|*.zip"
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $srcZip = $ofd.FileName

        # Show what the archive will overwrite before touching anything
        $knownItems = [ordered]@{
            "VSCode_User"                      = "VS Code settings"
            "Cursor_User"                      = "Cursor settings"
            ".gitconfig"                       = "Git config"
            "Microsoft.PowerShell_profile.ps1" = "Windows PowerShell profile (runs code every time PowerShell starts)"
            "PowerShell7_profile.ps1"          = "PowerShell 7 profile (runs code every time PowerShell starts)"
            "Terminal_settings.json"           = "Windows Terminal settings"
            "NotepadPlusPlus"                  = "Notepad++ settings"
            "SSH_Config"                       = "SSH config"
            "vscode_extensions.txt"            = "VS Code extension list (extensions will be installed from the Marketplace)"
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zipPeek = [System.IO.Compression.ZipFile]::OpenRead($srcZip)
            $topNames = @($zipPeek.Entries | ForEach-Object { ($_.FullName -replace '\\', '/').Split('/')[0] } | Sort-Object -Unique)
            $zipPeek.Dispose()
        } catch {
            Write-AppLog "Cannot read backup archive: $($_.Exception.Message)" "ERROR"
            return
        }
        $found = @($knownItems.Keys | Where-Object { $topNames -contains $_ } | ForEach-Object { " - " + $knownItems[$_] })
        if ($found.Count -eq 0) {
            [System.Windows.MessageBox]::Show("This file does not look like a VDOWNS configuration backup.", "Restore", "OK", "Warning")
            return
        }
        $confirmMsg = "The following will be overwritten:`n" + ($found -join "`n") + "`n`nOnly restore backups you created yourself: profiles and extensions can run code.`nYour current files are first saved to %LOCALAPPDATA%\VDOWNS\PreRestore_<date>.`n`nContinue?"
        $res = [System.Windows.MessageBox]::Show($confirmMsg, "Confirm Restore", "YesNo", "Warning")
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        Write-AppLog "Restoring AppData Configuration Backup in background..." "WARN"
        $btnRestoreConfig.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("srcZip", $srcZip)
        $runspace.SessionStateProxy.SetVariable("btnRestoreConfig", $btnRestoreConfig)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

            try {
                $tempDir = Join-Path $env:TEMP "VDOWNS_Restore_Temp"
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
                # Extract manually so no entry can escape the temp folder (zip-slip)
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                $rootFull = [System.IO.Path]::GetFullPath($tempDir).TrimEnd('\') + '\'
                $zip = [System.IO.Compression.ZipFile]::OpenRead($srcZip)
                try {
                    foreach ($entry in $zip.Entries) {
                        $target = [System.IO.Path]::GetFullPath((Join-Path $tempDir $entry.FullName))
                        if (-not $target.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                            throw "Unsafe path in archive, restore aborted: $($entry.FullName)"
                        }
                        if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) {
                            New-Item -ItemType Directory -Path $target -Force | Out-Null
                            continue
                        }
                        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
                        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
                    }
                } finally { $zip.Dispose() }

                # Save everything that is about to be overwritten; abort if that fails
                $docsDirSafe = [Environment]::GetFolderPath('MyDocuments')
                $safetyDir = Join-Path $env:LOCALAPPDATA ("VDOWNS\PreRestore_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
                $currentItems = @(
                    @{ Zip = "VSCode_User";                      Path = (Join-Path $env:APPDATA "Code\User"); Dir = $true },
                    @{ Zip = "Cursor_User";                      Path = (Join-Path $env:APPDATA "Cursor\User"); Dir = $true },
                    @{ Zip = ".gitconfig";                       Path = (Join-Path $env:USERPROFILE ".gitconfig") },
                    @{ Zip = "Microsoft.PowerShell_profile.ps1"; Path = (Join-Path $docsDirSafe "WindowsPowerShell\Microsoft.PowerShell_profile.ps1") },
                    @{ Zip = "PowerShell7_profile.ps1";          Path = (Join-Path $docsDirSafe "PowerShell\Microsoft.PowerShell_profile.ps1") },
                    @{ Zip = "Terminal_settings.json";           Path = (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json") },
                    @{ Zip = "NotepadPlusPlus";                  Path = (Join-Path $env:APPDATA "Notepad++"); Dir = $true },
                    @{ Zip = "SSH_Config";                       Path = (Join-Path $env:USERPROFILE ".ssh\config") }
                )
                $saved = 0
                foreach ($ci in $currentItems) {
                    if (-not (Test-Path (Join-Path $tempDir $ci.Zip)) -or -not (Test-Path $ci.Path)) { continue }
                    $dest = Join-Path $safetyDir $ci.Zip
                    if ($ci.Dir) {
                        New-Item -ItemType Directory -Path $dest -Force -ErrorAction Stop | Out-Null
                        Get-ChildItem -Path $ci.Path -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $dest -Recurse -Force -ErrorAction Stop
                    } else {
                        New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force -ErrorAction Stop | Out-Null
                        Copy-Item -Path $ci.Path -Destination $dest -Force -ErrorAction Stop
                    }
                    $saved++
                }
                if ($saved -gt 0) { Log-Msg "Current settings saved before restore: $safetyDir" "INFO" }

                # Restore VS Code
                if (Test-Path "$tempDir\VSCode_User") {
                    $vscodeDest = Join-Path $env:APPDATA "Code\User"
                    New-Item -ItemType Directory -Path $vscodeDest -Force | Out-Null
                    Copy-Item "$tempDir\VSCode_User\*" -Destination $vscodeDest -Recurse -Force
                    Log-Msg "Restored VS Code configurations." "SUCCESS"
                }

                # Restore Git Config
                if (Test-Path "$tempDir\.gitconfig") {
                    Copy-Item "$tempDir\.gitconfig" -Destination (Join-Path $env:USERPROFILE ".gitconfig") -Force
                    Log-Msg "Restored Git configuration." "SUCCESS"
                }

                # Restore Cursor
                if (Test-Path "$tempDir\Cursor_User") {
                    $cursorDest = Join-Path $env:APPDATA "Cursor\User"
                    New-Item -ItemType Directory -Path $cursorDest -Force | Out-Null
                    Copy-Item "$tempDir\Cursor_User\*" -Destination $cursorDest -Recurse -Force
                    Log-Msg "Restored Cursor configurations." "SUCCESS"
                }

                # Restore PowerShell Profiles ($PROFILE is not set inside a background runspace)
                $docsDir = [Environment]::GetFolderPath('MyDocuments')
                $profileMap = @(
                    @{ Src = "Microsoft.PowerShell_profile.ps1"; Dest = Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"; Label = "Windows PowerShell" },
                    @{ Src = "PowerShell7_profile.ps1";          Dest = Join-Path $docsDir "PowerShell\Microsoft.PowerShell_profile.ps1";        Label = "PowerShell 7" }
                )
                foreach ($pm in $profileMap) {
                    $srcFile = Join-Path $tempDir $pm.Src
                    if (Test-Path $srcFile) {
                        New-Item -ItemType Directory -Path (Split-Path $pm.Dest -Parent) -Force | Out-Null
                        Copy-Item $srcFile -Destination $pm.Dest -Force
                        Log-Msg "Restored $($pm.Label) profile." "SUCCESS"
                    }
                }

                # Restore Windows Terminal
                if (Test-Path "$tempDir\Terminal_settings.json") {
                    $wtDest = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
                    if (Test-Path $wtDest) {
                        Copy-Item "$tempDir\Terminal_settings.json" -Destination (Join-Path $wtDest "settings.json") -Force
                        Log-Msg "Restored Windows Terminal settings." "SUCCESS"
                    }
                }

                # Restore Notepad++
                if (Test-Path "$tempDir\NotepadPlusPlus") {
                    $nppDest = Join-Path $env:APPDATA "Notepad++"
                    New-Item -ItemType Directory -Path $nppDest -Force | Out-Null
                    Copy-Item "$tempDir\NotepadPlusPlus\*" -Destination $nppDest -Recurse -Force
                    Log-Msg "Restored Notepad++ settings." "SUCCESS"
                }

                # Restore SSH Config
                if (Test-Path "$tempDir\SSH_Config\config") {
                    $sshDir = Join-Path $env:USERPROFILE ".ssh"
                    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
                    Copy-Item "$tempDir\SSH_Config\config" -Destination (Join-Path $sshDir "config") -Force
                    Log-Msg "Restored SSH host configurations." "SUCCESS"
                }

                # Optional VS Code Extension Reinstall
                $extFile = Join-Path $tempDir "vscode_extensions.txt"
                if (Test-Path $extFile) {
                    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
                    if ($codeCmd) {
                        Log-Msg "Reinstalling backed up VS Code extensions..." "ACTION"
                        $exts = Get-Content $extFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                        foreach ($ext in $exts) {
                            Log-Msg "Installing extension: $ext" "INFO"
                            if ($ext -notmatch '^[A-Za-z0-9][\w\-]*\.[\w\-\.]+$') { Log-Msg "Skipped invalid extension id: $ext" "WARN"; continue }
                            $null = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--install-extension', $ext, '--force') 'UTF8'
                        }
                    }
                }

                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                Log-Msg "AppData Developer Restore completed successfully!" "SUCCESS"
                $window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show("Developer configurations restored successfully!", "Restore Complete", "OK", "Information")
                })
            } catch {
                Log-Msg "Restore failed: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnRestoreConfig) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnRestoreConfig.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
        }
    })
}

# Winget Native Export
if ($btnWingetExport) {
    $btnWingetExport.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "JSON Files (*.json)|*.json"
        $sfd.FileName = "Winget_Installed_$(Get-Date -Format 'yyyyMMdd').json"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Write-AppLog "Exporting Winget package list..." "ACTION"
            Start-StreamingCommand "winget" "export -o `"$($sfd.FileName)`" --accept-source-agreements"
        }
    })
}

# Winget Native Import
if ($btnWingetImport) {
    $btnWingetImport.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "JSON Files (*.json)|*.json"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Write-AppLog "Importing Winget package list..." "ACTION"
            Start-StreamingCommand "winget" "import -i `"$($ofd.FileName)`" --accept-package-agreements --accept-source-agreements"
        }
    })
}

# =============================================================================
# 13B. PC HEALTH SCORE & 1-CLICK PRIME OPTIMIZATION
# =============================================================================
function Get-SystemHealthScore {
    $score = 100
    $deductions = [System.Collections.ArrayList]::new()
    
    # 1. Telemetry DiagTrack service
    try {
        $svc = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $score -= 15
            [void]$deductions.Add("Telemetry service active (-15)")
        }
    } catch {}

    # 2. AllowTelemetry registry
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -EA SilentlyContinue).AllowTelemetry
        if ($val -ne 0) {
            $score -= 15
            [void]$deductions.Add("Telemetry policies enabled (-15)")
        }
    } catch {}

    # 3. GameDVR
    try {
        $g = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -EA SilentlyContinue).GameDVR_Enabled
        if ($g -eq 1) {
            $score -= 10
            [void]$deductions.Add("Xbox GameDVR background recorder active (-10)")
        }
    } catch {}

    # 4. SysMain
    try {
        $sm = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sm -and $sm.Status -eq "Running") {
            $score -= 10
            [void]$deductions.Add("SysMain Superfetch active (-10)")
        }
    } catch {}

    # 5. Restore Point Check (Instant Registry Lookup)
    try {
        $rpReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        $lastSeq = (Get-ItemProperty -Path $rpReg -Name "LastSequenceNumber" -ErrorAction SilentlyContinue).LastSequenceNumber
        if ($null -eq $lastSeq -or $lastSeq -le 0) {
            $score -= 10
            [void]$deductions.Add("No recent System Restore Point found (-10)")
        }
    } catch {}

    # 6. File extensions hidden
    try {
        $he = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -EA SilentlyContinue).HideFileExt
        if ($he -ne 0) {
            $score -= 10
            [void]$deductions.Add("Known file extensions hidden (-10)")
        }
    } catch {}

    $finalScore = [math]::Max(0, [math]::Min(100, $score))
    return @{ Score = $finalScore; Deductions = $deductions }
}

function Update-HealthScoreUI {
    $res = Get-SystemHealthScore
    if ($lblHealthScore) {
        $lblHealthScore.Text = "$($res.Score)/100"
        if ($res.Score -ge 80) {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#3FB950")
        } elseif ($res.Score -ge 50) {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#D29922")
        } else {
            $lblHealthScore.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#F85149")
        }
    }
}

if ($btnRefreshHealth) {
    $btnRefreshHealth.Add_Click({
        Update-HealthScoreUI
        Write-AppLog "System optimization health score refreshed." "INFO"
    })
}

if ($btnPrimeBoost) {
    $btnPrimeBoost.Add_Click({
        $msg = "⚡ PRIME 1-CLICK SYSTEM OPTIMIZATION`n`nThis action will safely apply recommended system baselines:`n1. Create a System Restore Point ('VDOWNS_PrimeBoost')`n2. Disable Windows Telemetry & DiagTrack background data collection`n3. Disable Xbox Game DVR background recording`n4. Disable SysMain Superfetch SSD thrashing`n5. Enable file extensions and Dark Mode`n6. Purge temporary Windows cache`n`nDo you want to proceed?"
        $res = [System.Windows.MessageBox]::Show($msg, "Confirm Prime Optimization", "YesNo", "Question")
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        Write-AppLog "Executing 1-Click Prime Optimization pipeline..." "ACTION"
        $btnPrimeBoost.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("btnPrimeBoost", $btnPrimeBoost)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

            try {
                Log-Msg "[1/6] Creating System Restore Point..." "ACTION"
                try {
                    Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
                    Checkpoint-Computer -Description "VDOWNS_PrimeBoost" -RestorePointType "MODIFY_SETTINGS" -EA SilentlyContinue
                    Log-Msg "System Restore Point created." "SUCCESS"
                } catch { Log-Msg "Restore Point skipped: $($_.Exception.Message)" "WARN" }

                Log-Msg "[2/6] Disabling Windows Telemetry & Advertising ID..." "ACTION"
                foreach ($k in @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR", "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                    if (-not (Test-Path $k)) { New-Item -Path $k -Force -EA SilentlyContinue | Out-Null }
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Stop-Service -Name "DiagTrack" -Force -EA SilentlyContinue
                Set-Service -Name "DiagTrack" -StartupType Disabled -EA SilentlyContinue

                Log-Msg "[3/6] Disabling Xbox GameDVR background recording..." "ACTION"
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force -EA SilentlyContinue

                Log-Msg "[4/6] Disabling SysMain Superfetch..." "ACTION"
                Stop-Service -Name "SysMain" -Force -EA SilentlyContinue
                Set-Service -Name "SysMain" -StartupType Disabled -EA SilentlyContinue

                Log-Msg "[5/6] Applying Dark Mode & Showing File Extensions..." "ACTION"
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force -EA SilentlyContinue

                Log-Msg "[6/6] Purging Temporary File Caches..." "ACTION"
                Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue

                Log-Msg "Prime 1-Click Optimization finished. Review the log above for any skipped steps." "SUCCESS"
            } catch {
                Log-Msg "Optimization error: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnPrimeBoost) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnPrimeBoost.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
            Update-HealthScoreUI
            Write-AppLog "Health score refreshed after Prime Optimization." "INFO"
        }
    })
}

# =============================================================================
# 13C. DNS OPTIMIZER & LATENCY BENCHMARK
# =============================================================================
function Get-ActivePhysicalAdapters {
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
    $actAdapters = Get-ActivePhysicalAdapters
    if ($actAdapters.Count -gt 0 -and $lblActiveDnsAdapter) {
        $lblActiveDnsAdapter.Text = "Active: " + (($actAdapters | ForEach-Object { $_.Name }) -join ", ")
    }
} catch {}

if ($btnApplyDns) {
    $btnApplyDns.Add_Click({
        $adapters = Get-ActivePhysicalAdapters
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
        try { Clear-DnsClientCache -ErrorAction Stop } catch {}
        if ($ok.Count -gt 0) { Write-AppLog "DNS set to $selectedKey on: $($ok -join ', ') (IPv4 + IPv6)." "SUCCESS" }
        foreach ($f in $failed) { Write-AppLog "DNS change failed on $f" "ERROR" }
        $summary = if ($failed.Count -eq 0) { "DNS updated on: $($ok -join ', ')" } else { "Updated: $($ok -join ', ')`nFailed: $($failed.Count) adapter(s) - see the log." }
        [System.Windows.MessageBox]::Show("$summary`n`nServers:`n$($servers -join "`n")", "DNS", "OK", $(if ($failed.Count -eq 0) { "Information" } else { "Warning" })) | Out-Null
    })
}

if ($btnResetDns) {
    $btnResetDns.Add_Click({
        $adapters = Get-ActivePhysicalAdapters
        if ($adapters.Count -eq 0) { Write-AppLog "No active physical network adapter detected." "ERROR"; return }
        foreach ($a in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ResetServerAddresses -ErrorAction Stop
                Write-AppLog "DNS on '$($a.Name)' reset to automatic (DHCP)." "SUCCESS"
            } catch {
                Write-AppLog "DNS reset failed on '$($a.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
        try { Clear-DnsClientCache -ErrorAction Stop } catch {}
    })
}

if ($btnPingDns) {
    $btnPingDns.Add_Click({
        # Measures real DNS lookups against each resolver (ping only measured ICMP round-trip) and
        # runs in a separate process so slow or blocked resolvers cannot freeze the window.
        Write-AppLog "Starting DNS lookup benchmark in the background..." "ACTION"
        Start-PSStreamingCommand @'
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
'@
    })
}

# =============================================================================
# 13D. STARTUP PROGRAMS OPTIMIZER
# =============================================================================
$script:StartupItemsList = [System.Collections.ArrayList]::new()
$script:StartupStoreV2 = "HKCU:\Software\VDOWNS\DisabledStartupV2"
$script:StartupStoreLegacy = "HKCU:\Software\VDOWNS\DisabledStartup"

function Scan-StartupPrograms {
    if (-not $startupContainer) { return }
    $startupContainer.Children.Clear()
    $script:StartupItemsList.Clear()
    Write-AppLog "Scanning Windows startup entries..." "INFO"
    
    $runSources = @(
        @{ Label = "HKCU";       Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" },
        @{ Label = "HKLM";       Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" },
        @{ Label = "HKLM 32-bit"; Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" }
    )
    $entries = [System.Collections.ArrayList]::new()

    # Active entries: keep the raw (unexpanded) data and its registry type
    foreach ($src in $runSources) {
        if (-not (Test-Path $src.Path)) { continue }
        $key = Get-Item -Path $src.Path
        foreach ($n in $key.GetValueNames()) {
            if ([string]::IsNullOrEmpty($n)) { continue }
            [void]$entries.Add(@{ Name = $n; Raw = $key.GetValue($n, $null, 'DoNotExpandEnvironmentNames'); Kind = $key.GetValueKind($n).ToString()
                                  RegPath = $src.Path; Source = $src.Label; Disabled = $false; StoreKey = $null; Legacy = $false })
        }
    }

    # Disabled entries (v3.4.0+): one subkey per entry remembers where it came from
    if (Test-Path $script:StartupStoreV2) {
        foreach ($sub in Get-ChildItem -Path $script:StartupStoreV2) {
            $entryName = $sub.GetValue("EntryName"); $srcPath = $sub.GetValue("SourcePath")
            if (-not $entryName -or -not $srcPath) { continue }
            $label = ($runSources | Where-Object { $_.Path -eq $srcPath } | Select-Object -First 1).Label
            [void]$entries.Add(@{ Name = $entryName; Raw = $sub.GetValue("Data", $null, 'DoNotExpandEnvironmentNames'); Kind = $sub.GetValueKind("Data").ToString()
                                  RegPath = $srcPath; Source = $(if ($label) { $label } else { $srcPath }); Disabled = $true; StoreKey = $sub.PSPath; Legacy = $false })
        }
    }

    # Disabled entries written by v3.3.x and earlier (flat values, origin unknown -> HKCU Run)
    if (Test-Path $script:StartupStoreLegacy) {
        $lkey = Get-Item -Path $script:StartupStoreLegacy
        foreach ($n in $lkey.GetValueNames()) {
            if ([string]::IsNullOrEmpty($n)) { continue }
            [void]$entries.Add(@{ Name = $n; Raw = $lkey.GetValue($n, $null, 'DoNotExpandEnvironmentNames'); Kind = $lkey.GetValueKind($n).ToString()
                                  RegPath = $script:StartupStoreLegacy; Source = "HKCU (legacy)"; Disabled = $true; StoreKey = $null; Legacy = $true })
        }
    }

    foreach ($entry in $entries) {
                $prop = $entry.Name
                $val = "$($entry.Raw)"
                $card = New-Object System.Windows.Controls.Border
                $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#161B22")
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#21262D")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
                $card.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
                $card.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)

                $grid = New-Object System.Windows.Controls.Grid
                $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = [System.Windows.GridLength]::Auto
                $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::Auto
                $grid.ColumnDefinitions.Add($c0); $grid.ColumnDefinitions.Add($c1); $grid.ColumnDefinitions.Add($c2)

                $cb = New-Object System.Windows.Controls.CheckBox
                $cb.VerticalAlignment = "Center"
                $cb.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
                [System.Windows.Controls.Grid]::SetColumn($cb, 0)
                [void]$grid.Children.Add($cb)

                $infoStack = New-Object System.Windows.Controls.StackPanel
                $lblN = New-Object System.Windows.Controls.TextBlock
                $lblN.Text = "$prop  ($($entry.Source))"
                $lblN.FontWeight = "Bold"
                $lblN.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3")
                $lblN.FontSize = 12.5

                $lblC = New-Object System.Windows.Controls.TextBlock
                $lblC.Text = $val
                $lblC.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E")
                $lblC.FontSize = 10.5
                $lblC.TextTrimming = "CharacterEllipsis"

                [void]$infoStack.Children.Add($lblN)
                [void]$infoStack.Children.Add($lblC)
                [System.Windows.Controls.Grid]::SetColumn($infoStack, 1)
                [void]$grid.Children.Add($infoStack)

                $statusBorder = New-Object System.Windows.Controls.Border
                $statusBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $statusBorder.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
                $statusBorder.VerticalAlignment = "Center"
                $statusText = New-Object System.Windows.Controls.TextBlock
                $statusText.FontSize = 10
                $statusText.FontWeight = "Bold"

                if ($entry.Disabled) {
                    $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#3D1F24")
                    $statusText.Text = "DISABLED"
                    $statusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#F85149")
                } else {
                    $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1F3D2A")
                    $statusText.Text = "ENABLED"
                    $statusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#3FB950")
                }
                $statusBorder.Child = $statusText
                [System.Windows.Controls.Grid]::SetColumn($statusBorder, 2)
                [void]$grid.Children.Add($statusBorder)

                $card.Child = $grid
                [void]$startupContainer.Children.Add($card)
                [void]$script:StartupItemsList.Add(@{ Check = $cb; Name = $prop; Raw = $entry.Raw; Kind = $entry.Kind; RegPath = $entry.RegPath
                                                      Disabled = $entry.Disabled; StoreKey = $entry.StoreKey; Legacy = $entry.Legacy })
    }
    Write-AppLog "Found $($script:StartupItemsList.Count) startup programs." "SUCCESS"
}

if ($btnScanStartup) { $btnScanStartup.Add_Click({ Scan-StartupPrograms }) }

if ($btnDisableStartup) {
    $btnDisableStartup.Add_Click({
        $targets = @($script:StartupItemsList | Where-Object { $_.Check.IsChecked -and -not $_.Disabled })
        if ($targets.Count -eq 0) { [System.Windows.MessageBox]::Show("No enabled startup items selected.", "Info", "OK", "Information"); return }
        $res = [System.Windows.MessageBox]::Show("Disable $($targets.Count) startup item(s)?`n`nThey are moved to HKCU\Software\VDOWNS\DisabledStartupV2 together with their original location and type, and can be re-enabled at any time.", "Disable Startup Items", "YesNo", "Question")
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $count = 0
        foreach ($item in $targets) {
            $dst = Join-Path $script:StartupStoreV2 ([guid]::NewGuid().ToString("N"))
            try {
                New-Item -Path $dst -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path $dst -Name "EntryName" -Value $item.Name -PropertyType String -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path $dst -Name "SourcePath" -Value $item.RegPath -PropertyType String -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path $dst -Name "Data" -Value $item.Raw -PropertyType $item.Kind -Force -ErrorAction Stop | Out-Null
                # Only remove the original once the backup copy is safely written
                Remove-ItemProperty -LiteralPath $item.RegPath -Name $item.Name -Force -ErrorAction Stop
                $count++
            } catch {
                Remove-Item -Path $dst -Recurse -Force -ErrorAction SilentlyContinue
                Write-AppLog "Could not disable '$($item.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
        Write-AppLog "Disabled $count startup program(s); originals preserved in the VDOWNS store." "SUCCESS"
        Scan-StartupPrograms
    })
}

if ($btnEnableStartup) {
    $btnEnableStartup.Add_Click({
        $hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $count = 0
        foreach ($item in @($script:StartupItemsList | Where-Object { $_.Check.IsChecked -and $_.Disabled })) {
            try {
                # Legacy entries never recorded their origin; HKCU Run is the safest place for them
                $dest = if ($item.Legacy) { $hkcuRun } else { $item.RegPath }
                if (-not (Test-Path $dest)) { New-Item -Path $dest -Force -ErrorAction Stop | Out-Null }
                if ((Get-Item -Path $dest).GetValueNames() -contains $item.Name) {
                    Write-AppLog "Skipped '$($item.Name)': an active entry with the same name already exists." "WARN"
                    continue
                }
                New-ItemProperty -Path $dest -Name $item.Name -Value $item.Raw -PropertyType $item.Kind -Force -ErrorAction Stop | Out-Null
                if ($item.Legacy) {
                    Remove-ItemProperty -LiteralPath $script:StartupStoreLegacy -Name $item.Name -Force -ErrorAction SilentlyContinue
                } else {
                    Remove-Item -LiteralPath $item.StoreKey -Recurse -Force -ErrorAction SilentlyContinue
                }
                $count++
            } catch {
                Write-AppLog "Could not re-enable '$($item.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
        Write-AppLog "Re-enabled $count startup program(s) at their original location." "SUCCESS"
        Scan-StartupPrograms
    })
}

# =============================================================================
# 13E. ADD CUSTOM APPLICATION DIALOG
# =============================================================================
if ($btnAddCustomApp) {
    $btnAddCustomApp.Add_Click({
        $dlg = New-Object System.Windows.Window
        $dlg.Title = "Add Custom Software to Catalog"
        $dlg.Width = 480
        $dlg.Height = 440
        $dlg.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#0D1117")
        $dlg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3")
        $dlg.WindowStartupLocation = "CenterOwner"
        $dlg.Owner = $script:window
        $dlg.ResizeMode = "NoResize"

        $mainStack = New-Object System.Windows.Controls.StackPanel
        $mainStack.Margin = [System.Windows.Thickness]::new(20)

        $t = New-Object System.Windows.Controls.TextBlock
        $t.Text = "➕ Add Application to Catalog"
        $t.FontSize = 18
        $t.FontWeight = "Bold"
        $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#58A6FF")
        $t.Margin = [System.Windows.Thickness]::new(0, 0, 0, 15)
        [void]$mainStack.Children.Add($t)

        $lbl1 = New-Object System.Windows.Controls.TextBlock; $lbl1.Text = "Application Name (e.g. Spotify)"; $lbl1.FontSize = 12; $lbl1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E"); $lbl1.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
        $txtName = New-Object System.Windows.Controls.TextBox; $txtName.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#161B22"); $txtName.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3"); $txtName.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#30363D"); $txtName.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6); $txtName.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        [void]$mainStack.Children.Add($lbl1); [void]$mainStack.Children.Add($txtName)

        $lbl2 = New-Object System.Windows.Controls.TextBlock; $lbl2.Text = "Winget Package ID (e.g. Spotify.Spotify)"; $lbl2.FontSize = 12; $lbl2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E"); $lbl2.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
        $txtId = New-Object System.Windows.Controls.TextBox; $txtId.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#161B22"); $txtId.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3"); $txtId.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#30363D"); $txtId.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6); $txtId.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        [void]$mainStack.Children.Add($lbl2); [void]$mainStack.Children.Add($txtId)

        $lbl3 = New-Object System.Windows.Controls.TextBlock; $lbl3.Text = "Category"; $lbl3.FontSize = 12; $lbl3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E"); $lbl3.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
        $cbCat = New-Object System.Windows.Controls.ComboBox; $cbCat.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#161B22"); $cbCat.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3"); $cbCat.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6); $cbCat.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        $catNames = @($script:CatalogCategories)
        if ($catNames.Count -eq 0) { $catNames = @(($script:DefaultAppsJson | ConvertFrom-Json).PSObject.Properties.Name) }
        foreach ($catName in $catNames) { [void]$cbCat.Items.Add($catName) }
        $cbCat.SelectedIndex = 0
        [void]$mainStack.Children.Add($lbl3); [void]$mainStack.Children.Add($cbCat)

        $lbl4 = New-Object System.Windows.Controls.TextBlock; $lbl4.Text = "Official Web / GitHub URL (Optional)"; $lbl4.FontSize = 12; $lbl4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E"); $lbl4.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
        $txtUrl = New-Object System.Windows.Controls.TextBox; $txtUrl.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#161B22"); $txtUrl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3"); $txtUrl.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#30363D"); $txtUrl.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6); $txtUrl.Margin = [System.Windows.Thickness]::new(0, 0, 0, 15)
        [void]$mainStack.Children.Add($lbl4); [void]$mainStack.Children.Add($txtUrl)

        $btnGrid = New-Object System.Windows.Controls.Grid
        $bc0 = New-Object System.Windows.Controls.ColumnDefinition; $bc0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $bc1 = New-Object System.Windows.Controls.ColumnDefinition; $bc1.Width = [System.Windows.GridLength]::new(10, [System.Windows.GridUnitType]::Pixel)
        $bc2 = New-Object System.Windows.Controls.ColumnDefinition; $bc2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $btnGrid.ColumnDefinitions.Add($bc0); $btnGrid.ColumnDefinitions.Add($bc1); $btnGrid.ColumnDefinitions.Add($bc2)

        $btnSave = New-Object System.Windows.Controls.Button; $btnSave.Content = "SAVE TO CATALOG"; $btnSave.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#238636"); $btnSave.Foreground = [System.Windows.Media.Brushes]::White; $btnSave.FontWeight = "Bold"; $btnSave.Padding = [System.Windows.Thickness]::new(0, 10, 0, 10); $btnSave.Style = $window.Resources["RoundedBtn"]
        $btnCancel = New-Object System.Windows.Controls.Button; $btnCancel.Content = "CANCEL"; $btnCancel.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#21262D"); $btnCancel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#E6EDF3"); $btnCancel.Padding = [System.Windows.Thickness]::new(0, 10, 0, 10); $btnCancel.Style = $window.Resources["RoundedBtn"]

        [System.Windows.Controls.Grid]::SetColumn($btnSave, 0); [void]$btnGrid.Children.Add($btnSave)
        [System.Windows.Controls.Grid]::SetColumn($btnCancel, 2); [void]$btnGrid.Children.Add($btnCancel)
        [void]$mainStack.Children.Add($btnGrid)

        $dlg.Content = $mainStack

        $btnCancel.Add_Click({ $dlg.Close() })

        $btnSave.Add_Click({
            $nameVal = $txtName.Text.Trim()
            $idVal = $txtId.Text.Trim()
            $catVal = $cbCat.SelectedItem
            $urlVal = $txtUrl.Text.Trim()

            if ([string]::IsNullOrWhiteSpace($nameVal) -or [string]::IsNullOrWhiteSpace($idVal)) {
                [System.Windows.MessageBox]::Show("App Name and Winget ID are required.", "Validation Error", "OK", "Warning")
                return
            }

            if ($idVal -notmatch '^[a-zA-Z0-9_\-\.\+]+$') {
                [System.Windows.MessageBox]::Show("Winget ID contains invalid characters. Use letters, digits, dot, hyphen, underscore or plus (e.g. Vendor.App).", "Invalid ID", "OK", "Warning")
                return
            }

            if (-not [string]::IsNullOrWhiteSpace($urlVal) -and $urlVal -notmatch '^https?://[^\s"]+$') {
                [System.Windows.MessageBox]::Show("The URL must start with http:// or https://.", "Invalid URL", "OK", "Warning")
                return
            }

            if ([string]::IsNullOrWhiteSpace($catVal)) {
                [System.Windows.MessageBox]::Show("Please choose a category.", "Validation Error", "OK", "Warning")
                return
            }

            try {
                $jPath = Join-Path $ScriptPath "apps.json"
                $catalog = if (Test-Path $jPath) { Get-Content -Path $jPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $script:DefaultAppsJson | ConvertFrom-Json }
                $newObj = @{ Name = $nameVal; Id = $idVal; Desc = $idVal }
                if (![string]::IsNullOrWhiteSpace($urlVal)) { $newObj["Url"] = $urlVal }

                if ($catalog.PSObject.Properties.Name -contains $catVal) {
                    $catalog.$catVal = @($catalog.$catVal) + $newObj
                } else {
                    $catalog | Add-Member -MemberType NoteProperty -Name $catVal -Value @($newObj)
                }

                $catalog | ConvertTo-Json -Depth 5 | Set-Content -Path $jPath -Encoding UTF8 -Force
                Write-AppLog "Custom app '$nameVal' ($idVal) added to $catVal and saved to apps.json." "SUCCESS"
                $dlg.Close()
                [System.Windows.MessageBox]::Show("Application '$nameVal' added successfully!`nRestart or re-open App Center to view updated list.", "App Added", "OK", "Information")
            } catch {
                Write-AppLog "Failed to save custom app: $($_.Exception.Message)" "ERROR"
            }
        })

        $dlg.ShowDialog() | Out-Null
    })
}

# =============================================================================
# 13F. WINDOWS UPDATE DEFERRAL CONTROLS
# =============================================================================
if ($btnPauseUpdates) {
    $btnPauseUpdates.Add_Click({
        $res = [System.Windows.MessageBox]::Show("Do you want to pause Windows Updates for 35 days?`n(Registry: PauseQualityUpdates & PauseFeatureUpdates)", "Pause Updates", "YesNo", "Question")
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $end = (Get-Date).AddDays(35).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            try {
                if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force -ErrorAction Stop | Out-Null }
                foreach ($pair in @(@("PauseFeatureUpdatesStartTime", $now), @("PauseFeatureUpdatesEndTime", $end),
                                    @("PauseQualityUpdatesStartTime", $now), @("PauseQualityUpdatesEndTime", $end),
                                    @("PauseUpdatesExpiryTime", $end))) {
                    New-ItemProperty -Path $wuPath -Name $pair[0] -Value $pair[1] -PropertyType String -Force -ErrorAction Stop | Out-Null
                }
                Write-AppLog "Windows Updates paused for 35 days until: $end" "SUCCESS"
                [System.Windows.MessageBox]::Show("Windows Updates paused until:`n$end", "Updates Paused", "OK", "Information")
            } catch {
                Write-AppLog "Could not pause Windows Updates: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

if ($btnResumeUpdates) {
    $btnResumeUpdates.Add_Click({
        $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        $props = @("PauseFeatureUpdatesStartTime", "PauseFeatureUpdatesEndTime", "PauseQualityUpdatesStartTime", "PauseQualityUpdatesEndTime", "PauseUpdatesExpiryTime")
        foreach ($p in $props) {
            Remove-ItemProperty -Path $wuPath -Name $p -Force -EA SilentlyContinue
        }
        Write-AppLog "Windows Updates resumed. Standard automatic checks active." "SUCCESS"
        [System.Windows.MessageBox]::Show("Windows Updates resumed to normal automatic checks.", "Updates Resumed", "OK", "Information")
    })
}

# 14. LIVE HARDWARE TELEMETRY & CONSOLE DRAWER
# =============================================================================

# A. Collapsible Log Drawer & Copy Handler
if ($btnToggleLog -and $logPanelGrid) {
    $script:logExpanded = $false
    $btnToggleLog.Add_Click({
        if ($script:logExpanded) {
            $logPanelGrid.Height = 32
            $logBox.Visibility = "Collapsed"
            $btnToggleLog.Content = "▲ Expand"
            $script:logExpanded = $false
        } else {
            $logPanelGrid.Height = 130
            $logBox.Visibility = "Visible"
            $btnToggleLog.Content = "▼ Collapse"
            $script:logExpanded = $true
        }
    })
}

if ($btnCopyLog -and $logBox) {
    $btnCopyLog.Add_Click({
        try {
            if (-not [string]::IsNullOrEmpty($logBox.Text)) {
                [System.Windows.Clipboard]::SetText($logBox.Text)
                Write-AppLog "Activity logs copied to clipboard." "SUCCESS"
            }
        } catch {}
    })
}

if ($btnClearLog -and $logBox) {
    $btnClearLog.Add_Click({
        $logBox.Clear()
        if ($lblLogCount) { $lblLogCount.Text = "CLEARED" }
    })
}

# B. Live Hardware Telemetry Engine
try {
    $prodName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName" -ErrorAction SilentlyContinue).ProductName
    $dispVer  = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($lblOsInfo) {
        $lblOsInfo.Text = if ($prodName) { "$prodName ($dispVer)" } else { "Windows 10/11" }
    }
} catch {
    if ($lblOsInfo) { $lblOsInfo.Text = "Windows 10/11" }
}

$script:telemetryTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:telemetryTimer.Interval = [TimeSpan]::FromSeconds(3.5)
$script:telemetryTimer.Add_Tick({
    try {
        # 1. Native Win32 RAM Telemetry (0.01ms execution, zero RPC/WMI overhead)
        $mem = [NativeSysInfo]::GetMemory()
        if ($mem) {
            $totalGB = [math]::Round($mem.ullTotalPhys / 1GB, 1)
            $availGB = [math]::Round($mem.ullAvailPhys / 1GB, 1)
            $usedGB  = [math]::Round($totalGB - $availGB, 1)
            $ramPct  = [int]$mem.dwMemoryLoad
            if ($lblRamPct) { $lblRamPct.Text = "${usedGB}/${totalGB} GB (${ramPct}%)" }
            if ($pbRam) { $pbRam.Value = $ramPct }
        }

        # 2. Targeted C: Drive Telemetry (Direct query without enumerating removable/network drives)
        $cDrive = New-Object System.IO.DriveInfo("C")
        if ($cDrive.IsReady) {
            $dFreeGB  = [math]::Round($cDrive.AvailableFreeSpace / 1GB, 1)
            $dTotalGB = [math]::Round($cDrive.TotalSize / 1GB, 1)
            $dUsedGB  = [math]::Round($dTotalGB - $dFreeGB, 1)
            $dPct     = [math]::Min(100, [math]::Max(0, [int](($dUsedGB / $dTotalGB) * 100)))
            if ($lblDiskPct) { $lblDiskPct.Text = "${dFreeGB} GB free" }
            if ($pbDisk) { $pbDisk.Value = $dPct }
        }

        # 3. Native Win32 CPU Load Telemetry (0.01ms GetSystemTimes, zero thread stalls)
        $load = [NativeSysInfo]::GetCpuLoad()
        if ($lblCpuPct) { $lblCpuPct.Text = "${load} %" }
        if ($pbCpu) { $pbCpu.Value = $load }
    } catch {}
})
$script:telemetryTimer.Start()

# Initial logs
Write-AppLog "VDOWNS PRIME v$($script:VdownsVersion) (Fluent UI Edition) initialized." "INFO"
Write-AppLog "Hardware-accelerated WPF subsystem online." "SUCCESS"
try {
    $wv = (Invoke-VdNative 'winget.exe' @('--version') 'UTF8').Output.Trim()
    Write-AppLog "Winget detected: $wv" "INFO"
} catch { Write-AppLog "Winget not found! App Center may not work." "ERROR" }
Update-HealthScoreUI

# Elevated with a different (admin) account? Then every HKCU tweak, backup and startup change
# lands in that account's profile, not in the signed-in user's.
try {
    $desktopUser = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
    $runAsUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    if ($desktopUser -and $runAsUser -and $desktopUser -ne $runAsUser) {
        Write-AppLog "Running as '$runAsUser' but the signed-in user is '$desktopUser'. Per-user settings will apply to '$runAsUser'." "WARN"
        [System.Windows.MessageBox]::Show("VDOWNS PRIME is running as '$runAsUser', but the signed-in desktop user is '$desktopUser'.`n`nPer-user changes (dark mode, Explorer options, startup items, developer backups) will apply to '$runAsUser', not to '$desktopUser'.", "Different User Account", "OK", "Warning") | Out-Null
    }
} catch {}
Write-AppLog "System Architect is ready. Select a category from the sidebar to begin." "SUCCESS"

# 15. SHOW WINDOW
# =============================================================================
if ($window) {
    $window.Add_Closed({
        try { if ($script:telemetryTimer) { $script:telemetryTimer.Stop() } } catch {}
    })
}
$window.ShowDialog() | Out-Null

} catch {
    [System.Windows.MessageBox]::Show(
        "Critical Error Occurred:`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)",
        "VDOWNS PRIME Error", "OK", "Error")
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    # Read-Host removed for noConsole GUI
}
