# =============================================================================
# 4. PARSE XAML AND FIND ELEMENTS
# =============================================================================
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$window.Title = "VDOWNS PRIME v$($script:VdownsVersion) | Fluent System Architect"

# Every x:Name becomes a script-scope variable ($btnInstall, $logBox, ...) and an entry in
# $script:Controls. Event handlers run in this scope, so nothing needs to be global.
$script:Controls = @{}
$nsmgr = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$nsmgr.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
foreach ($node in $xaml.SelectNodes('//*[@x:Name]', $nsmgr)) {
    $elName = $node.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
    $el = if ($elName) { $window.FindName($elName) }
    if ($el) {
        Set-Variable -Name $elName -Value $el -Scope Script -Force
        $script:Controls[$elName] = $el
    }
}

function Get-UIElement {
    param([string]$Name)
    if ($script:Controls.ContainsKey($Name)) { return $script:Controls[$Name] }
    return $window.FindName($Name)
}

if ($lblVersionBadge) { $lblVersionBadge.Text = "v$($script:VdownsVersion)" }

# Brushes: one frozen instance per colour, shared by every card and dialog
$converter = New-Object System.Windows.Media.BrushConverter
$script:BrushCache = @{}
function Get-VdBrush([string]$Hex) {
    if (-not $script:BrushCache.ContainsKey($Hex)) {
        $b = $converter.ConvertFrom($Hex)
        if ($b.CanFreeze) { $b.Freeze() }
        $script:BrushCache[$Hex] = $b
    }
    $script:BrushCache[$Hex]
}
$accentBrush  = $converter.ConvertFrom("#58A6FF")
$successBrush = $converter.ConvertFrom("#3FB950")
$dangerBrush  = $converter.ConvertFrom("#F85149")
$textBrush    = $converter.ConvertFrom("#E6EDF3")
$textDimBrush = $converter.ConvertFrom("#8B949E")
$surfaceBrush = $converter.ConvertFrom("#161B22")
$borderBrush  = $converter.ConvertFrom("#30363D")
$hoverBrush   = $converter.ConvertFrom("#1F2937")

