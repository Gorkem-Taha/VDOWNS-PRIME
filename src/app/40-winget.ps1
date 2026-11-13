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

