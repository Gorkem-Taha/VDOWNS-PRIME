<#
.SYNOPSIS
    VDOWNS PRIME v3.3.0 - System Architect (WPF Edition)
.DESCRIPTION
    Advanced System Configuration Tool built with PowerShell + WPF.
    Features: App Center, System Tweaks, Windows Features, Debloater, Update & Repair Center, Backup & Restore Center, Winget Manager.
    
    Compilation (PS2EXE):
    ps2exe -inputFile .\vdowns_3.0.ps1 -outputFile .\VDOWNS_PRIME.exe -noConsole -STA -title "VDOWNS PRIME" -version "3.0.0.0"
#>

$ErrorActionPreference = "Continue"

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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {

# =============================================================================
# 3. XAML INTERFACE DEFINITION
# =============================================================================
[xml]$xaml = @'
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="VDOWNS PRIME v3.3.0 | Fluent System Architect"
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
                            <TextBlock Text="v3.3" FontSize="10" FontWeight="Bold" Foreground="#22D3EE"/>
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
                                    <Path Data="M3 4a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm8 0a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1V4zM3 12a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1v-4zm8 0a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z" Fill="#58A6FF"/>
                                </Viewbox>
                                <TextBlock Text="App Center" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuWinget" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 1a1 1 0 00-.5.13L1.5 4.38A1 1 0 001 5.25v5.5a1 1 0 00.5.87l6 3.25a1 1 0 001 0l6-3.25a1 1 0 00.5-.87v-5.5a1 1 0 00-.5-.87L8.5 1.13A1 1 0 008 1zM2.5 5.5l5.5-3 5.5 3-5.5 3-5.5-3zm6 4.14l5.5-3v4.72l-5.5 2.98V9.64zm-1 0v4.72l-5.5-2.98V6.64l5.5 3z" Fill="#22D3EE"/>
                                </Viewbox>
                                <TextBlock Text="Winget Manager" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuTweaks" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M9.13 1.07a1 1 0 00-1.04.14L1.3 7.07A1 1 0 002 8.75h4.25L4.87 14.93a1 1 0 001.7.94l6.79-5.86a1 1 0 00-.7-1.76H8.41l1.38-6.18a1 1 0 00-.66-1z" Fill="#EAB308"/>
                                </Viewbox>
                                <TextBlock Text="System Tweaks" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuConfig" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 0a2 2 0 00-2 2v.26A5 5 0 004.26 3.4l-.18-.18a2 2 0 00-2.83 2.83l.18.18A5 5 0 001.26 8H1a2 2 0 00-2 2 2 2 0 002 2h.26a5 5 0 001.14 1.74l-.18.18a2 2 0 002.83 2.83l.18-.18A5 5 0 008 17.74V18a2 2 0 002 2 2 2 0 002-2v-.26a5 5 0 001.74-1.14l.18.18a2 2 0 002.83-2.83l-.18-.18A5 5 0 0017.74 12H18a2 2 0 002-2 2 2 0 00-2-2h-.26a5 5 0 00-1.14-1.74l.18-.18a2 2 0 00-2.83-2.83l-.18.18A5 5 0 0012 2.26V2a2 2 0 00-2-2zm0 6a4 4 0 110 8 4 4 0 010-8z" Fill="#A855F7"/>
                                </Viewbox>
                                <TextBlock Text="Features &amp; Clean" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuDebloat" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 0c-.8 0-4.5 1.5-7.5 2.5C.2 2.6 0 2.9 0 3.3c0 7.2 4.4 12 8 13.7 3.6-1.7 8-6.5 8-13.7 0-.4-.2-.7-.5-.8C12.5 1.5 8.8 0 8 0zm0 1.5c.6 0 3.8 1.3 6.5 2.2C14.2 8.7 10.7 13 8 14.6 5.3 13 1.8 8.7 1.5 3.7 4.2 2.8 7.4 1.5 8 1.5z" Fill="#EF4444"/>
                                </Viewbox>
                                <TextBlock Text="OS Debloater" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuUpdates" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M8 1.5a6.5 6.5 0 106.18 4.5h-1.57A5 5 0 118 3v2l4-2.5L8 0v1.5z" Fill="#10B981"/>
                                </Viewbox>
                                <TextBlock Text="Repair &amp; Updates" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="btnMenuBackup" Style="{StaticResource SidebarBtn}">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Data="M4 4a4 4 0 017.9-1A3.5 3.5 0 0115 6.5a3.5 3.5 0 01-3.5 3.5H4a4 4 0 010-8zm4 1v3.5h2L7.5 11 5 8.5h2V5h1z" Fill="#38BDF8"/>
                                </Viewbox>
                                <TextBlock Text="Backup &amp; Deploy" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Button>
                    </StackPanel>
                </ScrollViewer>

                <!-- Live Hardware Telemetry Panel -->
                <Border Grid.Row="2" Background="#161B22" CornerRadius="10" BorderBrush="#21262D" BorderThickness="1" Margin="10,6" Padding="12,10">
                    <StackPanel>
                        <Grid Margin="0,0,0,6">
                            <TextBlock Text="HARDWARE TELEMETRY" FontSize="9.5" FontWeight="Bold" Foreground="#8B949E"/>
                            <TextBlock Text="● LIVE" FontSize="9" FontWeight="Bold" Foreground="#3FB950" HorizontalAlignment="Right"/>
                        </Grid>

                        <TextBlock x:Name="lblOsInfo" Text="Windows 11 x64" Foreground="#C9D1D9" FontSize="11" FontWeight="SemiBold" TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"/>

                        <!-- CPU Load -->
                        <Grid Margin="0,6,0,2">
                            <TextBlock Text="CPU Load" FontSize="10" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblCpuPct" Text="-- %" FontSize="10" Foreground="#58A6FF" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbCpu" Height="4" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#58A6FF" BorderThickness="0"/>

                        <!-- RAM Usage -->
                        <Grid Margin="0,6,0,2">
                            <TextBlock Text="Memory" FontSize="10" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblRamPct" Text="-- GB" FontSize="10" Foreground="#3FB950" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbRam" Height="4" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#3FB950" BorderThickness="0"/>

                        <!-- Disk Space -->
                        <Grid Margin="0,6,0,2">
                            <TextBlock Text="Storage (C:)" FontSize="10" Foreground="#8B949E"/>
                            <TextBlock x:Name="lblDiskPct" Text="-- GB" FontSize="10" Foreground="#A855F7" HorizontalAlignment="Right" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar x:Name="pbDisk" Height="4" Minimum="0" Maximum="100" Value="0" Background="#21262D" Foreground="#A855F7" BorderThickness="0"/>
                    </StackPanel>
                </Border>

                <!-- Terminate Application -->
                <Button Grid.Row="3" x:Name="btnExit" Style="{StaticResource SidebarBtn}" Margin="8,4,8,12">
                    <StackPanel Orientation="Horizontal">
                        <Viewbox Width="14" Height="14" Margin="0,0,8,0">
                            <Path Data="M3.72 3.72a.75.75 0 011.06 0L8 6.94l3.22-3.22a.75.75 0 111.06 1.06L9.06 8l3.22 3.22a.75.75 0 11-1.06 1.06L8 9.06l-3.22 3.22a.75.75 0 01-1.06-1.06L6.94 8 3.72 4.78a.75.75 0 010-1.06z" Fill="#F85149"/>
                        </Viewbox>
                        <TextBlock Text="TERMINATE" Foreground="#F85149" FontWeight="Bold" FontSize="12.5"/>
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
            <Border Grid.Row="0" Background="#0C1017" BorderBrush="#21262D" BorderThickness="0,0,0,1" Padding="20,10">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                        <Border Background="#161B22" CornerRadius="6" BorderBrush="#30363D" BorderThickness="1" Padding="10,5" Margin="0,0,12,0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="🛡️ " FontSize="12" VerticalAlignment="Center"/>
                                <TextBlock Text="PC Optimization Score: " FontSize="12" Foreground="#8B949E" VerticalAlignment="Center"/>
                                <TextBlock x:Name="lblHealthScore" Text="Analyzing..." FontSize="12" FontWeight="Bold" Foreground="#3FB950" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                        <Button x:Name="btnRefreshHealth" Content="🔄 Scan Health" Background="#21262D" Foreground="#8B949E" FontSize="11" FontWeight="SemiBold" Padding="10,5" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>

                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button x:Name="btnPrimeBoost" Content="⚡ 1-CLICK PRIME OPTIMIZATION" Background="#238636" Foreground="White" FontSize="12.5" FontWeight="Bold" Padding="16,7" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- ===== PAGE: APP CENTER ===== -->
            <Grid x:Name="pageInstall" Grid.Row="1" Margin="25,20,25,12">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <!-- 0: Header -->
                    <RowDefinition Height="Auto"/> <!-- 1: Search & Batch Buttons -->
                    <RowDefinition Height="Auto"/> <!-- 2: Category Filter Chips -->
                    <RowDefinition Height="*"/>    <!-- 3: Cards Container -->
                    <RowDefinition Height="Auto"/> <!-- 4: Progress Panel -->
                    <RowDefinition Height="Auto"/> <!-- 5: Main Action Buttons -->
                </Grid.RowDefinitions>

                <!-- Header -->
                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="App Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Discover, install, and manage applications with instant category filtering, silent winget execution, and single-click installs" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <!-- Search and Controls bar -->
                <Grid Grid.Row="1" Margin="0,0,0,10">
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
                                     BorderThickness="0" FontSize="13.5" Padding="12,8" CaretBrush="#E6EDF3"/>
                        </Border>
                        <TextBlock x:Name="searchPlaceholder" Text="  🔍  Search 96 software packages by name, keyword, or Winget ID..." 
                                   Foreground="#484F58" FontSize="13" VerticalAlignment="Center" 
                                   Margin="12,0" IsHitTestVisible="False"/>
                    </Grid>

                    <Button x:Name="btnAddCustomApp" Grid.Column="2" Content="➕ Add App" 
                            Background="#1F6FEB" Foreground="White" FontSize="12" FontWeight="SemiBold" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnAppSelectAll" Grid.Column="4" Content="Select All" 
                            Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnAppDeselectAll" Grid.Column="6" Content="Deselect All" 
                            Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                </Grid>

                <!-- Category Filter Chips -->
                <ScrollViewer Grid.Row="2" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled" Margin="0,0,0,12">
                    <StackPanel x:Name="filterChipsPanel" Orientation="Horizontal"/>
                </ScrollViewer>

                <!-- App Cards View -->
                <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel x:Name="appContainer"/>
                </ScrollViewer>

                <!-- Progress Panel -->
                <Border x:Name="progressPanel" Grid.Row="4" Visibility="Collapsed" 
                        Background="#161B22" CornerRadius="8" Padding="14" Margin="0,10,0,0" 
                        BorderBrush="#30363D" BorderThickness="1">
                    <StackPanel>
                        <TextBlock x:Name="progressText" Text="" Foreground="#E6EDF3" FontSize="13.5" FontWeight="SemiBold" Margin="0,0,0,8"/>
                        <ProgressBar x:Name="progressBar" Height="8" Minimum="0" Maximum="100" Value="0" 
                                     Foreground="#58A6FF" Background="#21262D" BorderThickness="0"/>
                    </StackPanel>
                </Border>

                <!-- Batch Action Buttons -->
                <Grid Grid.Row="5" Margin="0,12,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnInstall" Grid.Column="0" Content="INSTALL SELECTED PACKAGES" 
                            Background="#238636" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnUninstall" Grid.Column="2" Content="UNINSTALL SELECTED PACKAGES" 
                            Background="#DA3633" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: WINGET MANAGER ===== -->
            <Grid x:Name="pageWinget" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="Winget Manager" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Scan installed packages on your system, search online Winget repository, and remove/add any software" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <!-- Controls & Search Bar -->
                <Grid Grid.Row="1" Margin="0,5,0,12">
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
                                     BorderThickness="0" FontSize="13.5" Padding="12,8" CaretBrush="#E6EDF3"/>
                        </Border>
                        <TextBlock x:Name="wingetSearchPlaceholder" Text="  🔍  Search Microsoft Winget online repository..." 
                                   Foreground="#484F58" FontSize="13" VerticalAlignment="Center" 
                                   Margin="12,0" IsHitTestVisible="False"/>
                    </Grid>

                    <Button x:Name="btnWingetSearch" Grid.Column="2" Content="Search Online" 
                            Background="#58A6FF" Foreground="White" FontSize="12" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnScanWingetInstalled" Grid.Column="4" Content="Scan Installed" 
                            Background="#21262D" Foreground="#E6EDF3" FontSize="12" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnWingetUpgradeAll" Grid.Column="6" Content="Upgrade All" 
                            Background="#238636" Foreground="White" FontSize="12" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                </Grid>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="wingetResultsContainer"/>
                </ScrollViewer>

                <Border x:Name="wingetProgressPanel" Grid.Row="3" Visibility="Collapsed" 
                        Background="#161B22" CornerRadius="8" Padding="14" Margin="0,10,0,0" 
                        BorderBrush="#30363D" BorderThickness="1">
                    <StackPanel>
                        <TextBlock x:Name="wingetProgressText" Text="Loading Winget Data..." Foreground="#E6EDF3" FontSize="13.5" FontWeight="SemiBold" Margin="0,0,0,8"/>
                        <ProgressBar x:Name="wingetProgressBar" Height="6" IsIndeterminate="True" 
                                     Foreground="#58A6FF" Background="#21262D" BorderThickness="0"/>
                    </StackPanel>
                </Border>
            </Grid>

            <!-- ===== PAGE: SYSTEM TWEAKS ===== -->
            <Grid x:Name="pageTweaks" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="System Tweaks" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Safe and reversible performance, privacy, and interface optimizations for Windows 10 and 11" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="tweakContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,12,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnApplyTweaks" Grid.Column="0" Content="APPLY SELECTED TWEAKS" 
                            Background="#238636" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnRevertTweaks" Grid.Column="2" Content="REVERT SELECTED TWEAKS" 
                            Background="#DA3633" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: FEATURES & CONFIG ===== -->
            <Grid x:Name="pageConfig" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="Features &amp; Extended Maintenance" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Enable optional Windows subsystems and run deep disk cleanup" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <StackPanel x:Name="featureContainer"/>

                        <!-- Windows Startup Programs Optimizer -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18" Margin="0,16,0,0">
                            <StackPanel>
                                <Grid Margin="0,0,0,10">
                                    <TextBlock Text="Windows Startup Programs Optimizer" FontSize="16" FontWeight="Bold" Foreground="#A855F7"/>
                                    <Button x:Name="btnScanStartup" Content="🔄 Scan Startup Items" HorizontalAlignment="Right" Background="#21262D" Foreground="#E6EDF3" FontSize="11" FontWeight="SemiBold" Padding="12,5" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <TextBlock Text="Manage background applications that launch automatically when Windows boots. Disabling unnecessary startup items drastically reduces system boot times." Foreground="#8B949E" FontSize="12" Margin="0,0,0,12"/>
                                <ScrollViewer MaxHeight="220" VerticalScrollBarVisibility="Auto" Margin="0,0,0,12">
                                    <StackPanel x:Name="startupContainer"/>
                                </ScrollViewer>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnDisableStartup" Grid.Column="0" Content="DISABLE SELECTED STARTUP ITEMS" Background="#DA3633" FontSize="13" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnEnableStartup" Grid.Column="2" Content="RE-ENABLE SELECTED STARTUP ITEMS" Background="#238636" FontSize="13" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,12,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnInstallFeatures" Grid.Column="0" Content="INSTALL SELECTED FEATURES" 
                            Background="#238636" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnDeepClean" Grid.Column="2" Content="RUN EXTENDED DISK CLEANUP" 
                            Background="#58A6FF" FontSize="15" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: DEBLOATER ===== -->
            <Grid x:Name="pageDebloat" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="Windows Debloater" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Safely remove pre-installed Windows UWP apps and telemetry packages to free RAM and background CPU" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="debloatContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,12,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnDebloatSelectAll" Grid.Column="0" Content="SELECT RECOMMENDED FOR REMOVAL" 
                            Background="#21262D" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnRemoveBloat" Grid.Column="2" Content="REMOVE SELECTED BLOATWARE" 
                            Background="#DA3633" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: UPDATES & REPAIR ===== -->
            <Grid x:Name="pageUpdates" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="Update &amp; System Repair Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Update software, scan and repair Windows image corruptions, and reset network stack" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <!-- Update Cards -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18" Margin="0,0,0,14">
                            <StackPanel>
                                <TextBlock Text="Update Modules" FontSize="16" FontWeight="Bold" Foreground="#58A6FF" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="10"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <Button x:Name="btnUpdateApps" Grid.Row="0" Grid.Column="0" Content="UPDATE ALL APPS (WINGET)" Background="#238636" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateWindows" Grid.Row="0" Grid.Column="2" Content="UPDATE WINDOWS (OS ONLY)" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateDrivers" Grid.Row="2" Grid.Column="0" Content="UPDATE DRIVERS ONLY" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnUpdateStore" Grid.Row="2" Grid.Column="2" Content="FORCE MS STORE UPDATES" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Grid Margin="0,10,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnPauseUpdates" Grid.Column="0" Content="PAUSE UPDATES (35 DAYS)" Background="#D29922" Foreground="Black" FontWeight="SemiBold" FontSize="12.5" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResumeUpdates" Grid.Column="2" Content="RESUME AUTOMATIC UPDATES" Background="#21262D" FontSize="12.5" Padding="0,11" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- Repair Cards -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18">
                            <StackPanel>
                                <TextBlock Text="System Repair &amp; Diagnostics" FontSize="16" FontWeight="Bold" Foreground="#A855F7" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="10"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <Button x:Name="btnRepairSfc" Grid.Row="0" Grid.Column="0" Content="RUN SFC /SCANNOW" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnRepairDism" Grid.Row="0" Grid.Column="2" Content="RUN DISM REPAIR" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResetNetwork" Grid.Row="2" Grid.Column="0" Content="RESET NETWORK STACK" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnFixUpdates" Grid.Row="2" Grid.Column="2" Content="PURGE UPDATE CACHE" Background="#DA3633" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- DNS Optimizer & Latency Benchmark -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18" Margin="0,14,0,0">
                            <StackPanel>
                                <Grid Margin="0,0,0,10">
                                    <TextBlock Text="DNS Optimizer &amp; Latency Benchmark" FontSize="16" FontWeight="Bold" Foreground="#22D3EE"/>
                                    <TextBlock x:Name="lblActiveDnsAdapter" Text="Active Adapter: Detecting..." Foreground="#8B949E" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                                </Grid>
                                <TextBlock Text="Switch your DNS provider to reduce network latency, block malware, or eliminate ads at the connection level." Foreground="#8B949E" FontSize="12" Margin="0,0,0,12"/>
                                <Grid Margin="0,0,0,12">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <ComboBox x:Name="cbDnsProvider" Grid.Column="0" Height="36" Background="#21262D" Foreground="#E6EDF3" FontSize="13" VerticalContentAlignment="Center" Padding="8,0"/>
                                    <Button x:Name="btnApplyDns" Grid.Column="2" Content="APPLY SELECTED DNS" Background="#238636" FontSize="13" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnPingDns" Grid.Column="0" Content="⚡ BENCHMARK DNS LATENCIES (PING)" Background="#1F6FEB" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnResetDns" Grid.Column="2" Content="RESET TO AUTOMATIC (DHCP)" Background="#21262D" FontSize="12.5" Padding="0,10" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ===== PAGE: BACKUP & RESTORE ===== -->
            <Grid x:Name="pageBackup" Grid.Row="1" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="Backup, Deploy &amp; Restore Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Export configurations, generate unattended bare-metal deployment scripts, and archive developer environments" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <!-- SECTION 1: SYSTEM PROFILE BACKUP -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18" Margin="0,0,0,14">
                            <StackPanel>
                                <TextBlock Text="1. VDOWNS System Profile &amp; Unattended Script" FontSize="17" FontWeight="Bold" Foreground="#58A6FF" Margin="0,0,0,6"/>
                                <TextBlock Text="Export your currently selected apps, active tweaks, and debloat settings into a portable profile file, or generate a standalone script to provision new PCs from a USB drive." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnExportProfile" Grid.Column="0" Content="EXPORT PROFILE (.vdowns)" Background="#58A6FF" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnImportProfile" Grid.Column="2" Content="IMPORT PROFILE &amp; APPLY" Background="#238636" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Button x:Name="btnExportUnattendedScript" Margin="0,10,0,0" Content="⚡ GENERATE UNATTENDED STANDALONE SETUP SCRIPT (.ps1)" Background="#1F6FEB" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 2: APPDATA CONFIG BACKUP -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18" Margin="0,0,0,14">
                            <StackPanel>
                                <TextBlock Text="2. Developer Environment &amp; AppData Snapshot (.zip)" FontSize="17" FontWeight="Bold" Foreground="#A855F7" Margin="0,0,0,6"/>
                                <TextBlock Text="Asynchronously archive developer tools (VS Code settings &amp; extension manifest, Cursor, Git identity, PowerShell profile, Windows Terminal, Notepad++, SSH configs) into a compressed archive with non-blocking UI." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnBackupConfig" Grid.Column="0" Content="CREATE DEVELOPER BACKUP (.zip)" Background="#8957E5" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnRestoreConfig" Grid.Column="2" Content="RESTORE DEVELOPER BACKUP (.zip)" Background="#D29922" Foreground="Black" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 3: WINGET BUNDLE BACKUP -->
                        <Border Background="#161B22" CornerRadius="10" BorderBrush="#30363D" BorderThickness="1" Padding="18">
                            <StackPanel>
                                <TextBlock Text="3. Winget Installed Packages List" FontSize="17" FontWeight="Bold" Foreground="#22D3EE" Margin="0,0,0,6"/>
                                <TextBlock Text="Export all installed applications via native Winget manifest, or restore missing packages on a clean installation." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="12"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnWingetExport" Grid.Column="0" Content="EXPORT WINGET MANIFEST" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnWingetImport" Grid.Column="2" Content="IMPORT WINGET MANIFEST" Background="#21262D" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ===== COLLAPSIBLE LIVE LOG PANEL ===== -->
            <Border Grid.Row="2" Background="#0D1117" BorderBrush="#21262D" BorderThickness="0,1,0,0">
                <Grid x:Name="logPanelGrid" Height="130">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="14,6,14,5">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="ACTIVITY CONSOLE" Foreground="#8B949E" FontSize="10" FontWeight="Bold"/>
                            <Border Background="#161B22" CornerRadius="4" Padding="6,1" Margin="8,0,0,0">
                                <TextBlock x:Name="lblLogCount" Text="READY" Foreground="#58A6FF" FontSize="9" FontWeight="SemiBold"/>
                            </Border>
                        </StackPanel>

                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button x:Name="btnCopyLog" Content="📋 Copy" Background="Transparent" Foreground="#8B949E" FontSize="11" Padding="8,3" Style="{StaticResource RoundedBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="btnClearLog" Content="🧹 Clear" Background="Transparent" Foreground="#8B949E" FontSize="11" Padding="8,3" Style="{StaticResource RoundedBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="btnToggleLog" Content="▼ Collapse" Background="#161B22" Foreground="#C9D1D9" FontSize="10.5" FontWeight="SemiBold" Padding="10,3" Style="{StaticResource RoundedBtn}"/>
                        </StackPanel>
                    </Grid>

                    <TextBox x:Name="logBox" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap" 
                             VerticalScrollBarVisibility="Auto" Background="#090D13" Foreground="#8B949E" 
                             FontFamily="Consolas" FontSize="11" BorderThickness="0" Padding="14,4"
                             AcceptsReturn="True"/>
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

# Auto-discover all named elements
$nsmgr = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$nsmgr.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
$xaml.SelectNodes('//*[@x:Name]', $nsmgr) | ForEach-Object {
    $elName = $_.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
    if ($elName) {
        $el = $window.FindName($elName)
        if ($el) { Set-Variable -Name $elName -Value $el -Scope Script }
    }
}

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
{"Internet & Comms": [{"Name": "Brave", "Id": "Brave.Brave", "Desc": "Privacy focused browser", "Url": "https://brave.com"}, {"Name": "Chrome", "Id": "Google.Chrome", "Desc": "Standard web browser", "Url": "https://google.com/chrome"}, {"Name": "Firefox", "Id": "Mozilla.Firefox", "Desc": "Open source browser", "Url": "https://mozilla.org/firefox"}, {"Name": "LibreWolf", "Id": "LibreWolf.LibreWolf", "Desc": "Hardened Firefox Fork", "Url": "https://librewolf.net"}, {"Name": "Tor Browser", "Id": "TorProject.TorBrowser", "Desc": "Anonymous browsing", "Url": "https://torproject.org"}, {"Name": "Opera GX", "Id": "Opera.OperaGX", "Desc": "Gaming Browser", "Url": "https://opera.com/gx"}, {"Name": "Cloudflare Warp", "Id": "Cloudflare.Warp", "Desc": "VPN and DNS Utility", "Url": "https://1.1.1.1"}, {"Name": "Proton VPN", "Id": "Proton.ProtonVPN", "Desc": "Secure VPN Service", "Url": "https://protonvpn.com"}, {"Name": "WhatsApp", "Id": "WhatsApp.WhatsApp", "Desc": "Messaging App", "Url": "https://whatsapp.com"}, {"Name": "Telegram", "Id": "Telegram.TelegramDesktop", "Desc": "Fast & Secure Messaging", "Url": "https://desktop.telegram.org"}, {"Name": "Discord", "Id": "Discord.Discord", "Desc": "Voice & Text Chat", "Url": "https://discord.com"}, {"Name": "Signal", "Id": "Signal.Signal", "Desc": "Encrypted Messenger", "Url": "https://signal.org"}, {"Name": "Zoom", "Id": "Zoom.Zoom", "Desc": "Video Conferencing", "Url": "https://zoom.us"}, {"Name": "LocalSend", "Id": "LocalSend.LocalSend", "Desc": "AirDrop alternative", "Url": "https://localsend.org"}, {"Name": "Free Download Mgr", "Id": "SoftDeluxe.FreeDownloadManager", "Desc": "Fast download manager", "Url": "https://freedownloadmanager.org"}, {"Name": "qBittorrent", "Id": "qBittorrent.qBittorrent", "Desc": "Open Source Torrent Client", "Url": "https://qbittorrent.org"}], "Development": [{"Name": "VS Code", "Id": "Microsoft.VisualStudioCode", "Desc": "Code Editor by Microsoft", "Url": "https://code.visualstudio.com"}, {"Name": "Visual Studio 2022", "Id": "Microsoft.VisualStudio.2022.Community", "Desc": "Full IDE (.NET/C++)", "Url": "https://visualstudio.microsoft.com"}, {"Name": "Cursor AI", "Id": "Anysphere.Cursor", "Desc": "AI-powered Code Editor", "Url": "https://cursor.com"}, {"Name": "Sublime Text", "Id": "SublimeHQ.SublimeText.4", "Desc": "Fast Text Editor", "Url": "https://sublimetext.com"}, {"Name": "Notepad++", "Id": "Notepad++.Notepad++", "Desc": "Lightweight Text Editor", "Url": "https://notepad-plus-plus.org"}, {"Name": "Git", "Id": "Git.Git", "Desc": "Version Control System", "Url": "https://git-scm.com"}, {"Name": "GitHub Desktop", "Id": "GitHub.GitHubDesktop", "Desc": "GUI for Git", "Url": "https://desktop.github.com"}, {"Name": "Node.js LTS", "Id": "OpenJS.NodeJS.LTS", "Desc": "JavaScript Runtime", "Url": "https://nodejs.org"}, {"Name": "Python 3", "Id": "Python.Python.3", "Desc": "Python Programming Language", "Url": "https://python.org"}, {"Name": "GoLang", "Id": "GoLang.Go", "Desc": "Go Programming Language", "Url": "https://go.dev"}, {"Name": "Rust", "Id": "Rustlang.Rustup", "Desc": "Rust Toolchain", "Url": "https://rust-lang.org"}, {"Name": "Docker Desktop", "Id": "Docker.DockerDesktop", "Desc": "Container Platform", "Url": "https://docker.com"}, {"Name": "PowerShell 7", "Id": "Microsoft.PowerShell", "Desc": "Cross-platform PowerShell", "Url": "https://github.com/PowerShell/PowerShell"}, {"Name": "Oh My Posh", "Id": "JanDeDobbeleer.OhMyPosh", "Desc": "Terminal Theme Engine", "Url": "https://ohmyposh.dev"}, {"Name": "Meslo Nerd Font", "Id": "Ryanoasis.NerdFonts.Meslo", "Desc": "Icons for Terminal", "Url": "https://nerdfonts.com"}, {"Name": "Postman", "Id": "Postman.Postman", "Desc": "API Testing Tool", "Url": "https://postman.com"}], "Office & Productivity": [{"Name": "LibreOffice", "Id": "TheDocumentFoundation.LibreOffice", "Desc": "Free Office Suite", "Url": "https://libreoffice.org"}, {"Name": "OnlyOffice", "Id": "ONLYOFFICE.DesktopEditors", "Desc": "Clean Office Alternative", "Url": "https://onlyoffice.com"}, {"Name": "Adobe Acrobat Reader", "Id": "Adobe.Acrobat.Reader.64-bit", "Desc": "PDF Viewer", "Url": "https://get.adobe.com/reader"}, {"Name": "SumatraPDF", "Id": "SumatraPDF.SumatraPDF", "Desc": "Fast PDF Reader", "Url": "https://sumatrapdfreader.org"}, {"Name": "Notion", "Id": "Notion.Notion", "Desc": "Notes & Workspace", "Url": "https://notion.so"}, {"Name": "Obsidian", "Id": "Obsidian.Obsidian", "Desc": "Knowledge Base (Markdown)", "Url": "https://obsidian.md"}, {"Name": "AnyDesk", "Id": "AnyDeskSoftwareGmbH.AnyDesk", "Desc": "Remote Desktop", "Url": "https://anydesk.com"}, {"Name": "TeamViewer", "Id": "TeamViewer.TeamViewer", "Desc": "Remote Support", "Url": "https://teamviewer.com"}], "Creativity & Design": [{"Name": "GIMP", "Id": "GIMP.GIMP", "Desc": "Free Photoshop Alternative", "Url": "https://gimp.org"}, {"Name": "Paint.NET", "Id": "dotPDN.PaintDotNet", "Desc": "Simple Image Editor", "Url": "https://getpaint.net"}, {"Name": "Inkscape", "Id": "Inkscape.Inkscape", "Desc": "Vector Graphics Editor", "Url": "https://inkscape.org"}, {"Name": "Blender", "Id": "BlenderFoundation.Blender", "Desc": "3D Modeling Suite", "Url": "https://blender.org"}, {"Name": "Figma", "Id": "Figma.Figma", "Desc": "UI/UX Design Tool", "Url": "https://figma.com"}, {"Name": "Krita", "Id": "Krita.Krita", "Desc": "Digital Painting", "Url": "https://krita.org"}, {"Name": "HandBrake", "Id": "HandBrake.HandBrake", "Desc": "Video Transcoder", "Url": "https://handbrake.fr"}], "Utilities & Tools": [{"Name": "PowerToys", "Id": "Microsoft.PowerToys", "Desc": "Essential Windows Utilities", "Url": "https://github.com/microsoft/PowerToys"}, {"Name": "7-Zip", "Id": "7zip.7zip", "Desc": "Classic Archive tool", "Url": "https://7-zip.org"}, {"Name": "WinRAR", "Id": "RARLab.WinRAR", "Desc": "Popular Archive Manager", "Url": "https://rarlab.com"}, {"Name": "NanaZip", "Id": "M2Team.NanaZip", "Desc": "Modern 7-Zip for Win11", "Url": "https://github.com/M2Team/NanaZip"}, {"Name": "Rufus", "Id": "Rufus.Rufus", "Desc": "Bootable USB tool", "Url": "https://rufus.ie"}, {"Name": "Ventoy", "Id": "Ventoy.Ventoy", "Desc": "Multi-boot USB Creator", "Url": "https://ventoy.net"}, {"Name": "CPU-Z", "Id": "CPUID.CPU-Z", "Desc": "Hardware info", "Url": "https://cpuid.com/softwares/cpu-z.html"}, {"Name": "GPU-Z", "Id": "TechPowerUp.GPU-Z", "Desc": "Graphics Card Info", "Url": "https://techpowerup.com/gpuz"}, {"Name": "CrystalDiskMark", "Id": "CrystalDiskMark.CrystalDiskMark", "Desc": "Disk Benchmark", "Url": "https://crystalmark.info"}, {"Name": "Files App", "Id": "Files-Community.Files", "Desc": "Modern File Explorer Alternative", "Url": "https://files.community"}, {"Name": "ModernFlyouts", "Id": "ModernFlyouts-Community.ModernFlyouts", "Desc": "Better Volume/Brightness UI", "Url": "https://github.com/ModernFlyouts-Community/ModernFlyouts"}, {"Name": "Ditto", "Id": "ScottBrosius.Ditto", "Desc": "Advanced Clipboard Manager", "Url": "https://ditto-cp.sourceforge.io"}, {"Name": "Rainmeter", "Id": "Rainmeter.Rainmeter", "Desc": "Desktop Customization Tool", "Url": "https://rainmeter.net"}, {"Name": "Wallpaper Engine", "Id": "GamerSoftware.WallpaperEngine", "Desc": "Live Wallpapers (Steam)", "Url": "https://wallpaperengine.io"}, {"Name": "TeraCopy", "Id": "CodeSector.TeraCopy", "Desc": "Faster File Copying", "Url": "https://codesector.com/teracopy"}, {"Name": "Everything", "Id": "voidtools.Everything", "Desc": "Instant File Search", "Url": "https://voidtools.com"}, {"Name": "WizTree", "Id": "AntibodySoftware.WizTree", "Desc": "Disk Space Analyzer", "Url": "https://diskanalyzer.com"}, {"Name": "BleachBit", "Id": "BleachBit.BleachBit", "Desc": "System Cleaner", "Url": "https://bleachbit.org"}, {"Name": "Revo Uninstaller", "Id": "RevoUninstaller.RevoUninstallerFree", "Desc": "Deep Uninstall Tool", "Url": "https://revouninstaller.com"}, {"Name": "Bitwarden", "Id": "Bitwarden.Bitwarden", "Desc": "Password Manager", "Url": "https://bitwarden.com"}, {"Name": "KeePassXC", "Id": "KeePassXCTeam.KeePassXC", "Desc": "Offline Password Manager", "Url": "https://keepassxc.org"}, {"Name": "HWiNFO", "Id": "RealiX.HWiNFO", "Desc": "Hardware Monitoring", "Url": "https://hwinfo.com"}, {"Name": "Process Explorer", "Id": "Microsoft.Sysinternals.ProcessExplorer", "Desc": "Advanced Task Manager", "Url": "https://learn.microsoft.com/sysinternals/downloads/process-explorer"}, {"Name": "ShareX", "Id": "ShareX.ShareX", "Desc": "Screenshot and Recording Tool", "Url": "https://getsharex.com"}, {"Name": "UniGetUI", "Id": "Marticliment.UniGetUI", "Desc": "GUI for Winget", "Url": "https://github.com/marticliment/UniGetUI"}], "Multimedia & Gaming": [{"Name": "VLC", "Id": "VideoLAN.VLC", "Desc": "Universal Video Player", "Url": "https://videolan.org"}, {"Name": "PotPlayer", "Id": "Daum.PotPlayer", "Desc": "Advanced Video Player", "Url": "https://potplayer.daum.net"}, {"Name": "MPC-HC", "Id": "clsid2.mpc-hc", "Desc": "Lightweight Video Player", "Url": "https://github.com/clsid2/mpc-hc"}, {"Name": "OBS Studio", "Id": "OBSProject.OBSStudio", "Desc": "Streaming Software", "Url": "https://obsproject.com"}, {"Name": "Audacity", "Id": "Audacity.Audacity", "Desc": "Audio Editor", "Url": "https://audacityteam.org"}, {"Name": "Spotify", "Id": "Spotify.Spotify", "Desc": "Music Streaming", "Url": "https://spotify.com"}, {"Name": "iTunes", "Id": "Apple.iTunes", "Desc": "Apple Media Player", "Url": "https://apple.com/itunes"}, {"Name": "Steam", "Id": "Valve.Steam", "Desc": "Gaming Platform", "Url": "https://store.steampowered.com"}, {"Name": "Epic Games", "Id": "EpicGames.EpicGamesLauncher", "Desc": "Game Store", "Url": "https://epicgames.com"}, {"Name": "GOG Galaxy", "Id": "GOG.Galaxy", "Desc": "DRM-free Games", "Url": "https://gog.com/galaxy"}, {"Name": "Ubisoft Connect", "Id": "Ubisoft.Connect", "Desc": "Ubisoft Games", "Url": "https://ubisoftconnect.com"}, {"Name": "EA App", "Id": "ElectronicArts.EADesktop", "Desc": "EA Games Client", "Url": "https://ea.com"}, {"Name": "ImageGlass", "Id": "ImageGlass.ImageGlass", "Desc": "Fast & Modern Photo Viewer", "Url": "https://imageglass.org"}, {"Name": "LosslessCut", "Id": "mifi.LosslessCut", "Desc": "Cut videos without re-encoding", "Url": "https://github.com/mifi/lossless-cut"}, {"Name": "SteelSeries GG", "Id": "SteelSeries.GG", "Desc": "Audio and Peripheral Driver", "Url": "https://steelseries.gg"}, {"Name": "Logitech G Hub", "Id": "Logitech.GHub", "Desc": "Logitech Gear Driver", "Url": "https://logitechg.com"}, {"Name": "Razer Synapse", "Id": "Razer.Synapse", "Desc": "Razer Gear Driver", "Url": "https://razer.com"}, {"Name": "EarTrumpet", "Id": "File-New-Project.EarTrumpet", "Desc": "Advanced Volume Control", "Url": "https://eartrumpet.app"}], "Runtimes (Essential)": [{"Name": ".NET 6 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.6", "Desc": "Required for many apps", "Url": "https://dotnet.microsoft.com"}, {"Name": ".NET 7 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.7", "Desc": "Required for newer apps", "Url": "https://dotnet.microsoft.com"}, {"Name": ".NET 8 Desktop", "Id": "Microsoft.DotNet.DesktopRuntime.8", "Desc": "Latest LTS Runtime", "Url": "https://dotnet.microsoft.com"}, {"Name": "VC++ Redist 2015-2022", "Id": "Microsoft.VCRedist.2015+.x64", "Desc": "Critical for games/apps", "Url": "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist"}, {"Name": "Java Runtime (JRE)", "Id": "Oracle.JavaRuntimeEnvironment", "Desc": "Java applications runner", "Url": "https://java.com"}, {"Name": "DirectX Web Runtime", "Id": "Microsoft.DirectX", "Desc": "Older Game Support", "Url": "https://microsoft.com/download/details.aspx?id=35"}]}
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

function Show-Page {
    param([string]$PageName)
    $script:pageInstall.Visibility = "Collapsed"
    $script:pageTweaks.Visibility  = "Collapsed"
    $script:pageConfig.Visibility  = "Collapsed"
    $script:pageDebloat.Visibility = "Collapsed"
    $script:pageUpdates.Visibility = "Collapsed"
    if ($script:pageBackup) { $script:pageBackup.Visibility = "Collapsed" }
    if ($script:pageWinget) { $script:pageWinget.Visibility = "Collapsed" }
    
    $script:btnMenuInstall.Tag = $null
    $script:btnMenuTweaks.Tag  = $null
    $script:btnMenuConfig.Tag  = $null
    $script:btnMenuDebloat.Tag = $null
    $script:btnMenuUpdates.Tag = $null
    if ($script:btnMenuBackup) { $script:btnMenuBackup.Tag = $null }
    if ($script:btnMenuWinget) { $script:btnMenuWinget.Tag = $null }

    switch ($PageName) {
        "install" { $script:pageInstall.Visibility = "Visible"; $script:btnMenuInstall.Tag = "Active" }
        "winget"  { if ($script:pageWinget) { $script:pageWinget.Visibility = "Visible" }; if ($script:btnMenuWinget) { $script:btnMenuWinget.Tag = "Active" } }
        "tweaks"  { $script:pageTweaks.Visibility  = "Visible"; $script:btnMenuTweaks.Tag  = "Active" }
        "config"  { $script:pageConfig.Visibility  = "Visible"; $script:btnMenuConfig.Tag  = "Active" }
        "debloat" { $script:pageDebloat.Visibility = "Visible"; $script:btnMenuDebloat.Tag = "Active" }
        "updates" { $script:pageUpdates.Visibility = "Visible"; $script:btnMenuUpdates.Tag = "Active" }
        "backup"  { if ($script:pageBackup) { $script:pageBackup.Visibility = "Visible" }; if ($script:btnMenuBackup) { $script:btnMenuBackup.Tag = "Active" } }
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

function Start-StreamingCommand {
    param([string]$FileName, [string]$Arguments)
    
    $script:outputBox.Text = ""
    
    $syncHash = [hashtable]::Synchronized(@{
        Window = $script:window
        OutputBox = $script:outputBox
    })
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    
    [void]$ps.AddScript({
        param($FN, $Args, $SH)
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $FN
            $psi.Arguments = $Args
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null
            
            while (-not $proc.StandardOutput.EndOfStream) {
                $line = $proc.StandardOutput.ReadLine()
                if ($null -ne $line) {
                    try { $SH.Window.Dispatcher.Invoke([action]{ $SH.OutputBox.AppendText("$line`r`n"); $SH.OutputBox.ScrollToEnd() }) } catch {}
                }
            }
            $errOut = $proc.StandardError.ReadToEnd()
            if ($errOut) { try { $SH.Window.Dispatcher.Invoke([action]{ $SH.OutputBox.AppendText($errOut) }) } catch {} }
            $proc.WaitForExit()
        } catch {
            $msg = $_.Exception.Message
            try { $SH.Window.Dispatcher.Invoke([action]{ $SH.OutputBox.AppendText("ERROR: $msg`r`n") }) } catch {}
        }
        try { $SH.Window.Dispatcher.Invoke([action]{ $SH.OutputBox.AppendText("`r`n--- PROCESS COMPLETED ---`r`n"); $SH.OutputBox.ScrollToEnd() }) } catch {}
    })
    [void]$ps.AddParameter("FN", $FileName)
    [void]$ps.AddParameter("Args", $Arguments)
    [void]$ps.AddParameter("SH", $syncHash)
    
    $handle = $ps.BeginInvoke()
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            try { $ps.EndInvoke($handle) } catch {}
            $ps.Dispose()
            $runspace.Close()
        }
    }.GetNewClosure())
    $timer.Start()
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
$btnMenuInstall.Add_Click({ Show-Page "install" })
if ($btnMenuWinget) { $btnMenuWinget.Add_Click({ Show-Page "winget" }) }
$btnMenuTweaks.Add_Click({ Show-Page "tweaks" })
$btnMenuConfig.Add_Click({ Show-Page "config" })
$btnMenuDebloat.Add_Click({ Show-Page "debloat" })
$btnMenuUpdates.Add_Click({ Show-Page "updates" })
if ($btnMenuBackup) { $btnMenuBackup.Add_Click({ Show-Page "backup" }) }
$btnExit.Add_Click({ $window.Close() })
$btnClearLog.Add_Click({ $logBox.Clear() })

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
                    $targetUrl = $app.Url
                    $urlBtn.Add_Click({
                        try { [System.Diagnostics.Process]::Start($targetUrl) } catch {}
                    }.GetNewClosure())
                    [void]$cbContent.Children.Add($urlBtn)
                }

                $cb.Content = $cbContent
                $card.Child = $cb
                
                # Hover effect on card
                $card.Add_MouseEnter({ $this.Background = $hoverBrush }.GetNewClosure())
                $card.Add_MouseLeave({ $this.Background = $surfaceBrush }.GetNewClosure())
                
                # Selection border highlight
                $currentCard = $card
                $cb.Add_Checked({ $currentCard.BorderBrush = $accentBrush }.GetNewClosure())
                $cb.Add_Unchecked({ $currentCard.BorderBrush = $borderBrush }.GetNewClosure())
                
                [void]$wrapPanel.Children.Add($card)
                [void]$script:InstallList.Add(@{Check=$cb; Id=$app.Id; Name=$app.Name; Card=$card; WrapPanel=$wrapPanel})
            }
            [void]$appContainer.Children.Add($wrapPanel)
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

# Search
$searchBox.Add_TextChanged({
    $query = $searchBox.Text.ToLower()
    $searchPlaceholder.Visibility = if ($query.Length -gt 0) { "Collapsed" } else { "Visible" }
    foreach ($item in $script:InstallList) {
        $visible = ($query.Length -eq 0) -or ($item.Name.ToLower().Contains($query))
        $item.Card.Visibility = if ($visible) { "Visible" } else { "Collapsed" }
    }
})

# INSTALL (Async with Runspace)
$btnInstall.Add_Click({
    if (-not (Test-WingetAvailable)) { return }
    
    $selected = @($script:InstallList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No applications selected.", "Info", "OK", "Information")
        return
    }
    
    $script:btnInstall.IsEnabled = $false
    $script:btnUninstall.IsEnabled = $false
    $script:progressPanel.Visibility = "Visible"
    $script:progressBar.Value = 0
    
    $appsData = @()
    foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }
    
    $syncHash = [hashtable]::Synchronized(@{
        Window = $window; ProgressBar = $progressBar; ProgressText = $progressText
        LogBox = $logBox; Total = $appsData.Count
    })
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    
    [void]$ps.AddScript({
        param($Apps, $SH)
        $current = 0
        foreach ($app in $Apps) {
            $current++
            $n = $app.Name; $id = $app.Id; $t = $SH.Total
            try { $SH.Window.Dispatcher.Invoke([action]{
                $SH.ProgressText.Text = "Installing: $n ($current / $t)"
                $SH.ProgressBar.Value = [math]::Round(($current / $t) * 100)
            }) } catch {}
            
            try {
                $null = & winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements --force 2>&1 | Out-String
                $code = $LASTEXITCODE
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    if ($code -eq 0 -or $null -eq $code) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Installed: $n`r`n") }
                    elseif ($code -eq -1978335189) { $SH.LogBox.AppendText("[$ts] [INFO] Already installed: $n`r`n") }
                    else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed: $n (Code: $code)`r`n") }
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $msg = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n"); $SH.LogBox.ScrollToEnd() }) } catch {}
            }
        }
        try { $SH.Window.Dispatcher.Invoke([action]{
            $SH.ProgressText.Text = "All installations completed!"
            $SH.ProgressBar.Value = 100
            $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [INFO] Installation cycle complete.`r`n"); $SH.LogBox.ScrollToEnd()
        }) } catch {}
    })
    [void]$ps.AddParameter("Apps", $appsData)
    [void]$ps.AddParameter("SH", $syncHash)
    $handle = $ps.BeginInvoke()
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            try { $ps.EndInvoke($handle) } catch {}
            $ps.Dispose(); $runspace.Close()
            $script:btnInstall.IsEnabled = $true
            $script:btnUninstall.IsEnabled = $true
        }
    }.GetNewClosure())
    $timer.Start()
    Write-AppLog "Installation started for $($appsData.Count) apps..." "ACTION"
})

# UNINSTALL (Async with Runspace)
$btnUninstall.Add_Click({
    if (-not (Test-WingetAvailable)) { return }
    
    $selected = @($script:InstallList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No applications selected.", "Info", "OK", "Information")
        return
    }
    
    $result = [System.Windows.MessageBox]::Show("Selected apps will be REMOVED. Continue?", "Confirm Uninstall", "YesNo", "Warning")
    if ($result -ne "Yes") { return }
    
    $script:btnInstall.IsEnabled = $false
    $script:btnUninstall.IsEnabled = $false
    $script:progressPanel.Visibility = "Visible"
    $script:progressBar.Value = 0
    
    $appsData = @()
    foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }
    
    $syncHash = [hashtable]::Synchronized(@{
        Window = $window; ProgressBar = $progressBar; ProgressText = $progressText
        LogBox = $logBox; Total = $appsData.Count
    })
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    
    [void]$ps.AddScript({
        param($Apps, $SH)
        $current = 0
        foreach ($app in $Apps) {
            $current++
            $n = $app.Name; $id = $app.Id; $t = $SH.Total
            try { $SH.Window.Dispatcher.Invoke([action]{
                $SH.ProgressText.Text = "Uninstalling: $n ($current / $t)"
                $SH.ProgressBar.Value = [math]::Round(($current / $t) * 100)
            }) } catch {}
            
            try {
                $null = & winget uninstall --id $id -e --silent --accept-source-agreements --force 2>&1 | Out-String
                $code = $LASTEXITCODE
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    if ($code -eq 0 -or $null -eq $code) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Uninstalled: $n`r`n") }
                    else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed to uninstall: $n (Code: $code)`r`n") }
                    $SH.LogBox.ScrollToEnd()
                }) } catch {}
            } catch {
                $msg = $_.Exception.Message
                try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n"); $SH.LogBox.ScrollToEnd() }) } catch {}
            }
        }
        try { $SH.Window.Dispatcher.Invoke([action]{
            $SH.ProgressText.Text = "All uninstallations completed!"
            $SH.ProgressBar.Value = 100
            $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [INFO] Uninstallation cycle complete.`r`n"); $SH.LogBox.ScrollToEnd()
        }) } catch {}
    })
    [void]$ps.AddParameter("Apps", $appsData)
    [void]$ps.AddParameter("SH", $syncHash)
    $handle = $ps.BeginInvoke()
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            try { $ps.EndInvoke($handle) } catch {}
            $ps.Dispose(); $runspace.Close()
            $script:btnInstall.IsEnabled = $true
            $script:btnUninstall.IsEnabled = $true
        }
    }.GetNewClosure())
    $timer.Start()
    Write-AppLog "Uninstallation started for $($appsData.Count) apps..." "WARN"
})

# =============================================================================
# 8. WINGET MANAGER MODULE
# =============================================================================
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

        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Foreground = $textBrush
        $cb.FontSize = 13
        $cb.VerticalContentAlignment = "Top"

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
        $instCardBtn.Padding = [System.Windows.Thickness]::new(0, 4, 0, 4)
        if ($roundedStyle) { $instCardBtn.Style = $roundedStyle }
        [System.Windows.Controls.Grid]::SetColumn($instCardBtn, 0)

        $uninstCardBtn = New-Object System.Windows.Controls.Button
        $uninstCardBtn.Content = "Uninstall"
        $uninstCardBtn.Background = $dangerBrush
        $uninstCardBtn.Foreground = [System.Windows.Media.Brushes]::White
        $uninstCardBtn.FontSize = 11
        $uninstCardBtn.Padding = [System.Windows.Thickness]::new(0, 4, 0, 4)
        if ($roundedStyle) { $uninstCardBtn.Style = $roundedStyle }
        [System.Windows.Controls.Grid]::SetColumn($uninstCardBtn, 2)

        [void]$btnGrid.Children.Add($instCardBtn)
        [void]$btnGrid.Children.Add($uninstCardBtn)
        [void]$cbContent.Children.Add($btnGrid)

        $targetPkgId = $item.Id
        $targetPkgName = $item.Name

        $instCardBtn.Add_Click({
            if (-not (Test-WingetAvailable)) { return }
            Write-AppLog "Installing package: $targetPkgName ($targetPkgId)..." "ACTION"
            Start-StreamingCommand "winget" "install --id `"$targetPkgId`" -e --silent --accept-package-agreements --accept-source-agreements --force"
        }.GetNewClosure())

        $uninstCardBtn.Add_Click({
            if (-not (Test-WingetAvailable)) { return }
            Write-AppLog "Uninstalling package: $targetPkgName ($targetPkgId)..." "WARN"
            Start-StreamingCommand "winget" "uninstall --id `"$targetPkgId`" -e --silent --accept-source-agreements --force"
        }.GetNewClosure())

        $cb.Content = $cbContent
        $card.Child = $cb

        $card.Add_MouseEnter({ $this.Background = $hoverBrush }.GetNewClosure())
        $card.Add_MouseLeave({ $this.Background = $surfaceBrush }.GetNewClosure())

        $currentCard = $card
        $cb.Add_Checked({ $currentCard.BorderBrush = $accentBrush }.GetNewClosure())
        $cb.Add_Unchecked({ $currentCard.BorderBrush = $borderBrush }.GetNewClosure())

        [void]$wrapPanel.Children.Add($card)
        [void]$script:WingetList.Add(@{Check=$cb; Id=$item.Id; Name=$item.Name; Card=$card})
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
        
        $syncHash = [hashtable]::Synchronized(@{
            Window = $window
            LogBox = $logBox
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($SH)
            $raw = & winget list --accept-source-agreements 2>&1 | Out-String
            $lines = $raw -split "`r?`n"
            $start = $false
            $installed = @()
            foreach ($l in $lines) {
                if ($l -like "*---*") { $start = $true; continue }
                if ($start -and $l.Trim().Length -gt 0) {
                    $parts = $l -split '\s{2,}'
                    if ($parts.Count -ge 2) {
                        $installed += @{
                            Name = $parts[0].Trim()
                            Id = $parts[1].Trim()
                            Version = if ($parts.Count -gt 2) { $parts[2].Trim() } else { "" }
                            Source = if ($parts.Count -gt 3) { $parts[3].Trim() } else { "" }
                        }
                    }
                }
            }
            return $installed
        })
        [void]$ps.AddParameter("SH", $syncHash)
        $handle = $ps.BeginInvoke()

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                $results = try { $ps.EndInvoke($handle) } catch { @() }
                $ps.Dispose(); $runspace.Close()
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                Render-WingetCards $results
                Write-AppLog "Winget Scan complete: $($results.Count) packages found." "SUCCESS"
            }
        }.GetNewClosure())
        $timer.Start()
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

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Q)
            $raw = & winget search "$Q" --accept-source-agreements 2>&1 | Out-String
            $lines = $raw -split "`r?`n"
            $start = $false
            $results = @()
            foreach ($l in $lines) {
                if ($l -like "*---*") { $start = $true; continue }
                if ($start -and $l.Trim().Length -gt 0) {
                    $parts = $l -split '\s{2,}'
                    if ($parts.Count -ge 2) {
                        $results += @{
                            Name = $parts[0].Trim()
                            Id = $parts[1].Trim()
                            Version = if ($parts.Count -gt 2) { $parts[2].Trim() } else { "" }
                            Source = if ($parts.Count -gt 3) { $parts[3].Trim() } else { "" }
                        }
                    }
                }
            }
            return $results
        })
        [void]$ps.AddParameter("Q", $query)
        $handle = $ps.BeginInvoke()

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                $results = try { $ps.EndInvoke($handle) } catch { @() }
                $ps.Dispose(); $runspace.Close()
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                Render-WingetCards $results
                Write-AppLog "Winget Online Search complete: $($results.Count) matching packages found." "SUCCESS"
            }
        }.GetNewClosure())
        $timer.Start()
    })
}

# Install Selected Packages from Winget List
if ($btnInstallSelectedWinget) {
    $btnInstallSelectedWinget.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $selected = @($script:WingetList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No packages selected from the list.", "Info", "OK", "Information")
            return
        }

        Write-AppLog "Installing $($selected.Count) selected Winget packages..." "ACTION"
        $appsData = @()
        foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }

        $syncHash = [hashtable]::Synchronized(@{
            Window = $window; LogBox = $logBox; Total = $appsData.Count
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Apps, $SH)
            foreach ($app in $Apps) {
                $n = $app.Name; $id = $app.Id
                try {
                    $null = & winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements --force 2>&1 | Out-String
                    $code = $LASTEXITCODE
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        if ($code -eq 0 -or $null -eq $code) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Installed Winget Package: $n ($id)`r`n") }
                        else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed to install: $n (Code: $code)`r`n") }
                        $SH.LogBox.ScrollToEnd()
                    }) } catch {}
                } catch {
                    $msg = $_.Exception.Message
                    try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n"); $SH.LogBox.ScrollToEnd() }) } catch {}
                }
            }
        })
        [void]$ps.AddParameter("Apps", $appsData)
        [void]$ps.AddParameter("SH", $syncHash)
        $handle = $ps.BeginInvoke()

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                try { $ps.EndInvoke($handle) } catch {}
                $ps.Dispose(); $runspace.Close()
                Write-AppLog "Winget Package Installation Cycle Complete." "INFO"
            }
        }.GetNewClosure())
        $timer.Start()
    })
}

# Remove Selected Installed Packages
if ($btnRemoveSelectedWinget) {
    $btnRemoveSelectedWinget.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $selected = @($script:WingetList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No packages selected from the list.", "Info", "OK", "Information")
            return
        }

        $result = [System.Windows.MessageBox]::Show("Selected $($selected.Count) packages will be UNINSTALLED from Windows. Continue?", "Confirm Uninstall", "YesNo", "Warning")
        if ($result -ne "Yes") { return }

        Write-AppLog "Uninstalling $($selected.Count) selected Winget packages..." "WARN"
        $appsData = @()
        foreach ($s in $selected) { $appsData += @{Id=$s.Id; Name=$s.Name} }

        $syncHash = [hashtable]::Synchronized(@{
            Window = $window; LogBox = $logBox; Total = $appsData.Count
        })

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        [void]$ps.AddScript({
            param($Apps, $SH)
            foreach ($app in $Apps) {
                $n = $app.Name; $id = $app.Id
                try {
                    $null = & winget uninstall --id $id -e --silent --accept-source-agreements --force 2>&1 | Out-String
                    $code = $LASTEXITCODE
                    try { $SH.Window.Dispatcher.Invoke([action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        if ($code -eq 0 -or $null -eq $code) { $SH.LogBox.AppendText("[$ts] [SUCCESS] Uninstalled Winget Package: $n ($id)`r`n") }
                        else { $SH.LogBox.AppendText("[$ts] [ERROR] Failed to uninstall: $n (Code: $code)`r`n") }
                        $SH.LogBox.ScrollToEnd()
                    }) } catch {}
                } catch {
                    $msg = $_.Exception.Message
                    try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $n - $msg`r`n"); $SH.LogBox.ScrollToEnd() }) } catch {}
                }
            }
        })
        [void]$ps.AddParameter("Apps", $appsData)
        [void]$ps.AddParameter("SH", $syncHash)
        $handle = $ps.BeginInvoke()

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                try { $ps.EndInvoke($handle) } catch {}
                $ps.Dispose(); $runspace.Close()
                Write-AppLog "Winget Package Removal Cycle Complete." "INFO"
            }
        }.GetNewClosure())
        $timer.Start()
    })
}

# Install / Add Custom Package By ID
if ($btnAddCustomWingetApp) {
    $btnAddCustomWingetApp.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $pkgId = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Winget Package ID (e.g. Google.Chrome or Python.Python.3):", "Install Package by ID", "")
        if ([string]::IsNullOrWhiteSpace($pkgId)) { return }

        $result = [System.Windows.MessageBox]::Show("Install package '$pkgId' now?", "Confirm Install", "YesNo", "Question")
        if ($result -eq "Yes") {
            Write-AppLog "Installing custom package ID: $pkgId..." "ACTION"
            Start-StreamingCommand "winget" "install --id `"$pkgId`" -e --silent --accept-package-agreements --accept-source-agreements --force"
        }
    })
}

# Export Custom List
if ($btnExportWingetCustom) {
    $btnExportWingetCustom.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "JSON Files (*.json)|*.json|Text Files (*.txt)|*.txt"
        $sfd.FileName = "Winget_Manager_List_$(Get-Date -Format 'yyyyMMdd').json"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $exportData = @($script:WingetList | ForEach-Object { @{ Name=$_.Name; Id=$_.Id } })
                $jsonStr = $exportData | ConvertTo-Json -Depth 3
                Set-Content -Path $sfd.FileName -Value $jsonStr -Encoding UTF8
                Write-AppLog "Winget list exported to: $($sfd.FileName)" "SUCCESS"
                [System.Windows.MessageBox]::Show("List exported successfully!", "Export Done", "OK", "Information")
            } catch {
                Write-AppLog "Export failed: $($_.Exception.Message)" "ERROR"
            }
        }
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
        [void]$script:TweakList.Add(@{Check=$cb; Do=$t.Do; Undo=$t.Undo; Name=$t.Name; Tag=$t.Tag})
    }
    
    $group.Child = $innerStack
    [void]$tweaksContainer.Children.Add($group)
}

$essentialTweaks = @(
    @{Name="Create Restore Point"; Tag="Essential"; 
      Do={ Checkpoint-Computer -Description "VDOWNSPrimeRestore" -RestorePointType "MODIFY_SETTINGS" }; 
      Undo={ Write-Host "Restore points cannot be deleted from here." } },
    @{Name="Run OO ShutUp10"; Tag="Essential"; 
      Do={ $url="https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"; Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\OOSU10.exe"; Start-Process "$env:TEMP\OOSU10.exe" }; 
      Undo={ Write-Host "Open O&O ShutUp10 manually to revert." } },
    @{Name="Disable Telemetry"; Tag="Essential"; 
      Do={ Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue; Stop-Service DiagTrack -EA SilentlyContinue }; 
      Undo={ Set-Service DiagTrack -StartupType Automatic; Start-Service DiagTrack } },
    @{Name="Disable Ad ID"; Tag="Essential"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 1 } }
)

$uiTweaks = @(
    @{Name="Dark Mode (System)"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1 } },
    @{Name="Dark Mode (Apps)"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1 } },
    @{Name="Show Hidden Files"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 2 } },
    @{Name="Show File Extensions"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 1 } },
    @{Name="Launch to 'This PC'"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 2 } },
    @{Name="Classic Context Menu"; Tag="UI"; 
      Do={ reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve 2>$null }; 
      Undo={ reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>$null } },
    @{Name="Align Taskbar Left"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1 } },
    @{Name="Hide Search Icon"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 } },
    @{Name="Clipboard History"; Tag="UI"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" "EnableClipboardHistory" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" "EnableClipboardHistory" 0 } }
)

$perfTweaks = @(
    @{Name="Disable Sticky Keys"; Tag="Power"; 
      Do={ Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" }; 
      Undo={ Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "510" } },
    @{Name="Enable Hibernate"; Tag="Power"; 
      Do={ powercfg /hibernate on }; 
      Undo={ powercfg /hibernate off } },
    @{Name="Storage Sense"; Tag="Power"; 
      Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 1 }; 
      Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0 } },
    @{Name="Ultimate Performance"; Tag="Power"; 
      Do={ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }; 
      Undo={ Write-Host "Go to Power Options to remove the plan." } },
    @{Name="Disable SysMain"; Tag="Power"; 
      Do={ Set-Service SysMain -StartupType Disabled -EA SilentlyContinue; Stop-Service SysMain -EA SilentlyContinue }; 
      Undo={ Set-Service SysMain -StartupType Automatic; Start-Service SysMain } },
    @{Name="Disable Game DVR"; Tag="Power"; 
      Do={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }; 
      Undo={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1 } }
)

Add-TweakGroup "Essential Privacy" $essentialTweaks "#F85149"
Add-TweakGroup "Interface Explorer" $uiTweaks "#58A6FF"
Add-TweakGroup "Performance Power" $perfTweaks "#3FB950"

# Profile buttons
$btnProfileDesktop.Add_Click({ foreach ($t in $script:TweakList) { if ($t.Tag -eq "Essential" -or $t.Tag -eq "UI") { $t.Check.IsChecked = $true } } })
$btnProfileLaptop.Add_Click({ foreach ($t in $script:TweakList) { if ($t.Tag -eq "Power") { $t.Check.IsChecked = $true } } })
$btnResetTweaks.Add_Click({ foreach ($t in $script:TweakList) { $t.Check.IsChecked = $false } })

# Apply Tweaks (Async Runspace to prevent UI freezing)
$btnApplyTweaks.Add_Click({
    $selected = @($script:TweakList | Where-Object { $_.Check.IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected.", "Info", "OK", "Information")
        return
    }

    Write-AppLog "Applying $($selected.Count) selected tweaks asynchronously..." "ACTION"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $btnApplyTweaks.IsEnabled = $false
    $btnRevertTweaks.IsEnabled = $false

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Do.ToString() }
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
        param($Tweaks, $SH)
        $applied = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                & $sBlock
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
    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            $count = try { $ps.EndInvoke($handle) } catch { 0 }
            $ps.Dispose(); $runspace.Close()
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            $btnApplyTweaks.IsEnabled = $true
            $btnRevertTweaks.IsEnabled = $true
            Write-AppLog "Tweak deployment completed ($count applied)." "SUCCESS"
        }
    }.GetNewClosure())
    $timer.Start()
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
    $btnApplyTweaks.IsEnabled = $false
    $btnRevertTweaks.IsEnabled = $false

    $tweakData = @()
    foreach ($t in $selected) {
        $tweakData += @{ Name = $t.Name; ScriptStr = $t.Undo.ToString() }
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
        param($Tweaks, $SH)
        $reverted = 0
        foreach ($item in $Tweaks) {
            $tName = $item.Name
            $sBlock = [scriptblock]::Create($item.ScriptStr)
            try {
                & $sBlock
                $reverted++
                try { $SH.Window.Dispatcher.Invoke([action]{
                    $ts = Get-Date -Format 'HH:mm:ss'
                    $SH.LogBox.AppendText("[$ts] [SUCCESS] Reverted: $tName`r`n")
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
    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            $count = try { $ps.EndInvoke($handle) } catch { 0 }
            $ps.Dispose(); $runspace.Close()
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            $btnApplyTweaks.IsEnabled = $true
            $btnRevertTweaks.IsEnabled = $true
            Write-AppLog "Tweak reversion completed ($count reverted)." "INFO"
        }
    }.GetNewClosure())
    $timer.Start()
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
    
    [void]$configContainer.Children.Add($card)
    [void]$script:FeatureList.Add(@{Check=$cb; WinName=$WinName; Name=$Name})
}

$featHeader = New-Object System.Windows.Controls.TextBlock
$featHeader.Text = "Windows Optional Features"
$featHeader.FontSize = 18
$featHeader.FontWeight = "SemiBold"
$featHeader.Foreground = $accentBrush
$featHeader.Margin = [System.Windows.Thickness]::new(0, 5, 0, 15)
[void]$configContainer.Children.Add($featHeader)

Add-FeatureCard "Hyper-V Platform" "Microsoft-Hyper-V-All" "Hardware virtualization for VMs and Docker"
Add-FeatureCard "WSL 2 (Linux)" "Microsoft-Windows-Subsystem-Linux" "Windows Subsystem for Linux"
Add-FeatureCard "Windows Sandbox" "Containers-DisposableClientVM" "Isolated desktop environment for safe testing"
Add-FeatureCard ".NET Framework 3.5" "NetFx3" "Required by legacy applications and games"

# Maintenance header
$maintHeader = New-Object System.Windows.Controls.TextBlock
$maintHeader.Text = "System Maintenance"
$maintHeader.FontSize = 18
$maintHeader.FontWeight = "SemiBold"
$maintHeader.Foreground = $dangerBrush
$maintHeader.Margin = [System.Windows.Thickness]::new(0, 25, 0, 10)
[void]$configContainer.Children.Add($maintHeader)

$maintDesc = New-Object System.Windows.Controls.TextBlock
$maintDesc.Text = "Deep System Clean configures all cleanup categories and runs the extended Disk Cleanup utility in the background."
$maintDesc.Foreground = $textDimBrush
$maintDesc.FontSize = 13
$maintDesc.TextWrapping = "Wrap"
$maintDesc.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
[void]$configContainer.Children.Add($maintDesc)

$btnEnableFeatures.Add_Click({
    Write-AppLog "Enabling features..." "ACTION"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    foreach ($f in $script:FeatureList) {
        if ($f.Check.IsChecked) {
            try {
                Write-AppLog "Enabling: $($f.Name)..." "INFO"
                Enable-WindowsOptionalFeature -Online -FeatureName $f.WinName -All -NoRestart -ErrorAction Stop
                Write-AppLog "Enabled: $($f.Name)" "SUCCESS"
            } catch { Write-AppLog "Failed: $($f.Name) - $($_.Exception.Message)" "ERROR" }
        }
    }
    $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    Write-AppLog "Feature changes may require a RESTART." "WARN"
})

$btnDisableFeatures.Add_Click({
    Write-AppLog "Disabling features..." "WARN"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    foreach ($f in $script:FeatureList) {
        if ($f.Check.IsChecked) {
            try {
                Write-AppLog "Disabling: $($f.Name)..." "INFO"
                Disable-WindowsOptionalFeature -Online -FeatureName $f.WinName -NoRestart -ErrorAction Stop
                Write-AppLog "Disabled: $($f.Name)" "SUCCESS"
            } catch { Write-AppLog "Failed: $($f.Name) - $($_.Exception.Message)" "ERROR" }
        }
    }
    $window.Cursor = [System.Windows.Input.Cursors]::Arrow
})

$btnDeepClean.Add_Click({
    $result = [System.Windows.MessageBox]::Show("This will run a deep system cleanup.`nContinue?", "Confirm", "YesNo", "Warning")
    if ($result -ne "Yes") { return }
    Write-AppLog "Starting Deep System Clean..." "ACTION"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        Get-ChildItem $regPath | ForEach-Object { New-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -PropertyType DWORD -Force | Out-Null }
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden
        Write-AppLog "Deep Clean started in background." "SUCCESS"
    } catch { Write-AppLog "Clean Error: $($_.Exception.Message)" "ERROR" }
})

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
    
    $card.Add_MouseEnter({ $this.Background = $hoverBrush }.GetNewClosure())
    $card.Add_MouseLeave({ $this.Background = $surfaceBrush }.GetNewClosure())
    
    [void]$debloatContainer.Children.Add($card)
    [void]$script:DebloatList.Add(@{Check=$cb; Pat=$patterns; Name=$k})
}

$btnSelectAll.Add_Click({ foreach ($i in $script:DebloatList) { $i.Check.IsChecked = $true } })
$btnDeselectAll.Add_Click({ foreach ($i in $script:DebloatList) { $i.Check.IsChecked = $false } })

$btnDebloat.Add_Click({
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
    $btnDebloat.IsEnabled = $false

    $debloatData = @()
    foreach ($item in $selected) {
        $debloatData += @{ Name = $item.Name; Patterns = $item.Pat }
    }

    $syncHash = [hashtable]::Synchronized(@{
        Window = $window
        LogBox = $logBox
        BtnDebloat = $btnDebloat
    })

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($Items, $SH)
        $removedCount = 0
        foreach ($item in $Items) {
            foreach ($p in $item.Patterns) {
                try {
                    $pkgs = Get-AppxPackage | Where-Object { $_.Name -like $p }
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
            }
        }
        return $removedCount
    })
    [void]$ps.AddParameter("Items", $debloatData)
    [void]$ps.AddParameter("SH", $syncHash)
    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            $totalRemoved = try { $ps.EndInvoke($handle) } catch { 0 }
            $ps.Dispose(); $runspace.Close()
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            $btnDebloat.IsEnabled = $true
            Write-AppLog "Debloat sequence completed ($totalRemoved packages removed)!" "SUCCESS"
            [System.Windows.MessageBox]::Show("Cleanup operation complete! Total removed: $totalRemoved packages.", "Done", "OK", "Information")
        }
    }.GetNewClosure())
    $timer.Start()
})

# =============================================================================
# 12. UPDATE & REPAIR CENTER
# =============================================================================
$btnUpdateApps.Add_Click({
    Write-AppLog "Starting: Update All Apps..." "ACTION"
    Start-StreamingCommand "winget" "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
})

$btnUpdateWindows.Add_Click({
    Write-AppLog "Starting: Windows Update..." "ACTION"
    Start-PSStreamingCommand 'if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -Confirm:$false }; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -Verbose'
})

$btnUpdateDrivers.Add_Click({
    Write-AppLog "Starting: Driver Updates..." "ACTION"
    Start-PSStreamingCommand 'if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -Confirm:$false }; Import-Module PSWindowsUpdate; Get-WindowsUpdate -Category "Drivers" -AcceptAll -Install -IgnoreReboot -Verbose'
})

$btnUpdateStore.Add_Click({
    Write-AppLog "Starting: MS Store Updates..." "ACTION"
    Start-StreamingCommand "winget" "upgrade --all --accept-package-agreements --accept-source-agreements --source msstore --include-unknown"
})

$btnSfc.Add_Click({
    Write-AppLog "Starting: SFC Scan..." "ACTION"
    Start-StreamingCommand "sfc" "/scannow"
})

$btnDism.Add_Click({
    Write-AppLog "Starting: DISM Repair..." "ACTION"
    Start-StreamingCommand "dism" "/Online /Cleanup-Image /RestoreHealth"
})

$btnNetReset.Add_Click({
    Write-AppLog "Starting: Network Reset..." "ACTION"
    Start-PSStreamingCommand 'ipconfig /flushdns; netsh winsock reset; netsh int ip reset; Write-Host "Network stack reset complete. Restart may be required."'
})

$btnFixWU.Add_Click({
    $result = [System.Windows.MessageBox]::Show("This will forcibly reset Windows Update components.`nContinue?", "Emergency WU Fix", "YesNo", "Warning")
    if ($result -ne "Yes") { return }
    Write-AppLog "Starting: Emergency WU Fix..." "WARN"
    Start-PSStreamingCommand 'Stop-Service wuauserv -Force; Stop-Service cryptSvc -Force; Stop-Service bits -Force; Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue; Start-Service wuauserv; Start-Service bits; Write-Host "Windows Update services reset complete."'
})

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
                $selectedTweaks = @($script:TweakList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                $selectedDebloat = @($script:DebloatList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                
                $appsLines = ($selectedApps | ForEach-Object { "    `"$_`"" }) -join "`r`n"
                $tweaksLines = ($selectedTweaks | ForEach-Object { "    `"$_`"" }) -join "`r`n"
                $debloatLines = ($selectedDebloat | ForEach-Object { "    `"$_`"" }) -join "`r`n"

                $scriptContent = @"
<#
.SYNOPSIS
    VDOWNS PRIME v3.3.0 - Automated Standalone Unattended Deployment Script
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
    winget install --id `$appId --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
}

# 3. System Tweaks Execution
Write-Host "`n[3/4] Applying System Tweaks..." -ForegroundColor Yellow
`$tweaksToApply = @(
$tweaksLines
)
if (`$tweaksToApply -contains "Dark Mode (System)") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
}
if (`$tweaksToApply -contains "Dark Mode (Apps)") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
}
if (`$tweaksToApply -contains "Disable Telemetry") {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
    Stop-Service -Name "DiagTrack" -Force -EA SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -EA SilentlyContinue
}
if (`$tweaksToApply -contains "Show Hidden Files") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force -EA SilentlyContinue
}
if (`$tweaksToApply -contains "Show File Extensions") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force -EA SilentlyContinue
}
if (`$tweaksToApply -contains "Classic Context Menu") {
    reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
}
if (`$tweaksToApply -contains "Ultimate Performance") {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
}

# 4. Debloater Execution
Write-Host "`n[4/4] Removing Selected Bloatware Packages..." -ForegroundColor Yellow
`$debloatTargets = @(
$debloatLines
)
foreach (`$pkg in `$debloatTargets) {
    Write-Host "Purging bloatware package: `$pkg" -ForegroundColor Cyan
    Get-AppxPackage -AllUsers "*`$pkg*" -EA SilentlyContinue | Remove-AppxPackage -AllUsers -EA SilentlyContinue
}

# Explorer Refresh
Stop-Process -Name explorer -Force -EA SilentlyContinue
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

        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
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
                        & code --list-extensions > (Join-Path $tempDir "vscode_extensions.txt")
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

                # 4. PowerShell Profile
                if (Test-Path $PROFILE) {
                    Copy-Item $PROFILE -Destination (Join-Path $tempDir "Microsoft.PowerShell_profile.ps1") -Force -EA SilentlyContinue
                    Log-Msg "Backed up PowerShell profile." "INFO"
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
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                try { $ps.EndInvoke($handle) } catch {}
                $ps.Dispose()
                $runspace.Close()
            }
        })
        $timer.Start()
    })
}

# Restore AppData Configurations (.zip) (Asynchronous Runspace)
if ($btnRestoreConfig) {
    $btnRestoreConfig.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Zip Files (*.zip)|*.zip"
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $srcZip = $ofd.FileName

        Write-AppLog "Restoring AppData Configuration Backup in background..." "WARN"
        $btnRestoreConfig.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("srcZip", $srcZip)
        $runspace.SessionStateProxy.SetVariable("btnRestoreConfig", $btnRestoreConfig)

        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
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
                Expand-Archive -Path $srcZip -DestinationPath $tempDir -Force

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

                # Restore PowerShell Profile
                if (Test-Path "$tempDir\Microsoft.PowerShell_profile.ps1") {
                    $psDir = Split-Path $PROFILE -Parent
                    New-Item -ItemType Directory -Path $psDir -Force | Out-Null
                    Copy-Item "$tempDir\Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
                    Log-Msg "Restored PowerShell profile." "SUCCESS"
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
                            & code --install-extension $ext --force 2>$null
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
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                try { $ps.EndInvoke($handle) } catch {}
                $ps.Dispose()
                $runspace.Close()
            }
        })
        $timer.Start()
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

    # 5. Restore Point Check
    try {
        $rp = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Select-Object -Last 1
        if (-not $rp) {
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
        if ($res -ne [System.Windows.Forms.DialogResult]::Yes -and $res -ne "Yes") { return }

        Write-AppLog "Executing 1-Click Prime Optimization pipeline..." "ACTION"
        $btnPrimeBoost.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("btnPrimeBoost", $btnPrimeBoost)

        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
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

                Log-Msg "Prime 1-Click Optimization successfully applied!" "SUCCESS"
            } catch {
                Log-Msg "Optimization error: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnPrimeBoost) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnPrimeBoost.IsEnabled = $true
                        Update-HealthScoreUI
                        [System.Windows.MessageBox]::Show("Prime Optimization completed successfully!`nSystem score updated.", "Optimization Complete", "OK", "Information")
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Add_Tick({
            if ($handle.IsCompleted) {
                $timer.Stop()
                try { $ps.EndInvoke($handle) } catch {}
                $ps.Dispose()
                $runspace.Close()
            }
        })
        $timer.Start()
    })
}

# =============================================================================
# 13C. DNS OPTIMIZER & LATENCY BENCHMARK
# =============================================================================
function Get-ActivePhysicalAdapter {
    return Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Virtual|Hyper-V|Loopback|WSL|VPN|TAP|PANGP" } | Select-Object -First 1
}

$script:DnsProviders = [ordered]@{
    "Cloudflare (1.1.1.1 / 1.0.0.1) - Privacy & Low Latency" = @("1.1.1.1", "1.0.0.1")
    "Google Public DNS (8.8.8.8 / 8.8.4.4) - Fast & Reliable" = @("8.8.8.8", "8.8.4.4")
    "AdGuard DNS (94.140.14.14 / 94.140.15.15) - Ad & Tracker Block" = @("94.140.14.14", "94.140.15.15")
    "Quad9 (9.9.9.9 / 149.112.112.112) - Malware Threat Protection" = @("9.9.9.9", "149.112.112.112")
}

if ($cbDnsProvider) {
    $cbDnsProvider.Items.Clear()
    foreach ($k in $script:DnsProviders.Keys) { [void]$cbDnsProvider.Items.Add($k) }
    $cbDnsProvider.SelectedIndex = 0
}

try {
    $actAdapter = Get-ActivePhysicalAdapter
    if ($actAdapter -and $lblActiveDnsAdapter) {
        $lblActiveDnsAdapter.Text = "Active: $($actAdapter.Name) ($($actAdapter.InterfaceDescription))"
    }
} catch {}

if ($btnApplyDns) {
    $btnApplyDns.Add_Click({
        $adapter = Get-ActivePhysicalAdapter
        if (-not $adapter) {
            Write-AppLog "No active physical network adapter detected." "ERROR"
            return
        }
        $selectedKey = $cbDnsProvider.SelectedItem
        $servers = $script:DnsProviders[$selectedKey]
        if ($servers) {
            Write-AppLog "Applying DNS $($servers -join ', ') to adapter '$($adapter.Name)'..." "ACTION"
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers -ErrorAction SilentlyContinue
            Clear-DnsClientCache
            Write-AppLog "DNS successfully set to $selectedKey." "SUCCESS"
            [System.Windows.MessageBox]::Show("DNS updated to:`n$($servers -join ', ')`nAdapter: $($adapter.Name)", "DNS Updated", "OK", "Information")
        }
    })
}

if ($btnResetDns) {
    $btnResetDns.Add_Click({
        $adapter = Get-ActivePhysicalAdapter
        if (-not $adapter) { return }
        Write-AppLog "Resetting DNS on adapter '$($adapter.Name)' to DHCP..." "ACTION"
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        Clear-DnsClientCache
        Write-AppLog "DNS reset to automatic DHCP." "SUCCESS"
        [System.Windows.MessageBox]::Show("DNS reset to DHCP (automatic) on adapter $($adapter.Name)", "DNS Reset", "OK", "Information")
    })
}

if ($btnPingDns) {
    $btnPingDns.Add_Click({
        Write-AppLog "Starting DNS Latency Benchmark (Ping)..." "ACTION"
        $targets = @(
            @{ Name = "Cloudflare"; IP = "1.1.1.1" },
            @{ Name = "Google"; IP = "8.8.8.8" },
            @{ Name = "Quad9"; IP = "9.9.9.9" },
            @{ Name = "AdGuard"; IP = "94.140.14.14" }
        )
        foreach ($t in $targets) {
            try {
                $ping = Test-Connection -ComputerName $t.IP -Count 2 -ErrorAction SilentlyContinue
                if ($ping) {
                    $avgMs = [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 1)
                    Write-AppLog "$($t.Name) ($($t.IP)): $avgMs ms" "INFO"
                } else {
                    Write-AppLog "$($t.Name) ($($t.IP)): Request timed out" "WARN"
                }
            } catch {
                Write-AppLog "$($t.Name): Ping test failed" "WARN"
            }
        }
        Write-AppLog "DNS Latency Benchmark completed." "SUCCESS"
    })
}

# =============================================================================
# 13D. STARTUP PROGRAMS OPTIMIZER
# =============================================================================
$script:StartupItemsList = [System.Collections.ArrayList]::new()

function Scan-StartupPrograms {
    if (-not $startupContainer) { return }
    $startupContainer.Children.Clear()
    $script:StartupItemsList.Clear()
    Write-AppLog "Scanning Windows startup entries..." "INFO"
    
    $paths = @(
        @{ Hive = "HKCU"; Path = "Software\Microsoft\Windows\CurrentVersion\Run"; Disabled = $false },
        @{ Hive = "HKLM"; Path = "Software\Microsoft\Windows\CurrentVersion\Run"; Disabled = $false },
        @{ Hive = "HKCU"; Path = "Software\VDOWNS\DisabledStartup"; Disabled = $true }
    )
    
    foreach ($p in $paths) {
        $regPath = "$($p.Hive):\$($p.Path)"
        if (Test-Path $regPath) {
            $props = (Get-Item -Path $regPath).Property
            foreach ($prop in $props) {
                if ($prop -eq "(default)") { continue }
                $val = (Get-ItemProperty -Path $regPath -Name $prop).$prop
                
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
                $lblN.Text = $prop
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

                if ($p.Disabled) {
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
                [void]$script:StartupItemsList.Add(@{ Check = $cb; Name = $prop; Val = $val; RegPath = $regPath; Disabled = $p.Disabled })
            }
        }
    }
    Write-AppLog "Found $($script:StartupItemsList.Count) startup programs." "SUCCESS"
}

if ($btnScanStartup) { $btnScanStartup.Add_Click({ Scan-StartupPrograms }) }

if ($btnDisableStartup) {
    $btnDisableStartup.Add_Click({
        $disPath = "HKCU:\Software\VDOWNS\DisabledStartup"
        if (-not (Test-Path $disPath)) { New-Item -Path $disPath -Force | Out-Null }
        $count = 0
        foreach ($item in $script:StartupItemsList) {
            if ($item.Check.IsChecked -and -not $item.Disabled) {
                Set-ItemProperty -Path $disPath -Name $item.Name -Value $item.Val -Force
                Remove-ItemProperty -Path $item.RegPath -Name $item.Name -Force -EA SilentlyContinue
                $count++
            }
        }
        Write-AppLog "Disabled $count startup programs (safely preserved in VDOWNS store)." "SUCCESS"
        Scan-StartupPrograms
    })
}

if ($btnEnableStartup) {
    $btnEnableStartup.Add_Click({
        $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $count = 0
        foreach ($item in $script:StartupItemsList) {
            if ($item.Check.IsChecked -and $item.Disabled) {
                Set-ItemProperty -Path $runPath -Name $item.Name -Value $item.Val -Force
                Remove-ItemProperty -Path $item.RegPath -Name $item.Name -Force -EA SilentlyContinue
                $count++
            }
        }
        Write-AppLog "Re-enabled $count startup programs." "SUCCESS"
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
        foreach ($sec in $script:CategorySections) { [void]$cbCat.Items.Add($sec.Name) }
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

            if ($idVal -notmatch '^[a-zA-Z0-9_\-\.]+$') {
                [System.Windows.MessageBox]::Show("Winget ID contains invalid characters. Use alphanumeric, dot or hyphen (e.g. Vendor.App).", "Invalid ID", "OK", "Warning")
                return
            }

            try {
                $jPath = Join-Path $ScriptPath "apps.json"
                $catalog = Get-Content -Path $jPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $newObj = @{ Name = $nameVal; Id = $idVal; Desc = $idVal }
                if (![string]::IsNullOrWhiteSpace($urlVal)) { $newObj["Url"] = $urlVal }

                if ($catalog.$catVal) {
                    $catalog.$catVal += $newObj
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
        if ($res -eq "Yes" -or $res -eq [System.Windows.Forms.DialogResult]::Yes) {
            $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $end = (Get-Date).AddDays(35).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            Set-ItemProperty -Path $wuPath -Name "PauseFeatureUpdatesStartTime" -Value $now -Force -EA SilentlyContinue
            Set-ItemProperty -Path $wuPath -Name "PauseFeatureUpdatesEndTime" -Value $end -Force -EA SilentlyContinue
            Set-ItemProperty -Path $wuPath -Name "PauseQualityUpdatesStartTime" -Value $now -Force -EA SilentlyContinue
            Set-ItemProperty -Path $wuPath -Name "PauseQualityUpdatesEndTime" -Value $end -Force -EA SilentlyContinue
            Set-ItemProperty -Path $wuPath -Name "PauseUpdatesExpiryTime" -Value $end -Force -EA SilentlyContinue
            Write-AppLog "Windows Updates paused for 35 days until: $end" "SUCCESS"
            [System.Windows.MessageBox]::Show("Windows Updates paused until:`n$end", "Updates Paused", "OK", "Information")
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
    $script:logExpanded = $true
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
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $lblOsInfo.Text = ($os.Caption -replace "Microsoft ", "")
} catch {
    $lblOsInfo.Text = "Windows 10/11"
}

$script:telemetryTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:telemetryTimer.Interval = [TimeSpan]::FromSeconds(2.5)
$script:telemetryTimer.Add_Tick({
    try {
        # Memory
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($osInfo) {
            $totalGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 1)
            $freeGB  = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
            $usedGB  = [math]::Round($totalGB - $freeGB, 1)
            $ramPct  = [math]::Min(100, [math]::Max(0, [int](($usedGB / $totalGB) * 100)))
            if ($lblRamPct) { $lblRamPct.Text = "${usedGB}/${totalGB} GB (${ramPct}%)" }
            if ($pbRam) { $pbRam.Value = $ramPct }
        }

        # Disk C:
        $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name -eq "C:\" -and $_.IsReady }
        if ($drives) {
            $d = $drives[0]
            $dFreeGB  = [math]::Round($d.AvailableFreeSpace / 1GB, 1)
            $dTotalGB = [math]::Round($d.TotalSize / 1GB, 1)
            $dUsedGB  = [math]::Round($dTotalGB - $dFreeGB, 1)
            $dPct     = [math]::Min(100, [math]::Max(0, [int](($dUsedGB / $dTotalGB) * 100)))
            if ($lblDiskPct) { $lblDiskPct.Text = "${dFreeGB} GB free" }
            if ($pbDisk) { $pbDisk.Value = $dPct }
        }

        # CPU Load
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu -and $cpu.LoadPercentage -ne $null) {
            $load = [int]$cpu.LoadPercentage
            if ($lblCpuPct) { $lblCpuPct.Text = "${load} %" }
            if ($pbCpu) { $pbCpu.Value = $load }
        }
    } catch {}
})
$script:telemetryTimer.Start()

# Initial logs
Write-AppLog "VDOWNS PRIME v3.3.0 (Fluent UI Edition) initialized." "INFO"
Write-AppLog "Hardware-accelerated WPF subsystem online." "SUCCESS"
try {
    $wv = & winget --version 2>$null
    Write-AppLog "Winget detected: $wv" "INFO"
} catch { Write-AppLog "Winget not found! App Center may not work." "ERROR" }
Update-HealthScoreUI
Write-AppLog "System Architect is ready. Select a category from the sidebar to begin." "SUCCESS"

# 15. SHOW WINDOW
# =============================================================================
$window.ShowDialog() | Out-Null

} catch {
    [System.Windows.MessageBox]::Show(
        "Critical Error Occurred:`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)",
        "VDOWNS PRIME Error", "OK", "Error")
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    # Read-Host removed for noConsole GUI
}
