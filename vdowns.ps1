<#
.SYNOPSIS
    VDOWNS PRIME v2.0 - System Architect 
.DESCRIPTION
    Advanced System Configuration Tool.
    Fixed: Startup Crash, Tooltip Logic, Update Module Freeze.
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
        Write-Host "ERROR: Please SAVE the script to a location (e.g., Desktop) before running." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        Exit
    }
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}
    # =========================================================================
    # DPI AWARENESS FIX (PowerShell 5.1 Compatible)
    # =========================================================================
    try {
        $dpiCode = @"
        using System;
        using System.Runtime.InteropServices;
        public class DpiAware {
            [DllImport("user32.dll")]
            public static extern bool SetProcessDPIAware();
        }
"@
        if (-not ([System.Management.Automation.PSTypeName]'DpiAware').Type) {
            Add-Type -TypeDefinition $dpiCode
        }
        [DpiAware]::SetProcessDPIAware() | Out-Null
    } catch {
       
    }
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
try {
    # =========================================================================
    # 2. FORM AND INTERFACE SETUP
    # =========================================================================
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


    $Color_Back    = "#121212"
    $Color_Sidebar = "#1F1F1F"
    $Color_Accent  = "#00A8FF"
    $Color_Red     = "#E74C3C" 
    $Color_Text    = "#ECF0F1"
    $Color_Green   = "#2ECC71"
    $Color_Yellow  = "#F1C40F"
    $Color_Console = "#0F0F0F"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VDOWNS PRIME v2.0 | System Architect"
    $form.Size = New-Object System.Drawing.Size(1280, 750)
    $form.StartPosition = "CenterScreen"
    $form.WindowState = "Maximized"
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.FormBorderStyle = "Sizable"
    $form.MaximizeBox = $true
    $form.BackColor = $Color_Back
    $form.ForeColor = $Color_Text

    function Write-Log ($text, $type="INFO") {
        Write-Host "[$type] $text" -ForegroundColor Cyan
    }
    
    # ToolTip
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.AutoPopDelay = 10000
    $tooltip.InitialDelay = 500
    $tooltip.ReshowDelay = 500


    # =========================================================================
    # 3. SIDEBAR AND NAVIGATION 
    # =========================================================================

    # 1. SIDEBAR 
    $sidebar = New-Object System.Windows.Forms.Panel
    $sidebar.Location = New-Object System.Drawing.Point(0, 0) 
    $sidebar.Size = New-Object System.Drawing.Size(270, 800)  
    $sidebar.BackColor = $Color_Sidebar
    $sidebar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
    [void]$form.Controls.Add($sidebar)
    
    # 2. HEADER
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0) 
    $headerPanel.Size = New-Object System.Drawing.Size(270, 150)
    $sidebar.Controls.Add($headerPanel)

    $header = New-Object System.Windows.Forms.Label
    $header.Text = "VDOWNS`nPRIME V2"
    $header.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $header.ForeColor = $Color_Accent
    $header.Location = New-Object System.Drawing.Point(0, 20)
    $header.Size = New-Object System.Drawing.Size(270, 100) 
    $header.TextAlign = "MiddleCenter"
    $headerPanel.Controls.Add($header)

    # 3. MENU
    $menuBox = New-Object System.Windows.Forms.Panel 
    $menuBox.Location = New-Object System.Drawing.Point(0, 100) 
    $menuBox.Size = New-Object System.Drawing.Size(270, 440)    
    $menuBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left 
    $sidebar.Controls.Add($menuBox)

    # 4. EXIT
    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Text = "  X  TERMINATE"
    $btnExit.Size = New-Object System.Drawing.Size(270, 60)
    $btnExit.Location = New-Object System.Drawing.Point(0, 540) 
    $btnExit.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
    $btnExit.FlatStyle = "Flat"
    $btnExit.FlatAppearance.BorderSize = 0
    $btnExit.BackColor = $Color_Sidebar
    $btnExit.ForeColor = $Color_Red
    $btnExit.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $btnExit.TextAlign = "MiddleLeft"
    $btnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnExit.Add_Click({ $form.Close() })
    $sidebar.Controls.Add($btnExit)

    # 5. MAIN CONTAINER
    $mainContainer = New-Object System.Windows.Forms.Panel
    $mainContainer.BackColor = $Color_Back
    $mainContainer.Location = New-Object System.Drawing.Point(270, 0) 
    $mainContainer.Size = New-Object System.Drawing.Size(1010, 710)    
    $mainContainer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $mainContainer.Padding = New-Object System.Windows.Forms.Padding(20)
    $form.Controls.Add($mainContainer)
    $mainContainer.BringToFront()

    $pnlInstall = New-Object System.Windows.Forms.Panel; $pnlInstall.Location = New-Object System.Drawing.Point(0,0); $pnlInstall.Size = $mainContainer.Size; $pnlInstall.Anchor = "Top, Bottom, Left, Right"; $pnlInstall.Visible = $true; [void]$mainContainer.Controls.Add($pnlInstall)
    $pnlTweaks  = New-Object System.Windows.Forms.Panel; $pnlTweaks.Location = New-Object System.Drawing.Point(0,0);  $pnlTweaks.Size = $mainContainer.Size;  $pnlTweaks.Anchor = "Top, Bottom, Left, Right"; $pnlTweaks.Visible = $false; [void]$mainContainer.Controls.Add($pnlTweaks)
    $pnlConfig  = New-Object System.Windows.Forms.Panel; $pnlConfig.Location = New-Object System.Drawing.Point(0,0);  $pnlConfig.Size = $mainContainer.Size;  $pnlConfig.Anchor = "Top, Bottom, Left, Right"; $pnlConfig.Visible = $false; [void]$mainContainer.Controls.Add($pnlConfig)
    $pnlDebloat = New-Object System.Windows.Forms.Panel; $pnlDebloat.Location = New-Object System.Drawing.Point(0,0); $pnlDebloat.Size = $mainContainer.Size; $pnlDebloat.Anchor = "Top, Bottom, Left, Right"; $pnlDebloat.Visible = $false; [void]$mainContainer.Controls.Add($pnlDebloat)
    $pnlUpdates = New-Object System.Windows.Forms.Panel; $pnlUpdates.Location = New-Object System.Drawing.Point(0,0); $pnlUpdates.Size = $mainContainer.Size; $pnlUpdates.Anchor = "Top, Bottom, Left, Right"; $pnlUpdates.Visible = $false; [void]$mainContainer.Controls.Add($pnlUpdates)

    function Show-Page ($targetPanel) {
        $pnlInstall.Visible = $false; $pnlTweaks.Visible = $false; $pnlConfig.Visible = $false; $pnlDebloat.Visible = $false; $pnlUpdates.Visible = $false
        $targetPanel.Visible = $true; $targetPanel.BringToFront()
    }

    function Add-MenuBtn ($text, $targetPage, $yPos) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $text
        $btn.Location = New-Object System.Drawing.Point(0, $yPos) 
        $btn.Size = New-Object System.Drawing.Size(270, 55)
        
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.BackColor = $Color_Sidebar
        $btn.ForeColor = $Color_Text
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 13)
        $btn.TextAlign = "MiddleLeft"
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        $btn.Add_MouseEnter({ $this.BackColor = "#333333" })
        $btn.Add_MouseLeave({ $this.BackColor = $Color_Sidebar })
        
        $btn.Add_Click({ Show-Page $targetPage }.GetNewClosure())
        
        [void]$menuBox.Controls.Add($btn)
    }

    Add-MenuBtn "  > App Center"        $pnlInstall 50
    Add-MenuBtn "  > System Tweaks"     $pnlTweaks  150
    Add-MenuBtn "  > Features & Config" $pnlConfig  250
    Add-MenuBtn "  > Debloater"         $pnlDebloat 350 
    Add-MenuBtn "  > Updates"           $pnlUpdates 450

    # =========================================================================
    # TAB 1: APP CENTER
    # =========================================================================
    $l_inst = New-Object System.Windows.Forms.Label; $l_inst.Text = "App Center"; $l_inst.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold); $l_inst.AutoSize = $true; $l_inst.Location = New-Object System.Drawing.Point(900, 10); $pnlInstall.Controls.Add($l_inst)

    $flowInstall = New-Object System.Windows.Forms.FlowLayoutPanel; $flowInstall.Location = New-Object System.Drawing.Point(20, 60); $flowInstall.Size = New-Object System.Drawing.Size(1000, 250); $flowInstall.AutoScroll = $true; $flowInstall.Anchor = "Top, Bottom, Left, Right";$pnlInstall.Controls.Add($flowInstall)
    $script:InstallList = @() 

    # JSON LOADING
    try {
        $jsonPath = Join-Path $ScriptPath "apps.json"
        if (Test-Path $jsonPath) {
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            foreach ($categoryName in $jsonContent.PSObject.Properties.Name) {
                $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $categoryName; $grp.ForeColor = $Color_Accent; $grp.Size = New-Object System.Drawing.Size(450, 500); $grp.Margin = New-Object System.Windows.Forms.Padding(10); $grp.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
                $p = New-Object System.Windows.Forms.FlowLayoutPanel; $p.Dock = "Fill"; $p.FlowDirection = "TopDown"; $p.AutoScroll = $true; $grp.Controls.Add($p)
                $appsInCategory = $jsonContent.$categoryName
                foreach ($app in $appsInCategory) {
                    $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $app.Name; $cb.AutoSize = $true; $cb.ForeColor = $Color_Text; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9); $cb.Margin = New-Object System.Windows.Forms.Padding(3)
                    $p.Controls.Add($cb)
                    $script:InstallList += @{Check=$cb; Id=$app.Id; Name=$app.Name}
                }
                $flowInstall.Controls.Add($grp)
            }
        } else { Write-Log "WARNING: apps.json not found. App Center will be empty." "WARN" }
    } catch { Write-Log "JSON Error: $($_.Exception.Message)" "ERROR" }

    $pnlButtons = New-Object System.Windows.Forms.TableLayoutPanel
    $pnlButtons.RowCount = 1
    $pnlButtons.ColumnCount = 2
    $pnlButtons.Dock = "Bottom"
    $pnlButtons.Height = 300
    [void]$pnlButtons.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
    [void]$pnlButtons.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
    $pnlInstall.Controls.Add($pnlButtons)

    $btnInst = New-Object System.Windows.Forms.Button
    $btnInst.Text = "INSTALL SELECTED"
    $btnInst.Location = New-Object System.Drawing.Point(20, 400)
    $btnInst.Size = New-Object System.Drawing.Size(1000, 80)
    $btnInst.BackColor = $Color_Green
    $btnInst.FlatStyle = "Flat"
    $btnInst.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
    $btnInst.Add_Click({ 

        Write-Log "--- Starting Installation ---" "ACTION"
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        foreach($a in $script:InstallList){ 
            [System.Windows.Forms.Application]::DoEvents()
            if($a.Check.Checked -and $a.Id -ne "") { 
                Write-Log "Installing: $($a.Name)..." "INFO"
                try {
                    $proc = Start-Process "winget" -ArgumentList "install --id $($a.Id) -e --silent --accept-package-agreements --accept-source-agreements --force" -Wait -PassThru
                    if ($proc.ExitCode -eq 0) { Write-Log "Successfully Installed: $($a.Name)" "SUCCESS" } else { Write-Log "Failed to Install: $($a.Name) (Exit Code: $($proc.ExitCode))" "ERROR" }
                } catch { Write-Log "Error executing winget for $($a.Name)" "ERROR" }
            } 
        }
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        Write-Log "Installation Cycle Complete." "INFO"
    })
    $pnlButtons.Controls.Add($btnInst, 0, 0) 

   
    $btnUninst = New-Object System.Windows.Forms.Button
    $btnUninst.Text = "UNINSTALL SELECTED"
    $btnUninst.Location = New-Object System.Drawing.Point(515, 630) 
    $btnUninst.Size = New-Object System.Drawing.Size(1000, 80)
    $btnUninst.BackColor = $Color_Red
    $btnUninst.FlatStyle = "Flat"
    $btnUninst.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold) 
    $btnUninst.Add_Click({ 
        Write-Log "--- Starting Uninstallation ---" "WARN"
        $result = [System.Windows.Forms.MessageBox]::Show("Selected apps will be REMOVED. Continue?", "Confirm Uninstall", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq "Yes") {
            foreach($a in $script:InstallList){ 
                if($a.Check.Checked -and $a.Id -ne "") { 
                    Write-Log "Uninstalling: $($a.Name)..." "INFO"
                    try {
                        Start-Process "winget" -ArgumentList "uninstall --id $($a.Id) --silent" -Wait
                        Write-Log "Uninstall command sent for: $($a.Name)" "INFO"
                    } catch { Write-Log "Error executing removal for $($a.Name)" "ERROR" }
                } 
            }
            Write-Log "Uninstallation Cycle Complete." "INFO"
        }
    })
    $pnlButtons.Controls.Add($btnUninst, 1, 0) 

    # =========================================================================
    # TAB 2: TWEAKS
    # =========================================================================
    $l_tw = New-Object System.Windows.Forms.Label; $l_tw.Text = "System Tweaks (Apply / Revert)"; $l_tw.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold); $l_tw.Size = New-Object System.Drawing.Size(600, 40); $l_tw.Location = New-Object System.Drawing.Point(900, 100); $pnlTweaks.Controls.Add($l_tw)

    $pnlProfiles = New-Object System.Windows.Forms.FlowLayoutPanel; $pnlProfiles.Location = New-Object System.Drawing.Point(850, 300); $pnlProfiles.Size = New-Object System.Drawing.Size(600, 80); $pnlTweaks.Controls.Add($pnlProfiles)
    function Add-ProfileBtn ($txt, $action) {
        $b = New-Object System.Windows.Forms.Button; $b.Text = $txt; $b.AutoSize = $true; $b.BackColor = $Color_Accent; $b.ForeColor = "Black"; $b.FlatStyle = "Flat"; $b.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $b.Margin = New-Object System.Windows.Forms.Padding(0,0,10,0); $b.Add_Click($action); $pnlProfiles.Controls.Add($b)
    }
    Add-ProfileBtn "PROFILE: DESKTOP" { $script:TweakList | Where-Object {$_.Tag -eq "Essential" -or $_.Tag -eq "UI"} | ForEach-Object { $_.Check.Checked = $true } }
    Add-ProfileBtn "PROFILE: LAPTOP" { $script:TweakList | Where-Object {$_.Tag -eq "Power"} | ForEach-Object { $_.Check.Checked = $true } }
    Add-ProfileBtn "RESET SELECTION" { $script:TweakList | ForEach-Object { $_.Check.Checked = $false } }

    $flowTweaks = New-Object System.Windows.Forms.FlowLayoutPanel; $flowTweaks.Location = New-Object System.Drawing.Point(500, 400); $flowTweaks.Size = New-Object System.Drawing.Size(1600, 700); $flowTweaks.AutoScroll = $true; $pnlTweaks.Controls.Add($flowTweaks)
    $script:TweakList = @()

    function Add-TweakGroup ($title, $tweaks) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $title; $grp.ForeColor = "White"; $grp.Size = New-Object System.Drawing.Size(400, 600);  $grp.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $p = New-Object System.Windows.Forms.FlowLayoutPanel; $p.Dock = "Fill"; $p.FlowDirection = "TopDown"; $p.AutoScroll = $true; $grp.Controls.Add($p)
        foreach ($t in $tweaks) {
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $t.Name; $cb.AutoSize = $true; $cb.ForeColor = "#dddddd"; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 11); $cb.Margin = New-Object System.Windows.Forms.Padding(3)
            $p.Controls.Add($cb)
            $script:TweakList += @{Check=$cb; Do=$t.Do; Undo=$t.Undo; Name=$t.Name; Tag=$t.Tag}
        }
        $flowTweaks.Controls.Add($grp)
    }

    $essentialTweaks = @(
        @{Name="Create Restore Point"; Tag="Essential"; 
          Do={ Checkpoint-Computer -Description "VDOWNSPrimeRestore" -RestorePointType "MODIFY_SETTINGS" }; 
          Undo={ Write-Log "Restore points cannot be deleted from here." "WARN" } },
        @{Name="Run OO ShutUp10"; Tag="Essential"; 
          Do={ $url="https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"; Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\OOSU10.exe"; Start-Process "$env:TEMP\OOSU10.exe" }; 
          Undo={ Write-Log "Open O&O ShutUp10 manually to revert changes." "INFO" } },
        @{Name="Disable Telemetry"; Tag="Essential"; 
          Do={ Set-Service DiagTrack -StartupType Disabled; Stop-Service DiagTrack }; 
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
          Do={ reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve }; 
          Undo={ reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f } },
        @{Name="Align Taskbar Left"; Tag="UI"; 
          Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 }; 
          Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1 } },
        @{Name="Hide Search Icon"; Tag="UI"; 
          Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 }; 
          Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 } },
        @{Name="Shrink Search Box"; Tag="UI"; 
          Do={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 }; 
          Undo={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 2 } },
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
          Undo={ Write-Log "Ultimate Power Plan added. Select it manually in Power Options." "INFO" } },
        @{Name="Disable SysMain"; Tag="Power"; 
          Do={ Set-Service SysMain -StartupType Disabled; Stop-Service SysMain }; 
          Undo={ Set-Service SysMain -StartupType Automatic; Start-Service SysMain } },
        @{Name="Disable Game DVR"; Tag="Power"; 
          Do={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }; 
          Undo={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1 } }
    )

    Add-TweakGroup "Essential Privacy" $essentialTweaks
    Add-TweakGroup "Interface Explorer" $uiTweaks
    Add-TweakGroup "Performance Power" $perfTweaks

    $btnApplyT = New-Object System.Windows.Forms.Button; $btnApplyT.Text = "APPLY SELECTED TWEAKS"; $btnApplyT.Size = New-Object System.Drawing.Size(500, 80); $btnApplyT.Location = New-Object System.Drawing.Point(600, 1200); $btnApplyT.BackColor = "#6c5ce7"; $btnApplyT.FlatStyle = "Flat"; $btnApplyT.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); 
    $btnApplyT.Add_Click({ 
        Write-Log "--- Applying Tweaks ---" "ACTION"
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        foreach($t in $script:TweakList){ 
            [System.Windows.Forms.Application]::DoEvents()
            if($t.Check.Checked){ 
                try {
                    Invoke-Command -ScriptBlock $t.Do -ErrorAction Stop
                    Write-Log "Applied: $($t.Name)" "SUCCESS"
                } catch { Write-Log "Failed: $($t.Name) - $($_.Exception.Message)" "ERROR" }
            } 
        }
        Stop-Process -Name explorer -Force
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        Write-Log "Tweaks Applied. Explorer Restarted." "INFO"
    }); $pnlTweaks.Controls.Add($btnApplyT)

    $btnRevT = New-Object System.Windows.Forms.Button; $btnRevT.Text = "REVERT (UNDO) SELECTED"; $btnRevT.Size = New-Object System.Drawing.Size(500, 80); $btnRevT.Location = New-Object System.Drawing.Point(1200, 1200); $btnRevT.BackColor = "#0984e3"; $btnRevT.FlatStyle = "Flat"; $btnRevT.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); 
    $btnRevT.Add_Click({ 
        Write-Log "--- Reverting Tweaks ---" "WARN"
        foreach($t in $script:TweakList){ 
            if($t.Check.Checked){ 
                try {
                    Invoke-Command -ScriptBlock $t.Undo -ErrorAction Stop
                    Write-Log "Reverted: $($t.Name)" "SUCCESS"
                } catch { Write-Log "Failed Revert: $($t.Name) - $($_.Exception.Message)" "ERROR" }
            } 
        }
        Stop-Process -Name explorer -Force
        Write-Log "Revert Operations Done. Explorer Restarted." "INFO"
    }); $pnlTweaks.Controls.Add($btnRevT)


    # =========================================================================
    # TAB 3: CONFIG & DEEP CLEAN
    # =========================================================================
    $l_cf = New-Object System.Windows.Forms.Label; $l_cf.Text = "Windows Features & Maintenance"; $l_cf.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_cf.AutoSize = $true; $l_cf.Location = New-Object System.Drawing.Point(800, 10); $pnlConfig.Controls.Add($l_cf)

    $flowFeat = New-Object System.Windows.Forms.FlowLayoutPanel; $flowFeat.Location = New-Object System.Drawing.Point(400, 200); $flowFeat.Size = New-Object System.Drawing.Size(1600, 60); $pnlConfig.Controls.Add($flowFeat)
    $script:FeatureList = @()

    function Add-FeatureItem ($name, $winName, $desc) {
        $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $name; $cb.AutoSize = $true; $cb.ForeColor = "White"; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 20); $cb.Margin = New-Object System.Windows.Forms.Padding(10)
        $flowFeat.Controls.Add($cb)
        $script:FeatureList += @{Check=$cb; WinName=$winName; Name=$name}
    }

    Add-FeatureItem "Hyper-V Platform" "Microsoft-Hyper-V-All" "VM Tech"
    Add-FeatureItem "WSL 2 (Linux)" "Microsoft-Windows-Subsystem-Linux" "Linux on Windows"
    Add-FeatureItem "Windows Sandbox" "Containers-DisposableClientVM" "Sandbox"
    Add-FeatureItem ".NET Framework 3.5" "NetFx3" "Old Apps"

    $btnFeat = New-Object System.Windows.Forms.Button; $btnFeat.Text = "ENABLE SELECTED"; $btnFeat.Size = New-Object System.Drawing.Size(800, 100); $btnFeat.Location = New-Object System.Drawing.Point(700, 400); $btnFeat.BackColor = "#e17055"; $btnFeat.FlatStyle = "Flat"; $btnFeat.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold); 
    $btnFeat.Add_Click({ 
        Write-Log "--- Enabling Features ---" "ACTION"
        foreach($f in $script:FeatureList){ 
            if($f.Check.Checked){ 
                try {
                    Write-Log "Enabling: $($f.Name)..." "INFO"
                    Enable-WindowsOptionalFeature -Online -FeatureName $f.WinName -All -NoRestart -ErrorAction Stop
                    Write-Log "Enabled: $($f.Name)" "SUCCESS"
                } catch { Write-Log "Error: $($f.Name)" "ERROR" }
            } 
        }
        Write-Log "Feature changes may require a RESTART." "WARN"
    }); $pnlConfig.Controls.Add($btnFeat)

    $btnFeatOff = New-Object System.Windows.Forms.Button; $btnFeatOff.Text = "DISABLE SELECTED"; $btnFeatOff.Size = New-Object System.Drawing.Size(800, 100); $btnFeatOff.Location = New-Object System.Drawing.Point(700, 580); $btnFeatOff.BackColor = "#636e72"; $btnFeatOff.FlatStyle = "Flat"; $btnFeatOff.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold); 
    $btnFeatOff.Add_Click({ 
        Write-Log "--- Disabling Features ---" "WARN"
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        foreach($f in $script:FeatureList){ 
            [System.Windows.Forms.Application]::DoEvents()
            if($f.Check.Checked){ 
                try {
                    Write-Log "Disabling: $($f.Name)..." "INFO"
                    Disable-WindowsOptionalFeature -Online -FeatureName $f.WinName -NoRestart -ErrorAction Stop
                    Write-Log "Disabled: $($f.Name)" "SUCCESS"
                } catch { Write-Log "Error: $($f.Name)" "ERROR" }
            } 
        }
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }); $pnlConfig.Controls.Add($btnFeatOff)

    $btnDeepClean = New-Object System.Windows.Forms.Button; $btnDeepClean.Text = "DEEP SYSTEM CLEAN"; $btnDeepClean.Size = New-Object System.Drawing.Size(800, 100); $btnDeepClean.Location = New-Object System.Drawing.Point(700, 760); $btnDeepClean.BackColor = $Color_Red; $btnDeepClean.FlatStyle = "Flat"; $btnDeepClean.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold); 
    $btnDeepClean.Add_Click({
        Write-Log "--- Starting Deep System Clean ---" "WARN"
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            Get-ChildItem $regPath | ForEach-Object {
                New-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -PropertyType DWORD -Force | Out-Null
            }
            Write-Log "Clean configurations loaded." "INFO"
            Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden
            Write-Log "Deep Clean process started in background." "SUCCESS"
        } catch { Write-Log "Clean Error: $($_.Exception.Message)" "ERROR" }
    }); $pnlConfig.Controls.Add($btnDeepClean)


    # =========================================================================
    # TAB 4: DEBLOAT
    # =========================================================================
    $l_deb = New-Object System.Windows.Forms.Label; $l_deb.Text = "Advanced System Debloater"; $l_deb.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_deb.Size = New-Object System.Drawing.Size(600, 100); $l_deb.Location = New-Object System.Drawing.Point(900, 10); $pnlDebloat.Controls.Add($l_deb)

    $flowDebloat = New-Object System.Windows.Forms.FlowLayoutPanel; $flowDebloat.Location = New-Object System.Drawing.Point(500, 300); $flowDebloat.Size = New-Object System.Drawing.Size(1800, 1200); $flowDebloat.FlowDirection = "LeftToRight"; $flowDebloat.WrapContents = $true; $flowDebloat.AutoScroll = $true; $pnlDebloat.Controls.Add($flowDebloat)
    $script:DebloatList = @()

    $bloatItems = [ordered]@{
        "News, Weather & Money" = @("*BingNews*","*BingWeather*","*BingFinance*", "Removes Bing News, Weather, and Money apps");
        "Microsoft Solitaire"   = @("*MicrosoftSolitaireCollection*", "Removes the pre-installed Solitaire game");
        "Get Help & Tips"       = @("*GetHelp*","*Getstarted*", "Removes 'Get Help' and 'Tips' bloatware");
        "Feedback Hub"          = @("*WindowsFeedbackHub*", "Removes the Windows Feedback/Telemetry Hub");
        "Cortana"               = @("*Cortana*", "Removes the legacy Cortana voice assistant");
        "People App"            = @("*Microsoft.People*", "Removes the taskbar People/Contacts integration");
        "Groove Music"          = @("*ZuneMusic*", "Removes the legacy Groove Music player");
        "Movies & TV"           = @("*ZuneVideo*", "Removes the Movies & TV app");
        "Windows Camera"        = @("*WindowsCamera*", "Removes the default Camera app (Use with caution)");
        "Windows Photos"        = @("*Windows.Photos*", "Removes the default Photos app (CAUTION: No image viewer left)");
        "Disney+"               = @("*Disney*", "Removes pre-provisioned Disney+ app");
        "3D Viewer & Paint 3D"  = @("*Microsoft3DViewer*","*MSPaint*", "Removes 3D Viewer and Paint 3D");
        "Office Hub"            = @("*MicrosoftOfficeHub*", "Removes the 'My Office' promotional app");
        "OneNote"               = @("*Office.OneNote*", "Removes the UWP OneNote app");
        "Skype"                 = @("*SkypeApp*", "Removes the consumer Skype application");
        "Teams (Personal)"      = @("*Teams*", "Removes the personal version of Microsoft Teams");
        "Sticky Notes"          = @("*MicrosoftStickyNotes*", "Removes the Sticky Notes widget");
        "Voice Recorder"        = @("*WindowsSoundRecorder*", "Removes the built-in Voice Recorder");
        "Calculator"            = @("*WindowsCalculator*", "Removes Windows Calculator (Use with caution)");
        "Alarms & Clock"        = @("*WindowsAlarms*", "Removes the Alarms and Timer app");
        "Windows Maps"          = @("*WindowsMaps*", "Removes the offline Maps application");
        "To-Do"                 = @("*Todos*", "Removes Microsoft To-Do list app");
        "Mail & Calendar"       = @("*windowscommunicationsapps*", "Removes default Mail and Calendar apps");
        "Xbox Game Bar"         = @("*XboxGamingOverlay*","*XboxGameOverlay*", "Removes the Win+G Game Bar overlay");
        "Xbox App & Identity"   = @("*XboxApp*","*XboxIdentityProvider*", "Removes the main Xbox App");
        "Your Phone"            = @("*YourPhone*","*PhoneLink*", "Removes Phone Link (Android/iOS integration)");
        "Mixed Reality"         = @("*MixedReality.Portal*", "Removes VR/Mixed Reality Portal");
        "Quick Assist"          = @("*QuickAssist*", "Removes the remote support tool");
        "Wallet / Pay"          = @("*Wallet*", "Removes Microsoft Pay/Wallet components")
    }

    foreach ($k in $bloatItems.Keys) {
        $data = $bloatItems[$k]
        $patterns = $data[0..($data.Count-2)]
        $desc = $data[-1]
        
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = "$k ($desc)"
        $cb.Checked = $false
        if ($k -eq "News, Weather & Money" -or $k -eq "Microsoft Solitaire" -or $k -eq "Get Help & Tips" -or $k -eq "Feedback Hub" -or $k -eq "Cortana") {
            $cb.Checked = $true
        }
        $cb.AutoSize = $false
        $cb.Size = New-Object System.Drawing.Size(460, 50)
        $cb.TextAlign = "MiddleLeft"
        $cb.ForeColor = "White"
        $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $cb.Margin = New-Object System.Windows.Forms.Padding(15, 15, 15, 20)
        
        $tooltip.SetToolTip($cb, $desc)
        
        $flowDebloat.Controls.Add($cb)
        $script:DebloatList += @{Check=$cb; Pat=$patterns; Name=$k}
    }

    $btnSelAll = New-Object System.Windows.Forms.Button; $btnSelAll.Text = "Select All"; $btnSelAll.Size = New-Object System.Drawing.Size(400, 60); $btnSelAll.Location = New-Object System.Drawing.Point(1200, 150); $btnSelAll.BackColor = "#636e72"; $btnSelAll.FlatStyle = "Flat"; $btnSelAll.Font = New-Object System.Drawing.Font("Segoe UI", 16); 
    $btnSelAll.Add_Click({ foreach($i in $script:DebloatList){ $i.Check.Checked = $true } }); $pnlDebloat.Controls.Add($btnSelAll)

    $btnClean = New-Object System.Windows.Forms.Button; $btnClean.Text = "INITIATE DEBLOAT SEQUENCE"; $btnClean.Size = New-Object System.Drawing.Size(400, 60); $btnClean.Location = New-Object System.Drawing.Point(700, 150); $btnClean.BackColor = $Color_Red; $btnClean.ForeColor = "White"; $btnClean.FlatStyle = "Flat"; $btnClean.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnClean.Add_Click({
        Write-Log "--- Starting Debloat Process ---" "WARN"
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $confirm = [System.Windows.Forms.MessageBox]::Show("Selected applications will be PERMANENTLY removed.`nSome system apps cannot be restored easily.`n`nAre you sure you want to continue?", "Confirm Debloat", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -eq "Yes") {
            foreach ($item in $script:DebloatList) {
                [System.Windows.Forms.Application]::DoEvents()
                if ($item.Check.Checked) {
                    foreach ($p in $item.Pat) { 
                        try {
                            $pkgs = Get-AppxPackage | Where-Object {$_.Name -like $p}
                            if ($pkgs) {
                                foreach ($pkg in $pkgs) {
                                    Write-Log "Removing: $($pkg.Name)..." "INFO"
                                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                                    Write-Log "Successfully Removed: $($pkg.Name)" "SUCCESS"
                                }
                            }
                        } catch { Write-Log "Failed to remove: $p - $($_.Exception.Message)" "ERROR" }
                    }
                }
            }
            Write-Log "Debloat Sequence Completed!" "INFO"
            [System.Windows.Forms.MessageBox]::Show("Cleanup Operation Complete!")
        } else { Write-Log "Debloat process cancelled by user." "INFO" }
         $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }); $pnlDebloat.Controls.Add($btnClean)

    # =========================================================================
    # TAB 5: SYSTEM UPDATE & REPAIR CENTER
    # =========================================================================
    
    # WINDOWS API
    $apiCode = @"
    using System;
    using System.Runtime.InteropServices;

    namespace User32 {
        public class WinApi {
            [DllImport("user32.dll")]
            public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
            
            [DllImport("user32.dll", SetLastError = true)]
            public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
            
            [DllImport("user32.dll")]
            public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
            
            [DllImport("user32.dll")]
            public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
            
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

            [DllImport("user32.dll")]
            public static extern bool EnableWindow(IntPtr hWnd, bool bEnable);
        }
    }
"@
    
    if (-not ([System.Management.Automation.PSTypeName]'User32.WinApi').Type) {
        Add-Type -TypeDefinition $apiCode
    }

    if ($null -eq $pnlUpdates) {
        $pnlUpdates = New-Object System.Windows.Forms.Panel
        $pnlUpdates.Dock = "Fill"
        $pnlUpdates.Visible = $false
        $mainContainer.Controls.Add($pnlUpdates)
    }

    $consoleHost = New-Object System.Windows.Forms.Panel
    $consoleHost.Location = New-Object System.Drawing.Point(350, 800) 
    $consoleHost.Size = New-Object System.Drawing.Size(1600, 600)     
    $consoleHost.BackColor = "Black"
    $consoleHost.BorderStyle = "Fixed3D"
    $pnlUpdates.Controls.Add($consoleHost)

    $lblConsole = New-Object System.Windows.Forms.Label
    $lblConsole.Text = "Live Process Monitor (View Only)"
    $lblConsole.ForeColor = "Gray"
    $lblConsole.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $lblConsole.Location = New-Object System.Drawing.Point(350, 760)
    $lblConsole.AutoSize = $true
    $pnlUpdates.Controls.Add($lblConsole)

    $script:EmbeddedProc = $null


    function Start-Embedded-Console ($command, $title) {
        
        if ($script:EmbeddedProc -ne $null -and -not $script:EmbeddedProc.HasExited) {
            $script:EmbeddedProc.Kill()
        }

        $startBlock = "
            `$host.UI.RawUI.WindowTitle = '$title';
            [Console]::BackgroundColor = 'Black';
            [Console]::ForegroundColor = 'Green';
            try { [Console]::BufferWidth = 120; } catch {} 
            Clear-Host;
            Write-Host '------------------------------------------------------------';
            Write-Host ' TASK STARTED: $title';
            Write-Host '------------------------------------------------------------';
            Write-Host '';
            $command;
            Write-Host '';
            Write-Host '------------------------------------------------------------';
            Write-Host ' PROCESS COMPLETED. STANDBY.';
            Write-Host '------------------------------------------------------------';
            cmd /c pause | Out-Null
        "

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoExit -Command & {$startBlock}"
        $psi.UseShellExecute = $true 
        $psi.WindowStyle = "Normal" 

        $script:EmbeddedProc = [System.Diagnostics.Process]::Start($psi)

        $timeout = 0
        while ($script:EmbeddedProc.MainWindowHandle -eq [IntPtr]::Zero -and $timeout -lt 20) {
            Start-Sleep -Milliseconds 100
            $script:EmbeddedProc.Refresh()
            $timeout++
        }

        if ($script:EmbeddedProc.MainWindowHandle -ne [IntPtr]::Zero) {
            $hWnd = $script:EmbeddedProc.MainWindowHandle
            
            
            $style = [User32.WinApi]::GetWindowLong($hWnd, -16)
            [User32.WinApi]::SetWindowLong($hWnd, -16, ($style -band -bnot 0xC40000)) | Out-Null

            [User32.WinApi]::SetParent($hWnd, $consoleHost.Handle) | Out-Null
            
            [User32.WinApi]::MoveWindow($hWnd, 0, 0, $consoleHost.Width, $consoleHost.Height, $true) | Out-Null
            
            [User32.WinApi]::ShowWindow($hWnd, 5) | Out-Null 

            [User32.WinApi]::EnableWindow($hWnd, $false) | Out-Null
        }
    }
    
    # Resize Event
    $consoleHost.Add_Resize({
        if ($script:EmbeddedProc -ne $null -and -not $script:EmbeddedProc.HasExited) {
             [User32.WinApi]::MoveWindow($script:EmbeddedProc.MainWindowHandle, 0, 0, $consoleHost.Width, $consoleHost.Height, $true) | Out-Null
        }
    })

    # --- UI BAŞLIKLARI ---
    $l_up = New-Object System.Windows.Forms.Label
    $l_up.Text = "Update Center"
    $l_up.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $l_up.AutoSize = $true
    $l_up.ForeColor = $Color_Accent
    $l_up.Location = New-Object System.Drawing.Point(650, 200)
    $pnlUpdates.Controls.Add($l_up)

    $l_rep = New-Object System.Windows.Forms.Label
    $l_rep.Text = "System Repair Tools"
    $l_rep.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $l_rep.AutoSize = $true
    $l_rep.ForeColor = $Color_Red
    $l_rep.Location = New-Object System.Drawing.Point(1300, 200)
    $pnlUpdates.Controls.Add($l_rep)

    # ================= LEFT (UPDATES) =================

    # 1. APP UPDATES
    $btnUp = New-Object System.Windows.Forms.Button
    $btnUp.Text = "UPDATE ALL APPS (Winget)"
    $btnUp.Size = New-Object System.Drawing.Size(600, 80)
    $btnUp.Location = New-Object System.Drawing.Point(500, 300)
    $btnUp.BackColor = "#F1C40F" 
    $btnUp.FlatStyle = "Flat"
    $btnUp.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnUp.Add_Click({
        Start-Embedded-Console "winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements" "Winget Update"
    })
    $pnlUpdates.Controls.Add($btnUp)

    # 2. WINDOWS UPDATES
    $btnWinUp = New-Object System.Windows.Forms.Button
    $btnWinUp.Text = "UPDATE WINDOWS (OS Only)"
    $btnWinUp.Size = New-Object System.Drawing.Size(600, 80)
    $btnWinUp.Location = New-Object System.Drawing.Point(500, 400)
    $btnWinUp.BackColor = "#2ECC71" 
    $btnWinUp.FlatStyle = "Flat"
    $btnWinUp.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnWinUp.Add_Click({
        $cmd = "
            if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -Confirm:`$false }
            Import-Module PSWindowsUpdate;
            Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -Verbose
        "
        Start-Embedded-Console $cmd "Windows OS Update"
    })
    $pnlUpdates.Controls.Add($btnWinUp)

# 3. DRIVER UPDATES
    $btnDriver = New-Object System.Windows.Forms.Button
    $btnDriver.Text = "UPDATE DRIVERS ONLY"
    $btnDriver.Size = New-Object System.Drawing.Size(600, 80)
    $btnDriver.Location = New-Object System.Drawing.Point(500, 500)
    $btnDriver.BackColor = "#00cec9"
    $btnDriver.FlatStyle = "Flat"
    $btnDriver.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnDriver.Add_Click({
        $cmd = "
            if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -Confirm:`$false }
            Import-Module PSWindowsUpdate;
            Get-WindowsUpdate -Category 'Drivers' -AcceptAll -Install -IgnoreReboot -Verbose
        "
        Start-Embedded-Console $cmd "Driver Updates"
    })
    $pnlUpdates.Controls.Add($btnDriver)

    # 4. STORE UPDATES 
    $btnStore = New-Object System.Windows.Forms.Button
    $btnStore.Text = "FORCE MS STORE UPDATES"
    $btnStore.Size = New-Object System.Drawing.Size(600, 80)
    $btnStore.Location = New-Object System.Drawing.Point(500, 600)
    $btnStore.BackColor = "#6c5ce7"
    $btnStore.ForeColor = "White"
    $btnStore.FlatStyle = "Flat"
    $btnStore.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnStore.Add_Click({
        $cmd = "winget upgrade --all --accept-package-agreements --accept-source-agreements --source msstore --include-unknown"
        Start-Embedded-Console $cmd "Microsoft Store Updates"
    })
    $pnlUpdates.Controls.Add($btnStore)


    # ================= RIGHT (REPAIR TOOLS) =================

    # 5. SFC SCANNOW
    $btnSFC = New-Object System.Windows.Forms.Button
    $btnSFC.Text = "RUN SFC /SCANNOW"
    $btnSFC.Size = New-Object System.Drawing.Size(600, 80)
    $btnSFC.Location = New-Object System.Drawing.Point(1200, 300)
    $btnSFC.BackColor = "#34495e"
    $btnSFC.ForeColor = "White"
    $btnSFC.FlatStyle = "Flat"
    $btnSFC.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnSFC.Add_Click({
        Start-Embedded-Console "sfc /scannow" "System File Checker"
    })
    $pnlUpdates.Controls.Add($btnSFC)

    # 6. DISM RESTORE
    $btnDISM = New-Object System.Windows.Forms.Button
    $btnDISM.Text = "RUN DISM REPAIR"
    $btnDISM.Size = New-Object System.Drawing.Size(600, 80)
    $btnDISM.Location = New-Object System.Drawing.Point(1200, 400)
    $btnDISM.BackColor = "#34495e"
    $btnDISM.ForeColor = "White"
    $btnDISM.FlatStyle = "Flat"
    $btnDISM.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnDISM.Add_Click({
        Start-Embedded-Console "dism /Online /Cleanup-Image /RestoreHealth" "DISM Image Repair"
    })
    $pnlUpdates.Controls.Add($btnDISM)

    # 7. NETWORK RESET
    $btnNet = New-Object System.Windows.Forms.Button
    $btnNet.Text = "RESET NETWORK STACK"
    $btnNet.Size = New-Object System.Drawing.Size(600, 80)
    $btnNet.Location = New-Object System.Drawing.Point(1200, 500)
    $btnNet.BackColor = "#e67e22"
    $btnNet.ForeColor = "White"
    $btnNet.FlatStyle = "Flat"
    $btnNet.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnNet.Add_Click({
        Start-Embedded-Console "ipconfig /flushdns; netsh winsock reset; netsh int ip reset" "Network Reset"
    })
    $pnlUpdates.Controls.Add($btnNet)

    # 8. EMERGENCY
    $btnFixWU = New-Object System.Windows.Forms.Button
    $btnFixWU.Text = "EMERGENCY: FIX STUCK UPDATES"
    $btnFixWU.Size = New-Object System.Drawing.Size(600, 80)
    $btnFixWU.Location = New-Object System.Drawing.Point(1200, 600)
    $btnFixWU.BackColor = "#c0392b"
    $btnFixWU.ForeColor = "White"
    $btnFixWU.FlatStyle = "Flat"
    $btnFixWU.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $btnFixWU.Add_Click({
        $cmd = "
            Stop-Service wuauserv -Force; Stop-Service cryptSvc -Force; Stop-Service bits -Force;
            Remove-Item -Path 'C:\Windows\SoftwareDistribution' -Recurse -Force;
            Start-Service wuauserv; Start-Service bits;
        "
        Start-Embedded-Console $cmd "Emergency WU Reset"
    })
    $pnlUpdates.Controls.Add($btnFixWU)

    # ======================================================
    # SHOW APP
    # ===================================================
    $form.ShowDialog() | Out-Null

} catch {
    [System.Windows.Forms.MessageBox]::Show("Critical Error Occurred:`n" + $_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
}