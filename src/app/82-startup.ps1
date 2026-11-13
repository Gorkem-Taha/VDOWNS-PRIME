# =============================================================================
# 13D. STARTUP PROGRAMS OPTIMIZER
# =============================================================================
$script:StartupItemsList = [System.Collections.ArrayList]::new()
$script:StartupStoreV2 = "HKCU:\Software\VDOWNS\DisabledStartupV2"
$script:StartupStoreLegacy = "HKCU:\Software\VDOWNS\DisabledStartup"

function Update-StartupList {
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
                $card.Background = (Get-VdBrush "#161B22")
                $card.BorderBrush = (Get-VdBrush "#21262D")
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
                $lblN.Foreground = (Get-VdBrush "#E6EDF3")
                $lblN.FontSize = 12.5

                $lblC = New-Object System.Windows.Controls.TextBlock
                $lblC.Text = $val
                $lblC.Foreground = (Get-VdBrush "#8B949E")
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
                    $statusBorder.Background = (Get-VdBrush "#3D1F24")
                    $statusText.Text = "DISABLED"
                    $statusText.Foreground = (Get-VdBrush "#F85149")
                } else {
                    $statusBorder.Background = (Get-VdBrush "#1F3D2A")
                    $statusText.Text = "ENABLED"
                    $statusText.Foreground = (Get-VdBrush "#3FB950")
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

if ($btnScanStartup) { $btnScanStartup.Add_Click({ Update-StartupList }) }

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
        Update-StartupList
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
        Update-StartupList
    })
}

