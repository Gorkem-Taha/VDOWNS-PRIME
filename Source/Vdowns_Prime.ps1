<#
.SYNOPSIS
    VDOWNS PRIME v1.0 - System Architect
.DESCRIPTION
    Elite System Configuration Tool.
    Features:
    - Dynamic App Loader (apps.json)
    - Hybrid Interface (Dark Theme)
    - Advanced Tweaks & Debloater
#>

$ErrorActionPreference = "Continue"

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

try {
    # --- 2. LIBRARIES & THEME ---
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $host.UI.RawUI.WindowTitle = "VDOWNS PRIME v1.0 | System Architect"

    # Elite Color Palette
    $Color_Back    = "#121212" # Deep Black
    $Color_Sidebar = "#1F1F1F" # Dark Gray
    $Color_Accent  = "#00A8FF" # Neon Blue (Prime Color)
    $Color_Red     = "#E74C3C" 
    $Color_Text    = "#ECF0F1"
    $Color_Green   = "#2ECC71"
    $Color_Yellow  = "#F1C40F"
    # --- 3. PATH DETECTION (UNIVERSAL FIX) ---
    # Bu yöntem hem EXE hem de Script modunda hatasız çalışır
    if ([string]::IsNullOrEmpty($PSScriptRoot)) {
        # Eğer PSScriptRoot boşsa, demek ki EXE içindeyiz
        $ScriptPath = [System.AppDomain]::CurrentDomain.BaseDirectory
    } else {
        # Doluysa, normal script modundayız
        $ScriptPath = $PSScriptRoot
    }
    # Yolun sonundaki ters slash işaretini temizle (garanti olsun)
    $ScriptPath = $ScriptPath.TrimEnd('\')

    # --- 4. FORM SETUP ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VDOWNS PRIME | System Architect"
    $form.Size = New-Object System.Drawing.Size(1280, 850)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = $Color_Back
    $form.ForeColor = $Color_Text

    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.AutoPopDelay = 15000
    $tooltip.InitialDelay = 500
    $tooltip.ReshowDelay = 500
    $tooltip.IsBalloon = $false

    # --- 5. SIDEBAR ---
    $sidebar = New-Object System.Windows.Forms.Panel
    $sidebar.Size = New-Object System.Drawing.Size(260, 850)
    $sidebar.Location = New-Object System.Drawing.Point(0, 0)
    $sidebar.BackColor = $Color_Sidebar
    $form.Controls.Add($sidebar)

    $header = New-Object System.Windows.Forms.Label
    $header.Text = "VDOWNS`nPRIME"
    $header.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $header.ForeColor = $Color_Accent
    $header.AutoSize = $false
    $header.TextAlign = "MiddleCenter"
    $header.Size = New-Object System.Drawing.Size(260, 100)
    $header.Location = New-Object System.Drawing.Point(0, 15)
    $sidebar.Controls.Add($header)
    
    $subHeader = New-Object System.Windows.Forms.Label
    $subHeader.Text = "System Architect"
    $subHeader.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
    $subHeader.ForeColor = "Gray"
    $subHeader.AutoSize = $false
    $subHeader.TextAlign = "TopCenter"
    $subHeader.Size = New-Object System.Drawing.Size(260, 30)
    $subHeader.Location = New-Object System.Drawing.Point(0, 95)
    $sidebar.Controls.Add($subHeader)

    # --- 6. MAIN CONTAINER & PANELS ---
    $mainContainer = New-Object System.Windows.Forms.Panel
    $mainContainer.Size = New-Object System.Drawing.Size(1000, 800)
    $mainContainer.Location = New-Object System.Drawing.Point(270, 10)
    $mainContainer.BackColor = $Color_Back
    $form.Controls.Add($mainContainer)

    # Creating all 5 Panels
    $pnlInstall = New-Object System.Windows.Forms.Panel; $pnlInstall.Dock = "Fill"; $pnlInstall.Visible = $true; $mainContainer.Controls.Add($pnlInstall)
    $pnlTweaks  = New-Object System.Windows.Forms.Panel; $pnlTweaks.Dock = "Fill"; $pnlTweaks.Visible = $false; $mainContainer.Controls.Add($pnlTweaks)
    $pnlConfig  = New-Object System.Windows.Forms.Panel; $pnlConfig.Dock = "Fill"; $pnlConfig.Visible = $false; $mainContainer.Controls.Add($pnlConfig)
    $pnlDebloat = New-Object System.Windows.Forms.Panel; $pnlDebloat.Dock = "Fill"; $pnlDebloat.Visible = $false; $mainContainer.Controls.Add($pnlDebloat)
    $pnlUpdates = New-Object System.Windows.Forms.Panel; $pnlUpdates.Dock = "Fill"; $pnlUpdates.Visible = $false; $mainContainer.Controls.Add($pnlUpdates)

    # --- 7. NAVIGATION LOGIC ---
    function Show-Page ($targetPanel) {
        $pnlInstall.Visible = $false
        $pnlTweaks.Visible  = $false
        $pnlConfig.Visible  = $false
        $pnlDebloat.Visible = $false
        $pnlUpdates.Visible = $false
        $targetPanel.Visible = $true
        $targetPanel.BringToFront()
    }

    function Style-Btn ($btn) {
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.BackColor = $Color_Sidebar
        $btn.ForeColor = $Color_Text
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $btn.TextAlign = "MiddleLeft"
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btn.Add_MouseEnter({ $this.BackColor = "#333333" })
        $btn.Add_MouseLeave({ $this.BackColor = $Color_Sidebar })
    }

    # Navigation Buttons
    $btn1 = New-Object System.Windows.Forms.Button; $btn1.Text = "  > App Center (JSON)"; $btn1.Size = New-Object System.Drawing.Size(260, 55); $btn1.Location = New-Object System.Drawing.Point(0, 140); Style-Btn $btn1; $btn1.Add_Click({ Show-Page $pnlInstall }); $sidebar.Controls.Add($btn1)
    $btn2 = New-Object System.Windows.Forms.Button; $btn2.Text = "  > System Tweaks"; $btn2.Size = New-Object System.Drawing.Size(260, 55); $btn2.Location = New-Object System.Drawing.Point(0, 195); Style-Btn $btn2; $btn2.Add_Click({ Show-Page $pnlTweaks }); $sidebar.Controls.Add($btn2)
    $btn3 = New-Object System.Windows.Forms.Button; $btn3.Text = "  > Features & Config"; $btn3.Size = New-Object System.Drawing.Size(260, 55); $btn3.Location = New-Object System.Drawing.Point(0, 250); Style-Btn $btn3; $btn3.Add_Click({ Show-Page $pnlConfig }); $sidebar.Controls.Add($btn3)
    $btn4 = New-Object System.Windows.Forms.Button; $btn4.Text = "  > Debloater"; $btn4.Size = New-Object System.Drawing.Size(260, 55); $btn4.Location = New-Object System.Drawing.Point(0, 305); Style-Btn $btn4; $btn4.Add_Click({ Show-Page $pnlDebloat }); $sidebar.Controls.Add($btn4)
    $btn5 = New-Object System.Windows.Forms.Button; $btn5.Text = "  > Updates"; $btn5.Size = New-Object System.Drawing.Size(260, 55); $btn5.Location = New-Object System.Drawing.Point(0, 360); Style-Btn $btn5; $btn5.Add_Click({ Show-Page $pnlUpdates }); $sidebar.Controls.Add($btn5)
    
    $btnExit = New-Object System.Windows.Forms.Button; $btnExit.Text = "  X  TERMINATE"; $btnExit.Size = New-Object System.Drawing.Size(260, 55); $btnExit.Location = New-Object System.Drawing.Point(0, 750); Style-Btn $btnExit; $btnExit.ForeColor = $Color_Red; $btnExit.Add_Click({ $form.Close() }); $sidebar.Controls.Add($btnExit)


    # =========================================================================
    # TAB 1: INSTALL APPS (LOAD FROM JSON + EXE FIX)
    # =========================================================================
    $l_inst = New-Object System.Windows.Forms.Label; $l_inst.Text = "App Center (Database)"; $l_inst.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_inst.AutoSize = $true; $l_inst.Location = New-Object System.Drawing.Point(20, 10); $pnlInstall.Controls.Add($l_inst)

    $flowInstall = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowInstall.Location = New-Object System.Drawing.Point(20, 60); $flowInstall.Size = New-Object System.Drawing.Size(960, 600); $flowInstall.AutoScroll = $true; $pnlInstall.Controls.Add($flowInstall)
    $script:InstallList = @() 

    # --- JSON LOADING LOGIC ---
    try {
        $jsonPath = Join-Path $ScriptPath "apps.json"
        
        if (Test-Path $jsonPath) {
            # Read JSON file
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            
            # Loop through Categories in JSON
            foreach ($categoryName in $jsonContent.PSObject.Properties.Name) {
                
                # Create GroupBox for Category
                $grp = New-Object System.Windows.Forms.GroupBox
                $grp.Text = $categoryName
                $grp.ForeColor = $Color_Accent
                $grp.Size = New-Object System.Drawing.Size(300, 380)
                $grp.Margin = New-Object System.Windows.Forms.Padding(5)
                $grp.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

                # Create Inner Panel
                $p = New-Object System.Windows.Forms.FlowLayoutPanel; $p.Dock = "Fill"; $p.FlowDirection = "TopDown"; $p.AutoScroll = $true; $grp.Controls.Add($p)

                # Loop through Apps in Category
                $appsInCategory = $jsonContent.$categoryName
                foreach ($app in $appsInCategory) {
                    $cb = New-Object System.Windows.Forms.CheckBox
                    $cb.Text = $app.Name
                    $cb.AutoSize = $true
                    $cb.ForeColor = $Color_Text
                    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
                    $cb.Margin = New-Object System.Windows.Forms.Padding(3)
                    
                    $tooltip.SetToolTip($cb, $app.Desc)
                    
                    $p.Controls.Add($cb)
                    $script:InstallList += @{Check=$cb; Id=$app.Id; Name=$app.Name}
                }
                $flowInstall.Controls.Add($grp)
            }
        } else {
            # ERROR STATE IF JSON MISSING
            $errLbl = New-Object System.Windows.Forms.Label
            $errLbl.Text = "CRITICAL ERROR: 'apps.json' Database Not Found!`n`nPlease ensure 'apps.json' exists in:`n$ScriptPath"
            $errLbl.ForeColor = $Color_Red
            $errLbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $errLbl.AutoSize = $true
            $flowInstall.Controls.Add($errLbl)
        }

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Database Error: " + $_.Exception.Message)
    }

    # Install Button
    $btnInst = New-Object System.Windows.Forms.Button; $btnInst.Text = "INITIALIZE SELECTED INSTALLATIONS"; $btnInst.Size = New-Object System.Drawing.Size(960, 40); $btnInst.Location = New-Object System.Drawing.Point(20, 680); $btnInst.BackColor = $Color_Green; $btnInst.FlatStyle = "Flat"; $btnInst.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnInst.Add_Click({ 
        $form.WindowState = "Minimized"
        foreach($a in $script:InstallList){ 
            if($a.Check.Checked -and $a.Id -ne "") { 
                Start-Process "winget" -ArgumentList "install --id $($a.Id) -e --silent --accept-package-agreements --accept-source-agreements --force" -Wait 
            } 
        }
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Deployment Sequence Complete.")
    }); $pnlInstall.Controls.Add($btnInst)


    # =========================================================================
    # TAB 2: TWEAKS
    # =========================================================================
    $l_tw = New-Object System.Windows.Forms.Label; $l_tw.Text = "System Tweaks & Optimization"; $l_tw.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_tw.AutoSize = $true; $l_tw.Location = New-Object System.Drawing.Point(20, 10); $pnlTweaks.Controls.Add($l_tw)

    # Profiles (CTT Logic)
    $pnlProfiles = New-Object System.Windows.Forms.FlowLayoutPanel; $pnlProfiles.Location = New-Object System.Drawing.Point(20, 50); $pnlProfiles.Size = New-Object System.Drawing.Size(960, 50); $pnlTweaks.Controls.Add($pnlProfiles)
    function Add-ProfileBtn ($txt, $action) {
        $b = New-Object System.Windows.Forms.Button; $b.Text = $txt; $b.AutoSize = $true; $b.BackColor = $Color_Accent; $b.ForeColor = "Black"; $b.FlatStyle = "Flat"; $b.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $b.Margin = New-Object System.Windows.Forms.Padding(0,0,10,0); $b.Add_Click($action); $pnlProfiles.Controls.Add($b)
    }

    Add-ProfileBtn "PROFILE: DESKTOP (Recommended)" { $script:TweakList | Where-Object {$_.Tag -eq "Essential" -or $_.Tag -eq "UI"} | ForEach-Object { $_.Check.Checked = $true } }
    Add-ProfileBtn "PROFILE: LAPTOP (Efficiency)" { $script:TweakList | Where-Object {$_.Tag -eq "Power"} | ForEach-Object { $_.Check.Checked = $true } }
    Add-ProfileBtn "RESET SELECTION" { $script:TweakList | ForEach-Object { $_.Check.Checked = $false } }

    $flowTweaks = New-Object System.Windows.Forms.FlowLayoutPanel; $flowTweaks.Location = New-Object System.Drawing.Point(20, 110); $flowTweaks.Size = New-Object System.Drawing.Size(960, 550); $flowTweaks.AutoScroll = $true; $pnlTweaks.Controls.Add($flowTweaks)
    $script:TweakList = @()

    function Add-TweakGroup ($title, $tweaks) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $title; $grp.ForeColor = "White"; $grp.Size = New-Object System.Drawing.Size(300, 400); $grp.Margin = New-Object System.Windows.Forms.Padding(5); $grp.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $p = New-Object System.Windows.Forms.FlowLayoutPanel; $p.Dock = "Fill"; $p.FlowDirection = "TopDown"; $p.AutoScroll = $true; $grp.Controls.Add($p)
        foreach ($t in $tweaks) {
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $t.Name; $cb.AutoSize = $true; $cb.ForeColor = "#dddddd"; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9); $cb.Margin = New-Object System.Windows.Forms.Padding(3)
            $tooltip.SetToolTip($cb, $t.Desc)
            $p.Controls.Add($cb)
            $script:TweakList += @{Check=$cb; Action=$t.Action; Tag=$t.Tag}
        }
        $flowTweaks.Controls.Add($grp)
    }

    # -- MERGED TWEAKS --
    $essentialTweaks = @(
        @{Name="Create Restore Point"; Desc="Highly Recommended!"; Tag="Essential"; Action={ Checkpoint-Computer -Description "VDOWNSPrimeRestore" -RestorePointType "MODIFY_SETTINGS" }},
        @{Name="Run O&O ShutUp10"; Desc="Runs privacy config"; Tag="Essential"; Action={ $url = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"; Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\OOSU10.exe"; Start-Process "$env:TEMP\OOSU10.exe" }},
        @{Name="Disable Telemetry"; Desc="Disables Windows diag tracking"; Tag="Essential"; Action={ Set-Service DiagTrack -StartupType Disabled; Stop-Service DiagTrack }},
        @{Name="Disable Ad ID"; Desc="Stops apps from using advertising ID"; Tag="Essential"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }}
    )

    $uiTweaks = @(
        @{Name="Dark Mode (System)"; Desc="Enables Dark Mode"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 }},
        @{Name="Dark Mode (Apps)"; Desc="Enables Dark Mode for Apps"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 }},
        @{Name="Show Hidden Files"; Desc="Makes hidden files visible"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 }},
        @{Name="Show File Extensions"; Desc="Shows .exe, .txt"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }},
        @{Name="Launch to 'This PC'"; Desc="Explorer opens This PC not Quick Access"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 }},
        @{Name="Classic Context Menu"; Desc="Restores Win10 Right Click"; Tag="UI"; Action={ reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve }},
        @{Name="Align Taskbar Left"; Desc="Moves Win11 Start to Left"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 }},
        @{Name="Hide Search Icon"; Desc="Removes Search from Taskbar"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 }},
        @{Name="Shrink Search Box"; Desc="Makes search box an icon"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 }},
        @{Name="Clipboard History"; Desc="Enable Win+V"; Tag="UI"; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" "EnableClipboardHistory" 1 }}
    )

    $perfTweaks = @(
        @{Name="Disable Sticky Keys"; Desc="Stops Shift key popup"; Tag="Power"; Action={ Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" }},
        @{Name="Enable Hibernate"; Desc="Adds Hibernate to Start Menu"; Tag="Power"; Action={ powercfg /hibernate on }},
        @{Name="Storage Sense"; Desc="Auto cleans temp files"; Tag="Power"; Action={ try { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 1 } catch {} }},
        @{Name="Ultimate Performance"; Desc="Unlocks Power Plan"; Tag="Power"; Action={ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }},
        @{Name="Disable SysMain"; Desc="Disables Superfetch (SSD)"; Tag="Power"; Action={ Set-Service SysMain -StartupType Disabled; Stop-Service SysMain }},
        @{Name="Disable Game DVR"; Desc="Turns off Xbox recording"; Tag="Power"; Action={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }}
    )

    Add-TweakGroup "Essential & Privacy" $essentialTweaks
    Add-TweakGroup "Interface & Explorer" $uiTweaks
    Add-TweakGroup "Performance & Power" $perfTweaks

    $btnApplyT = New-Object System.Windows.Forms.Button; $btnApplyT.Text = "EXECUTE TWEAKS"; $btnApplyT.Size = New-Object System.Drawing.Size(960, 40); $btnApplyT.Location = New-Object System.Drawing.Point(20, 680); $btnApplyT.BackColor = "#6c5ce7"; $btnApplyT.FlatStyle = "Flat"; $btnApplyT.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnApplyT.Add_Click({ 
        $form.WindowState = "Minimized"
        foreach($t in $script:TweakList){ if($t.Check.Checked){ Invoke-Command -ScriptBlock $t.Action } }
        Stop-Process -Name explorer -Force
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Optimization Complete. Explorer Restarted.")
    }); $pnlTweaks.Controls.Add($btnApplyT)


    # =========================================================================
    # TAB 3: CONFIG & WINDOWS FEATURES
    # =========================================================================
    $l_cf = New-Object System.Windows.Forms.Label; $l_cf.Text = "Windows Features & Maintenance"; $l_cf.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_cf.AutoSize = $true; $l_cf.Location = New-Object System.Drawing.Point(20, 10); $pnlConfig.Controls.Add($l_cf)

    $flowFeat = New-Object System.Windows.Forms.FlowLayoutPanel; $flowFeat.Location = New-Object System.Drawing.Point(20, 60); $flowFeat.Size = New-Object System.Drawing.Size(960, 500); $pnlConfig.Controls.Add($flowFeat)
    $script:FeatureList = @()

    function Add-FeatureItem ($name, $winName, $desc) {
        $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $name; $cb.AutoSize = $true; $cb.ForeColor = "White"; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $cb.Margin = New-Object System.Windows.Forms.Padding(10)
        $tooltip.SetToolTip($cb, $desc)
        $flowFeat.Controls.Add($cb)
        $script:FeatureList += @{Check=$cb; WinName=$winName}
    }

    Add-FeatureItem "Hyper-V Platform" "Microsoft-Hyper-V-All" "Enables Hyper-V for VMs"
    Add-FeatureItem "WSL 2 (Linux Subsystem)" "Microsoft-Windows-Subsystem-Linux" "Run Linux on Windows"
    Add-FeatureItem "Windows Sandbox" "Containers-DisposableClientVM" "Temporary Desktop Environment"
    Add-FeatureItem "Telnet Client" "TelnetClient" "For network debugging"
    Add-FeatureItem ".NET Framework 3.5" "NetFx3" "Required for older games/apps"

    $btnFeat = New-Object System.Windows.Forms.Button; $btnFeat.Text = "ENABLE SELECTED FEATURES"; $btnFeat.Size = New-Object System.Drawing.Size(400, 50); $btnFeat.Location = New-Object System.Drawing.Point(20, 580); $btnFeat.BackColor = "#e17055"; $btnFeat.FlatStyle = "Flat"; $btnFeat.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnFeat.Add_Click({ 
        $form.WindowState = "Minimized"
        foreach($f in $script:FeatureList){ 
            if($f.Check.Checked){ Write-Host "Enabling $($f.WinName)..."; Enable-WindowsOptionalFeature -Online -FeatureName $f.WinName -All -NoRestart } 
        }
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Features Enabled. System Restart Required.")
    }); $pnlConfig.Controls.Add($btnFeat)

    $btnTemp = New-Object System.Windows.Forms.Button; $btnTemp.Text = "DEEP SYSTEM CLEAN"; $btnTemp.Size = New-Object System.Drawing.Size(400, 50); $btnTemp.Location = New-Object System.Drawing.Point(440, 580); $btnTemp.BackColor = $Color_Red; $btnTemp.FlatStyle = "Flat"; $btnTemp.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnTemp.Add_Click({ Cleanmgr /sagerun:1 }); $pnlConfig.Controls.Add($btnTemp)


    # =========================================================================
    # TAB 4: DEBLOAT
    # =========================================================================
    $l_deb = New-Object System.Windows.Forms.Label; $l_deb.Text = "System Debloater"; $l_deb.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_deb.AutoSize = $true; $l_deb.Location = New-Object System.Drawing.Point(20, 10); $pnlDebloat.Controls.Add($l_deb)

    $flowDebloat = New-Object System.Windows.Forms.FlowLayoutPanel; $flowDebloat.Location = New-Object System.Drawing.Point(20, 60); $flowDebloat.Size = New-Object System.Drawing.Size(960, 550); $flowDebloat.FlowDirection = "TopDown"; $pnlDebloat.Controls.Add($flowDebloat)
    $script:DebloatList = @()

    $bloatItems = [ordered]@{
        "News & Weather" = @("*BingNews*","*BingWeather*", "Removes default News/Weather");
        "Help & Tips" = @("*GetHelp*","*Getstarted*", "Removes Get Help/Tips");
        "3D Viewer & Office Hub" = @("*Microsoft3DViewer*","*MicrosoftOfficeHub*", "Removes 3D Viewer/Office");
        "Solitaire Collection" = @("*MicrosoftSolitaireCollection*", "Removes Solitaire");
        "Communication Apps" = @("*People*","*SkypeApp*","*YourPhone*","*windowscommunicationsapps*", "Removes People/Skype/Phone");
        "Feedback Hub" = @("*WindowsFeedbackHub*", "Removes Feedback Hub");
        "Legacy Media" = @("*ZuneMusic*","*ZuneVideo*", "Removes Groove/Movies");
        "Cortana" = @("*Cortana*", "Removes Cortana");
        "Windows Maps" = @("*WindowsMaps*", "Removes Maps");
        "Sound Recorder" = @("*WindowsSoundRecorder*", "Removes Voice Recorder");
        "Photos App" = @("*Windows.Photos*", "Removes Photos (Caution!)")
    }

    foreach ($k in $bloatItems.Keys) {
        $data = $bloatItems[$k]
        $patterns = $data[0..($data.Count-2)]
        $desc = $data[-1]
        $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $k; $cb.Checked = $true; $cb.AutoSize = $true; $cb.ForeColor = "White"; $cb.Font = New-Object System.Drawing.Font("Segoe UI", 12); $cb.Margin = New-Object System.Windows.Forms.Padding(0,0,0,15)
        $tooltip.SetToolTip($cb, $desc)
        $flowDebloat.Controls.Add($cb)
        $script:DebloatList += @{Check=$cb; Pat=$patterns}
    }

    $btnClean = New-Object System.Windows.Forms.Button; $btnClean.Text = "INITIATE DEBLOAT SEQUENCE"; $btnClean.Size = New-Object System.Drawing.Size(300, 50); $btnClean.Location = New-Object System.Drawing.Point(20, 660); $btnClean.BackColor = $Color_Red; $btnClean.ForeColor = "White"; $btnClean.FlatStyle = "Flat"; $btnClean.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); 
    $btnClean.Add_Click({
        $form.WindowState = "Minimized"
        Write-Host "Purging Bloatware..." -ForegroundColor Yellow
        foreach ($item in $script:DebloatList) {
            if ($item.Check.Checked) {
                foreach ($p in $item.Pat) { Write-Host "Removing: $p"; Get-AppxPackage | Where-Object {$_.Name -like $p} | Remove-AppxPackage -ErrorAction SilentlyContinue }
            }
        }
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Debloat Sequence Completed!")
    }); $pnlDebloat.Controls.Add($btnClean)


    # =========================================================================
    # TAB 5: UPDATES
    # =========================================================================
    $l_up = New-Object System.Windows.Forms.Label; $l_up.Text = "System Update Center"; $l_up.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $l_up.AutoSize = $true; $l_up.Location = New-Object System.Drawing.Point(20, 10); $pnlUpdates.Controls.Add($l_up)

    $btnUp = New-Object System.Windows.Forms.Button; $btnUp.Text = "UPDATE ALL APPS (Winget)"; $btnUp.Size = New-Object System.Drawing.Size(350, 60); $btnUp.Location = New-Object System.Drawing.Point(20, 80); $btnUp.BackColor = $Color_Yellow; $btnUp.FlatStyle = "Flat"; $btnUp.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); 
    $btnUp.Add_Click({
        $form.WindowState = "Minimized"
        Write-Host "Updating Repository & Apps..." -ForegroundColor Cyan
        Start-Process "winget" -ArgumentList "upgrade --all --include-unknown --accept-package-agreements" -NoNewWindow -Wait
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Applications Updated.")
    }); $pnlUpdates.Controls.Add($btnUp)

    $btnWinUp = New-Object System.Windows.Forms.Button; $btnWinUp.Text = "FORCE WINDOWS UPDATE"; $btnWinUp.Size = New-Object System.Drawing.Size(350, 60); $btnWinUp.Location = New-Object System.Drawing.Point(20, 160); $btnWinUp.BackColor = $Color_Green; $btnWinUp.FlatStyle = "Flat"; $btnWinUp.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); 
    $btnWinUp.Add_Click({
        $form.WindowState = "Minimized"
        Write-Host "Checking for Update Module..." -ForegroundColor Cyan
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "Installing PSWindowsUpdate Module..." -ForegroundColor Yellow
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser
        }
        Write-Host "Initializing Windows Update..." -ForegroundColor Green
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
        $form.WindowState = "Normal"
        [System.Windows.Forms.MessageBox]::Show("Windows Update Cycle Finished.")
    }); $pnlUpdates.Controls.Add($btnWinUp)

    # --- SHOW ---
    $form.ShowDialog() | Out-Null

} catch {
    Write-Host "Critical Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}