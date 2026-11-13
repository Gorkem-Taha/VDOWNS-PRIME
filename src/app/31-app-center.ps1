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
            Set-Content -Path $targetSave -Value $script:DefaultAppsJson -Encoding UTF8 -Force -ErrorAction Stop
            Write-AppLog "Restored default apps.json to: $targetSave" "SUCCESS"
        } catch { Write-AppLog "Could not write apps.json (using the built-in catalog): $($_.Exception.Message)" "WARN" }
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
                        if ($u -match '^https?://[^\s"]+$') { try { Start-Process -FilePath $u } catch { Write-AppLog "Could not open $u : $($_.Exception.Message)" "WARN" } }
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

# INSTALL / UNINSTALL selected catalog apps (background task)
function Start-AppBatch {
    param([ValidateSet('install', 'uninstall')][string]$Action)
    if (-not (Test-WingetAvailable)) { return }
    $selected = @($script:InstallList | Where-Object { $_.Check.IsChecked -eq $true -and $_.Id -ne "" })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No applications selected.", "Info", "OK", "Information")
        return
    }
    if ($Action -eq 'uninstall') {
        $result = [System.Windows.MessageBox]::Show("Selected apps will be REMOVED. Continue?", "Confirm Uninstall", "YesNo", "Warning")
        if ($result -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    $btnInstall.IsEnabled = $false
    $btnUninstall.IsEnabled = $false
    $panel = Get-UIElement "progressPanel"; if ($panel) { $panel.Visibility = "Visible" }
    $bar = Get-UIElement "progressBar"; if ($bar) { $bar.Value = 0 }

    $apps = @(foreach ($s in $selected) { @{ Id = $s.Id; Name = $s.Name } })
    $ctx = New-VdTaskContext -ProgressBar $bar -ProgressText (Get-UIElement "progressText")
    Start-VdTask 'Invoke-VdWingetBatch' @{ Apps = $apps; Action = $Action; SH = $ctx } -OnComplete {
        $btnInstall.IsEnabled = $true
        $btnUninstall.IsEnabled = $true
    }
    Write-AppLog "$(if ($Action -eq 'install') { 'Installation' } else { 'Uninstallation' }) started for $($apps.Count) apps..." "ACTION"
}

if ($btnInstall) { $btnInstall.Add_Click({ Start-AppBatch 'install' }) }
if ($btnUninstall) { $btnUninstall.Add_Click({ Start-AppBatch 'uninstall' }) }
