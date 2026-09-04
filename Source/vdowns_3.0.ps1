<#
.SYNOPSIS
    VDOWNS PRIME v3.1.0 - System Architect (WPF Edition)
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
            Read-Host "Press Enter to exit..."
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
    Title="VDOWNS PRIME v3.1.0 | System Architect"
    Width="1280" Height="780"
    WindowStartupLocation="CenterScreen"
    WindowState="Maximized"
    Background="#0D1117"
    Foreground="#E6EDF3"
    FontFamily="Segoe UI"
    MinWidth="920" MinHeight="640">

    <Window.Resources>

        <!-- SIDEBAR BUTTON -->
        <Style x:Key="SidebarBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#8B949E"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="Transparent" 
                                BorderBrush="Transparent" BorderThickness="3,0,0,0" 
                                Padding="17,12">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#1F2937"/>
                            </Trigger>
                            <Trigger Property="Tag" Value="Active">
                                <Setter TargetName="bd" Property="BorderBrush" Value="#58A6FF"/>
                                <Setter TargetName="bd" Property="Background" Value="#161B22"/>
                                <Setter Property="Foreground" Value="#E6EDF3"/>
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
                                    CornerRadius="6" Padding="{TemplateBinding Padding}"/>
                            <Border x:Name="hoverOverlay" Background="White" CornerRadius="6" Opacity="0"/>
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
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ==================== SIDEBAR ==================== -->
        <Border Grid.Column="0" Background="#0D1117" BorderBrush="#30363D" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Logo -->
                <StackPanel Grid.Row="0" Margin="0,25,0,20" HorizontalAlignment="Center">
                    <TextBlock Text="VDOWNS" FontSize="28" FontWeight="Bold" Foreground="#58A6FF" HorizontalAlignment="Center"/>
                    <TextBlock Text="PRIME V3.1" FontSize="16" FontWeight="SemiBold" Foreground="#484F58" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                    <Border Height="1" Background="#30363D" Margin="20,15,20,0"/>
                </StackPanel>

                <!-- Menu -->
                <StackPanel Grid.Row="1" Margin="0,5,0,0">
                    <Button x:Name="btnMenuInstall" Style="{StaticResource SidebarBtn}" Tag="Active">
                        <TextBlock Text="&#9656;  App Center" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuWinget" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  Winget Manager" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuTweaks" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  System Tweaks" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuConfig" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  Features" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuDebloat" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  Debloater" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuUpdates" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  Updates" FontSize="14"/>
                    </Button>
                    <Button x:Name="btnMenuBackup" Style="{StaticResource SidebarBtn}">
                        <TextBlock Text="&#9656;  Backup &amp; Restore" FontSize="14"/>
                    </Button>
                </StackPanel>

                <!-- System Info -->
                <Border Grid.Row="2" Background="#161B22" CornerRadius="8" Margin="12,5" Padding="12,10">
                    <StackPanel>
                        <TextBlock Text="SYSTEM" FontSize="10" FontWeight="Bold" Foreground="#484F58" Margin="0,0,0,6"/>
                        <TextBlock x:Name="lblOsInfo" Text="Loading..." Foreground="#8B949E" FontSize="11" TextWrapping="Wrap"/>
                        <TextBlock x:Name="lblCpuInfo" Text="" Foreground="#8B949E" FontSize="11" Margin="0,3,0,0" TextWrapping="Wrap" TextTrimming="CharacterEllipsis" MaxHeight="32"/>
                        <TextBlock x:Name="lblRamInfo" Text="" Foreground="#8B949E" FontSize="11" Margin="0,3,0,0"/>
                    </StackPanel>
                </Border>

                <!-- Exit -->
                <Button Grid.Row="3" x:Name="btnExit" Style="{StaticResource SidebarBtn}" Margin="0,5,0,10">
                    <TextBlock Foreground="#F85149" FontWeight="SemiBold" FontSize="14" Text="&#10005;  TERMINATE"/>
                </Button>
            </Grid>
        </Border>

        <!-- ==================== MAIN CONTENT ==================== -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- ===== PAGE: APP CENTER ===== -->
            <Grid x:Name="pageInstall" Grid.Row="0" Margin="25,20,25,15">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,10">
                    <TextBlock Text="App Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Discover, install, and manage applications with instant search and official web links" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <!-- Search and Controls bar -->
                <Grid Grid.Row="1" Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="5"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <Grid Grid.Column="0">
                        <Border Background="#161B22" CornerRadius="6" BorderBrush="#30363D" BorderThickness="1" Padding="2">
                            <TextBox x:Name="searchBox" Background="Transparent" Foreground="#E6EDF3" 
                                     BorderThickness="0" FontSize="14" Padding="10,8" CaretBrush="#E6EDF3"/>
                        </Border>
                        <TextBlock x:Name="searchPlaceholder" Text="  Search applications by name or description..." 
                                   Foreground="#484F58" FontSize="14" VerticalAlignment="Center" 
                                   Margin="14,0" IsHitTestVisible="False"/>
                    </Grid>

                    <Button x:Name="btnAppSelectAll" Grid.Column="2" Content="Select All" 
                            Background="#30363D" Foreground="#E6EDF3" FontSize="12" Padding="12,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnAppDeselectAll" Grid.Column="4" Content="Deselect All" 
                            Background="#30363D" Foreground="#E6EDF3" FontSize="12" Padding="12,8" Style="{StaticResource RoundedBtn}"/>
                </Grid>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel x:Name="appContainer"/>
                </ScrollViewer>

                <Border x:Name="progressPanel" Grid.Row="3" Visibility="Collapsed" 
                        Background="#161B22" CornerRadius="8" Padding="15" Margin="0,10,0,0" 
                        BorderBrush="#30363D" BorderThickness="1">
                    <StackPanel>
                        <TextBlock x:Name="progressText" Text="" Foreground="#E6EDF3" FontSize="14" Margin="0,0,0,8"/>
                        <ProgressBar x:Name="progressBar" Height="8" Minimum="0" Maximum="100" Value="0" 
                                     Foreground="#58A6FF" Background="#30363D" BorderThickness="0"/>
                    </StackPanel>
                </Border>

                <Grid Grid.Row="4" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnInstall" Grid.Column="0" Content="INSTALL SELECTED" 
                            Background="#3FB950" FontSize="16" Padding="0,15" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnUninstall" Grid.Column="2" Content="UNINSTALL SELECTED" 
                            Background="#F85149" FontSize="16" Padding="0,15" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: WINGET MANAGER ===== -->
            <Grid x:Name="pageWinget" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
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
                        <Border Background="#161B22" CornerRadius="6" BorderBrush="#30363D" BorderThickness="1" Padding="2">
                            <TextBox x:Name="wingetSearchBox" Background="Transparent" Foreground="#E6EDF3" 
                                     BorderThickness="0" FontSize="14" Padding="10,8" CaretBrush="#E6EDF3"/>
                        </Border>
                        <TextBlock x:Name="wingetSearchPlaceholder" Text="  Type to filter installed apps or search online repo..." 
                                   Foreground="#484F58" FontSize="14" VerticalAlignment="Center" 
                                   Margin="14,0" IsHitTestVisible="False"/>
                    </Grid>

                    <Button x:Name="btnScanWingetInstalled" Grid.Column="2" Content="Scan Installed Apps" 
                            Background="#58A6FF" FontSize="13" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnSearchWingetRepo" Grid.Column="4" Content="Search Online Repo" 
                            Background="#A855F7" FontSize="13" Padding="14,8" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnExportWingetCustom" Grid.Column="6" Content="Export List" 
                            Background="#30363D" Foreground="#E6EDF3" FontSize="13" Padding="12,8" Style="{StaticResource RoundedBtn}"/>
                </Grid>

                <!-- Dynamic Content Area -->
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel x:Name="wingetItemsContainer"/>
                </ScrollViewer>

                <!-- Action Footer -->
                <Grid Grid.Row="3" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnInstallSelectedWinget" Grid.Column="0" Content="INSTALL SELECTED PACKAGES" 
                            Background="#3FB950" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnRemoveSelectedWinget" Grid.Column="2" Content="UNINSTALL SELECTED PACKAGES" 
                            Background="#F85149" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnAddCustomWingetApp" Grid.Column="4" Content="INSTALL / ADD BY ID" 
                            Background="#8957E5" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: TWEAKS ===== -->
            <Grid x:Name="pageTweaks" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,8">
                    <TextBlock Text="System Tweaks" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Apply or revert system optimizations" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,5,0,12">
                    <Button x:Name="btnProfileDesktop" Content="Desktop Profile" Background="#58A6FF" Padding="15,8" Margin="0,0,8,0" FontSize="13" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnProfileLaptop" Content="Laptop Profile" Background="#58A6FF" Padding="15,8" Margin="0,0,8,0" FontSize="13" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnResetTweaks" Content="Reset Selection" Background="#484F58" Padding="15,8" FontSize="13" Style="{StaticResource RoundedBtn}"/>
                </StackPanel>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                    <WrapPanel x:Name="tweaksContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="3" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnApplyTweaks" Grid.Column="0" Content="APPLY SELECTED TWEAKS" 
                            Background="#A855F7" FontSize="16" Padding="0,15" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnRevertTweaks" Grid.Column="2" Content="REVERT SELECTED TWEAKS" 
                            Background="#3B82F6" FontSize="16" Padding="0,15" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: CONFIG ===== -->
            <Grid x:Name="pageConfig" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,12">
                    <TextBlock Text="Features &amp; Configuration" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Enable Windows features and perform system maintenance" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="configContainer"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="btnEnableFeatures" Grid.Column="0" Content="ENABLE SELECTED" 
                            Background="#3FB950" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnDisableFeatures" Grid.Column="2" Content="DISABLE SELECTED" 
                            Background="#484F58" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnDeepClean" Grid.Column="4" Content="DEEP SYSTEM CLEAN" 
                            Background="#F85149" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                </Grid>
            </Grid>

            <!-- ===== PAGE: DEBLOAT ===== -->
            <Grid x:Name="pageDebloat" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,8">
                    <TextBlock Text="Advanced Debloater" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Remove pre-installed Windows bloatware" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,5,0,12">
                    <Button x:Name="btnSelectAll" Content="Select All" Background="#484F58" Padding="15,8" Margin="0,0,8,0" FontSize="13" Style="{StaticResource RoundedBtn}"/>
                    <Button x:Name="btnDeselectAll" Content="Deselect All" Background="#484F58" Padding="15,8" FontSize="13" Style="{StaticResource RoundedBtn}"/>
                </StackPanel>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                    <WrapPanel x:Name="debloatContainer"/>
                </ScrollViewer>

                <Button x:Name="btnDebloat" Grid.Row="3" Content="INITIATE DEBLOAT SEQUENCE" 
                        Background="#F85149" FontSize="16" Padding="0,15" Margin="0,10,0,0" Style="{StaticResource RoundedBtn}"/>
            </Grid>

            <!-- ===== PAGE: UPDATES ===== -->
            <Grid x:Name="pageUpdates" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,15">
                    <TextBlock Text="Update &amp; Repair Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="System updates and repair tools" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <Grid Grid.Row="1" Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <StackPanel Grid.Column="0">
                        <TextBlock Text="Updates" FontSize="18" FontWeight="SemiBold" Foreground="#58A6FF" Margin="0,0,0,10"/>
                        <Button x:Name="btnUpdateApps" Content="UPDATE ALL APPS (Winget)" Background="#D29922" Foreground="Black" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnUpdateWindows" Content="UPDATE WINDOWS (OS)" Background="#3FB950" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnUpdateDrivers" Content="UPDATE DRIVERS" Background="#22D3EE" Foreground="Black" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnUpdateStore" Content="MS STORE UPDATES" Background="#A855F7" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>

                    <StackPanel Grid.Column="2">
                        <TextBlock Text="System Repair" FontSize="18" FontWeight="SemiBold" Foreground="#F85149" Margin="0,0,0,10"/>
                        <Button x:Name="btnSfc" Content="RUN SFC /SCANNOW" Background="#30363D" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnDism" Content="RUN DISM REPAIR" Background="#30363D" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnNetReset" Content="RESET NETWORK STACK" Background="#D29922" Foreground="Black" FontSize="13" Padding="0,12" Margin="0,0,0,8" Style="{StaticResource RoundedBtn}"/>
                        <Button x:Name="btnFixWU" Content="EMERGENCY: FIX UPDATES" Background="#F85149" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                    </StackPanel>
                </Grid>

                <Border Grid.Row="2" Background="#0D1117" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <TextBlock Grid.Row="0" Text="  Command Output" Foreground="#484F58" FontSize="12" Margin="10,8,0,5"/>
                        <TextBox x:Name="outputBox" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap" 
                                 VerticalScrollBarVisibility="Auto" Background="Transparent" Foreground="#3FB950" 
                                 FontFamily="Consolas" FontSize="12" BorderThickness="0" Padding="10,5"
                                 AcceptsReturn="True"/>
                    </Grid>
                </Border>
            </Grid>

            <!-- ===== PAGE: BACKUP & RESTORE ===== -->
            <Grid x:Name="pageBackup" Grid.Row="0" Margin="25,20,25,15" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,15">
                    <TextBlock Text="Backup &amp; Restore Center" FontSize="26" FontWeight="Bold" Foreground="#E6EDF3"/>
                    <TextBlock Text="Export or import app lists, tweak preferences, and application configurations" Foreground="#8B949E" FontSize="13" Margin="0,4,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <!-- SECTION 1: SYSTEM PROFILE BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="20" Margin="0,0,0,15">
                            <StackPanel>
                                <TextBlock Text="1. VDOWNS System Profile (.vdowns)" FontSize="18" FontWeight="Bold" Foreground="#58A6FF" Margin="0,0,0,6"/>
                                <TextBlock Text="Export your currently selected apps, active tweaks, and debloat settings into a single portable profile file. Import it on a fresh system to auto-select and batch install everything." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,15"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="15"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnExportProfile" Grid.Column="0" Content="EXPORT PROFILE (.vdowns)" Background="#58A6FF" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnImportProfile" Grid.Column="2" Content="IMPORT PROFILE &amp; APPLY" Background="#3FB950" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                                <Button x:Name="btnExportUnattendedScript" Margin="0,12,0,0" Content="⚡ GENERATE UNATTENDED STANDALONE SETUP SCRIPT (.ps1)" Background="#238636" FontSize="13" Padding="0,12" Style="{StaticResource RoundedBtn}"/>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 2: APPDATA CONFIG BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="20" Margin="0,0,0,15">
                            <StackPanel>
                                <TextBlock Text="2. Application Settings &amp; Config Backup (.zip)" FontSize="18" FontWeight="Bold" Foreground="#A855F7" Margin="0,0,0,6"/>
                                <TextBlock Text="Backup popular app configurations (VS Code settings &amp; extensions, Git config, PowerShell profile, Windows Terminal settings, Notepad++ preferences) into a compressed Zip archive. Restore on a new PC to keep your exact workflow." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,15"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="15"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnBackupConfig" Grid.Column="0" Content="CREATE CONFIG BACKUP (.zip)" Background="#A855F7" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnRestoreConfig" Grid.Column="2" Content="RESTORE CONFIG BACKUP (.zip)" Background="#D29922" Foreground="Black" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- SECTION 3: WINGET BUNDLE BACKUP -->
                        <Border Background="#161B22" CornerRadius="8" BorderBrush="#30363D" BorderThickness="1" Padding="20">
                            <StackPanel>
                                <TextBlock Text="3. Winget Installed Package Export" FontSize="18" FontWeight="Bold" Foreground="#22D3EE" Margin="0,0,0,6"/>
                                <TextBlock Text="Export all software installed on this PC via Winget native package export, or import a winget file to install missing software." Foreground="#8B949E" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,15"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="15"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button x:Name="btnWingetExport" Grid.Column="0" Content="EXPORT WINGET LIST" Background="#30363D" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                    <Button x:Name="btnWingetImport" Grid.Column="2" Content="IMPORT WINGET LIST" Background="#30363D" FontSize="14" Padding="0,14" Style="{StaticResource RoundedBtn}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ===== LOG PANEL ===== -->
            <Border Grid.Row="1" Background="#161B22" BorderBrush="#30363D" BorderThickness="0,1,0,0">
                <Grid Height="120">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid Grid.Row="0" Margin="15,8,15,5">
                        <TextBlock Text="Activity Log" Foreground="#484F58" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        <Button x:Name="btnClearLog" HorizontalAlignment="Right" Content="Clear" 
                                Background="Transparent" Foreground="#8B949E" FontSize="11" 
                                Padding="8,3" Style="{StaticResource RoundedBtn}"/>
                    </Grid>
                    <TextBox x:Name="logBox" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap" 
                             VerticalScrollBarVisibility="Auto" Background="Transparent" Foreground="#8B949E" 
                             FontFamily="Consolas" FontSize="11" BorderThickness="0" Padding="15,2"
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
    VDOWNS PRIME v3.1.0 - Automated Standalone Unattended Deployment Script
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

# 14. SYSTEM INFO
# =============================================================================
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $lblOsInfo.Text = ($os.Caption -replace "Microsoft ", "")
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop).Name -replace '\s+', ' ' -replace '^\s+', ''
    $lblCpuInfo.Text = $cpu
    $ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $lblRamInfo.Text = "RAM: ${freeGB}GB free / ${ramGB}GB"
} catch {
    $lblOsInfo.Text = "Could not load system info"
}

# Initial log
Write-AppLog "VDOWNS PRIME v3.1.0 initialized." "INFO"
Write-AppLog "Running as Administrator." "SUCCESS"
try {
    $wv = & winget --version 2>$null
    Write-AppLog "Winget detected: $wv" "INFO"
} catch { Write-AppLog "Winget not found! App Center may not work." "ERROR" }

# Ready status notification
Write-AppLog "System Architect is ready. Select a category from the sidebar to begin." "SUCCESS"

# =============================================================================
# 15. SHOW WINDOW
# =============================================================================
$window.ShowDialog() | Out-Null

} catch {
    [System.Windows.MessageBox]::Show(
        "Critical Error Occurred:`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)",
        "VDOWNS PRIME Error", "OK", "Error")
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
}
