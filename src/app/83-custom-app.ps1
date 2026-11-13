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

