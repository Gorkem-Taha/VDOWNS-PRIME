# =============================================================================
# 4. PARSE XAML AND FIND ELEMENTS
# =============================================================================
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$script:window = $window
$window.Title = "VDOWNS PRIME v$($script:VdownsVersion) | Fluent System Architect"

# Auto-discover all named elements and register globally across scopes
$global:window = $window
$script:window = $window
$global:Controls = @{}
$script:Controls = @{}

$nsmgr = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$nsmgr.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
$nodes = $xaml.SelectNodes('//*[@x:Name]', $nsmgr)
foreach ($node in $nodes) {
    $elName = $node.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
    if ($elName) {
        $el = $window.FindName($elName)
        if ($el) {
            Set-Variable -Name $elName -Value $el -Scope Script -Force
            Set-Variable -Name $elName -Value $el -Scope Global -Force
            Set-Variable -Name $elName -Value $el -Force
            $global:Controls[$elName] = $el
            $script:Controls[$elName] = $el
        }
    }
}

function Get-UIElement {
    param([string]$Name)
    if ($global:Controls -and $global:Controls.ContainsKey($Name) -and $global:Controls[$Name]) { return $global:Controls[$Name] }
    if ($script:Controls -and $script:Controls.ContainsKey($Name) -and $script:Controls[$Name]) { return $script:Controls[$Name] }
    if ($window) { $c = $window.FindName($Name); if ($c) { return $c } }
    if ($script:window) { $c = $script:window.FindName($Name); if ($c) { return $c } }
    if ($global:window) { $c = $global:window.FindName($Name); if ($c) { return $c } }
    $v = Get-Variable -Name $Name -Scope Script -ErrorAction SilentlyContinue
    if ($v -and $v.Value) { return $v.Value }
    $v = Get-Variable -Name $Name -Scope Global -ErrorAction SilentlyContinue
    if ($v -and $v.Value) { return $v.Value }
    return $null
}

if ($lblVersionBadge) { $lblVersionBadge.Text = "v$($script:VdownsVersion)" }

# Explicit aliases for XAML to script element compatibility
$script:tweaksContainer = $script:tweakContainer; $tweaksContainer = $tweakContainer; $global:tweaksContainer = $tweakContainer
$script:configContainer = $script:featureContainer; $configContainer = $featureContainer; $global:configContainer = $featureContainer
$script:wingetItemsContainer = $script:wingetResultsContainer; $wingetItemsContainer = $wingetResultsContainer; $global:wingetItemsContainer = $wingetResultsContainer
$script:btnDebloat = $script:btnRemoveBloat; $btnDebloat = $btnRemoveBloat; $global:btnDebloat = $btnRemoveBloat
$script:btnSelectAll = $script:btnDebloatSelectAll; $btnSelectAll = $btnDebloatSelectAll; $global:btnSelectAll = $btnDebloatSelectAll
$script:btnDeselectAll = $script:btnDebloatClear; $btnDeselectAll = $btnDebloatClear; $global:btnDeselectAll = $btnDebloatClear
$script:btnEnableFeatures = $script:btnInstallFeatures; $btnEnableFeatures = $btnInstallFeatures; $global:btnEnableFeatures = $btnInstallFeatures
$script:btnSfc = $script:btnRepairSfc; $btnSfc = $btnRepairSfc; $global:btnSfc = $btnRepairSfc
$script:btnDism = $script:btnRepairDism; $btnDism = $btnRepairDism; $global:btnDism = $btnRepairDism
$script:btnNetReset = $script:btnResetNetwork; $btnNetReset = $btnResetNetwork; $global:btnNetReset = $btnResetNetwork
$script:btnFixWU = $script:btnFixUpdates; $btnFixWU = $btnFixUpdates; $global:btnFixWU = $btnFixUpdates
$script:btnSearchWingetRepo = $script:btnWingetSearch; $btnSearchWingetRepo = $btnWingetSearch; $global:btnSearchWingetRepo = $btnWingetSearch
$script:outputBox = $script:logBox; $outputBox = $logBox; $global:outputBox = $logBox

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

