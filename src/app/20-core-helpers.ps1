# =============================================================================
# 5. DATA STORES AND HELPER FUNCTIONS
# =============================================================================
$script:DefaultAppsJson = @'
#@include ../apps.json
'@

$script:InstallList  = [System.Collections.ArrayList]::new()
$script:TweakList    = [System.Collections.ArrayList]::new()
$script:FeatureList  = [System.Collections.ArrayList]::new()
$script:DebloatList  = [System.Collections.ArrayList]::new()
$script:WingetList   = [System.Collections.ArrayList]::new()

function Write-AppLog {
    param([string]$Text, [string]$Type = "INFO")
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logBox.AppendText("[$timestamp] [$Type] $Text`r`n")
    $logBox.ScrollToEnd()
}

function Switch-AppTab {
    param([string]$TabName)
    $vCur = Get-UIElement "viewCurated"; $vWin = Get-UIElement "viewWinget"
    $bCur = Get-UIElement "btnTabCurated"; $bWin = Get-UIElement "btnTabWinget"
    if ($TabName -eq "winget") {
        if ($vCur) { $vCur.Visibility = "Collapsed" }
        if ($vWin) { $vWin.Visibility = "Visible" }
        if ($bCur) { $bCur.Tag = $null }
        if ($bWin) { $bWin.Tag = "Active" }
    } else {
        if ($vCur) { $vCur.Visibility = "Visible" }
        if ($vWin) { $vWin.Visibility = "Collapsed" }
        if ($bCur) { $bCur.Tag = "Active" }
        if ($bWin) { $bWin.Tag = $null }
    }
}

function Show-Page {
    param([string]$PageName)
    $pInst = Get-UIElement "pageInstall"; if ($pInst) { $pInst.Visibility = "Collapsed" }
    $pTwk  = Get-UIElement "pageTweaks";  if ($pTwk)  { $pTwk.Visibility  = "Collapsed" }
    $pCfg  = Get-UIElement "pageConfig";  if ($pCfg)  { $pCfg.Visibility  = "Collapsed" }
    $pDeb  = Get-UIElement "pageDebloat"; if ($pDeb)  { $pDeb.Visibility  = "Collapsed" }
    $pUpd  = Get-UIElement "pageUpdates"; if ($pUpd)  { $pUpd.Visibility  = "Collapsed" }
    $pBak  = Get-UIElement "pageBackup";  if ($pBak)  { $pBak.Visibility  = "Collapsed" }
    $pWin  = Get-UIElement "pageWinget";  if ($pWin)  { $pWin.Visibility  = "Collapsed" }

    $bInst = Get-UIElement "btnMenuInstall"; if ($bInst) { $bInst.Tag = $null }
    $bTwk  = Get-UIElement "btnMenuTweaks";  if ($bTwk)  { $bTwk.Tag  = $null }
    $bCfg  = Get-UIElement "btnMenuConfig";  if ($bCfg)  { $bCfg.Tag  = $null }
    $bDeb  = Get-UIElement "btnMenuDebloat"; if ($bDeb)  { $bDeb.Tag  = $null }
    $bUpd  = Get-UIElement "btnMenuUpdates"; if ($bUpd)  { $bUpd.Tag  = $null }
    $bBak  = Get-UIElement "btnMenuBackup";  if ($bBak)  { $bBak.Tag  = $null }
    $bWin  = Get-UIElement "btnMenuWinget";  if ($bWin)  { $bWin.Tag  = $null }

    switch ($PageName) {
        "install" {
            if ($pInst) { $pInst.Visibility = "Visible" }
            if ($bInst) { $bInst.Tag = "Active" }
            Switch-AppTab "curated"
        }
        "winget"  {
            if ($pInst) { $pInst.Visibility = "Visible" }
            if ($bInst) { $bInst.Tag = "Active" }
            Switch-AppTab "winget"
        }
        "tweaks"  { if ($pTwk)  { $pTwk.Visibility  = "Visible" }; if ($bTwk)  { $bTwk.Tag  = "Active" } }
        "config"  { if ($pCfg)  { $pCfg.Visibility  = "Visible" }; if ($bCfg)  { $bCfg.Tag  = "Active" } }
        "debloat" { if ($pDeb)  { $pDeb.Visibility  = "Visible" }; if ($bDeb)  { $bDeb.Tag  = "Active" } }
        "updates" { if ($pUpd)  { $pUpd.Visibility  = "Visible" }; if ($bUpd)  { $bUpd.Tag  = "Active" } }
        "backup"  { if ($pBak)  { $pBak.Visibility  = "Visible" }; if ($bBak)  { $bBak.Tag  = "Active" } }
    }
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        [System.Windows.MessageBox]::Show(
            "Winget (Windows Package Manager) is not installed.`nPlease install it from the Microsoft Store or GitHub.",
            "Winget Not Found", "OK", "Warning")
        return $false
    }
}

# Hidden native-process runner shared by the UI thread and every background runspace.
# CreateNoWindow keeps console tools (winget, powercfg, code) from flashing a window in the
# -noConsole exe; stderr is drained asynchronously so a full stderr pipe cannot deadlock stdout.
$script:VdNativeLib = @'
#@include lib/VdNative.ps1
'@
. ([scriptblock]::Create($script:VdNativeLib))

# Completion watcher for background runspaces. Deliberately no closure: the tick handler and
# OnComplete run in the script's scope, so script functions (Write-AppLog, Get-UIElement, ...)
# resolve both in the compiled .exe and when the .ps1 is started with -File.
function Watch-Runspace {
    param($PS, $Handle, $Runspace, [scriptblock]$OnComplete)
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds(400)
    $t.Tag = @{ PS = $PS; Handle = $Handle; Runspace = $Runspace; OnComplete = $OnComplete }
    $t.Add_Tick({
        $st = $this.Tag
        if (-not $st.Handle.IsCompleted) { return }
        $this.Stop()
        $result = $null
        try { $result = $st.PS.EndInvoke($st.Handle) } catch { Write-AppLog "Background task failed: $($_.Exception.Message)" "ERROR" }
        foreach ($e in @($st.PS.Streams.Error)) { Write-AppLog "Background task error: $($e.Exception.Message)" "ERROR" }
        $st.PS.Dispose()
        $st.Runspace.Close()
        if ($st.OnComplete) {
            try { & $st.OnComplete $result } catch { Write-AppLog "Completion handler failed: $($_.Exception.Message)" "ERROR" }
        }
    })
    $t.Start()
}

# Background task library (src/lib/Tasks.ps1), loaded into every task runspace.
$script:VdTasksLib = @'
#@include lib/Tasks.ps1
'@

# Context handed to a task: the window (for its Dispatcher) and the controls it may update.
function New-VdTaskContext {
    param($ProgressBar, $ProgressText)
    [hashtable]::Synchronized(@{ Window = $window; LogBox = $logBox; ProgressBar = $ProgressBar; ProgressText = $ProgressText })
}

# Runs one function from the task library in a fresh runspace; OnComplete gets its output on
# the UI thread (see Watch-Runspace). The only place that creates runspaces.
function Start-VdTask {
    param([string]$Command, [hashtable]$Parameters = @{}, [scriptblock]$OnComplete)
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript((@($script:VdNativeLib, $script:TweakStateLib, $script:VdTasksLib) -join "`n"))
    [void]$ps.AddStatement().AddCommand($Command)
    foreach ($k in $Parameters.Keys) { [void]$ps.AddParameter($k, $Parameters[$k]) }
    $handle = $ps.BeginInvoke()
    Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete $OnComplete
}

function Start-StreamingCommand {
    param([string]$FileName, [string]$Arguments)
    $shown = if ($FileName -eq "powershell.exe" -and $Arguments -match '-EncodedCommand') { "powershell.exe (script)" } else { "$FileName $Arguments" }
    Write-AppLog $shown "CMD"
    Start-VdTask 'Invoke-VdStream' @{ FileName = $FileName; Arguments = $Arguments; SH = (New-VdTaskContext) }
}

function Start-PSStreamingCommand {
    param([string]$PSScript)
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($PSScript)
    $encoded = [Convert]::ToBase64String($bytes)
    Start-StreamingCommand "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
}

