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

