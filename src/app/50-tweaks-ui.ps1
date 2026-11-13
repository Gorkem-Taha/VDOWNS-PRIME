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

