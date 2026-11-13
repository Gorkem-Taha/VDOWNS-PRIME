# Shared helpers for the Pester suites. Dot-source from BeforeAll.
# Works in Windows PowerShell 5.1 and PowerShell 7 (Windows and Linux).

$script:RepoRoot   = Split-Path $PSScriptRoot -Parent
$script:ScriptPath = Join-Path $script:RepoRoot 'VDOWNS_PRIME.ps1'
$script:SrcRoot    = Join-Path $script:RepoRoot 'src'
$script:OnWindows  = ($env:OS -eq 'Windows_NT')

function Get-VdScriptText {
    [System.IO.File]::ReadAllText($script:ScriptPath, [System.Text.Encoding]::UTF8)
}

function Get-VdScriptAst {
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors)
    if ($errors) { throw "VDOWNS_PRIME.ps1 does not parse: $($errors[0].Message)" }
    $ast
}

# Returns the source text of the first top-level-or-nested assignment to $Name
# (e.g. 'essentialTweaks' or 'script:TweakStateLib'), ready to dot-source.
function Get-VdAssignmentText([string]$Name) {
    $ast = Get-VdScriptAst
    $a = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq "`$$Name" }, $true) | Select-Object -First 1
    if (-not $a) { throw "Assignment `$$Name not found" }
    $a.Extent.Text
}

function Get-VdFunctionText([string]$Name) {
    $ast = Get-VdScriptAst
    $f = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name }, $true) | Select-Object -First 1
    if (-not $f) { throw "Function $Name not found" }
    $f.Extent.Text
}

function Get-VdXaml {
    [xml](Get-Content (Join-Path $script:SrcRoot 'ui/MainWindow.xaml') -Raw -Encoding UTF8)
}

function Get-VdXamlNames {
    $x = Get-VdXaml
    $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
    $ns.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
    @($x.SelectNodes('//*[@x:Name]', $ns) | ForEach-Object { $_.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml') })
}

function Get-VdCatalogIds([object]$Catalog) {
    @(foreach ($p in $Catalog.PSObject.Properties) { foreach ($app in @($p.Value)) { $app.Id } })
}
