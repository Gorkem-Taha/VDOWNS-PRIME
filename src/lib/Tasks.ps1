# Background task library. Loaded (together with VdNative.ps1 and TweakState.ps1) into every
# runspace started by Start-VdTask, and dot-sourced directly by the Pester tests.
#
# $SH is a synchronized hashtable from New-VdTaskContext: Window (for its Dispatcher), LogBox and
# optionally ProgressBar/ProgressText. Every UI update is marshalled to the UI thread here, so the
# task functions themselves never touch WPF objects. All UI helpers are no-ops without a window.

# Each helper calls Dispatcher.Invoke itself, with the [action] literal next to the values it
# uses (the same pattern as the original handlers). UI errors never abort a background task.
function Write-VdTaskLog {
    param($SH, [string]$Text, [string]$Type = 'INFO')
    if (-not ($SH -and $SH.Window -and $SH.LogBox)) { return }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Type] $Text`r`n"
    try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText($line); $SH.LogBox.ScrollToEnd() }) }
    catch { Write-Verbose "Log line dropped: $($_.Exception.Message)" }
}

function Write-VdTaskRaw {
    param($SH, [string]$Text)
    if (-not ($SH -and $SH.Window -and $SH.LogBox)) { return }
    $line = "$Text`r`n"
    try { $SH.Window.Dispatcher.Invoke([action]{ $SH.LogBox.AppendText($line); $SH.LogBox.ScrollToEnd() }) }
    catch { Write-Verbose "Output line dropped: $($_.Exception.Message)" }
}

function Set-VdTaskProgress {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Used inside the Dispatcher [action] block')]
    param($SH, [string]$Text, [int]$Percent)
    if (-not ($SH -and $SH.Window)) { return }
    try {
        $SH.Window.Dispatcher.Invoke([action]{
            if ($SH.ProgressText) { $SH.ProgressText.Text = $Text }
            if ($SH.ProgressBar) { $SH.ProgressBar.Value = $Percent }
        })
    } catch { Write-Verbose "Progress update dropped: $($_.Exception.Message)" }
}

function Show-VdTaskMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Used inside the Dispatcher [action] block')]
    param($SH, [string]$Text, [string]$Title, [string]$Buttons = 'OK', [string]$Icon = 'Information')
    if (-not ($SH -and $SH.Window)) { return }
    try { $SH.Window.Dispatcher.Invoke([action]{ [void][System.Windows.MessageBox]::Show($Text, $Title, $Buttons, $Icon) }) }
    catch { Write-Verbose "Message box skipped: $($_.Exception.Message)" }
}

# ---- winget -------------------------------------------------------------------------------

$script:VdWingetAlreadyInstalled = -1978335189   # APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED

function Invoke-VdWingetBatch {
    param([object[]]$Apps, [ValidateSet('install', 'uninstall')][string]$Action, $SH)
    $verb = if ($Action -eq 'install') { 'Installing' } else { 'Uninstalling' }
    $done = 0; $failed = 0; $i = 0; $total = @($Apps).Count
    foreach ($app in $Apps) {
        $i++
        Set-VdTaskProgress -SH $SH -Text "${verb}: $($app.Name) ($i / $total)" -Percent ([math]::Round(($i / $total) * 100))
        $wgArgs = if ($Action -eq 'install') {
            @('install', '--id', $app.Id, '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        } else {
            @('uninstall', '--id', $app.Id, '-e', '--silent', '--accept-source-agreements', '--disable-interactivity', '--force')
        }
        try {
            $code = (Invoke-VdNative 'winget.exe' $wgArgs 'UTF8').ExitCode
            if ($code -eq 0) {
                $done++
                Write-VdTaskLog -SH $SH -Text "$(if ($Action -eq 'install') { 'Installed' } else { 'Uninstalled' }): $($app.Name)" -Type 'SUCCESS'
            } elseif ($Action -eq 'install' -and $code -eq $script:VdWingetAlreadyInstalled) {
                Write-VdTaskLog -SH $SH -Text "Already installed: $($app.Name)" -Type 'INFO'
            } else {
                $failed++
                Write-VdTaskLog -SH $SH -Text "Failed to $Action $($app.Name) (winget exit code $code)" -Type 'ERROR'
            }
        } catch {
            $failed++
            Write-VdTaskLog -SH $SH -Text "$($app.Name) - $($_.Exception.Message)" -Type 'ERROR'
        }
    }
    Set-VdTaskProgress -SH $SH -Text "All ${Action}s completed!" -Percent 100
    Write-VdTaskLog -SH $SH -Text "$verb finished: $done succeeded, $failed failed, $($total - $done - $failed) skipped." -Type 'INFO'
}

function Invoke-VdWingetQuery {
    param([ValidateSet('list', 'search')][string]$Kind, [string]$Query)
    $wgArgs = if ($Kind -eq 'list') { @('list') } else { @('search', $Query) }
    $r = Invoke-VdNative 'winget.exe' ($wgArgs + @('--accept-source-agreements', '--disable-interactivity')) 'UTF8'
    @(ConvertFrom-VdWingetTable $r.Output)
}

# ---- tweaks -------------------------------------------------------------------------------

# Apply: snapshot first (skip the tweak if that fails, so Revert can always restore), create
# missing registry keys, run the Do block with ErrorAction Stop and check native exit codes.
# Revert: restore the exact snapshot, or fall back to the generic Undo block.
function Invoke-VdTweakBatch {
    param([object[]]$Tweaks, [ValidateSet('Apply', 'Revert')][string]$Mode, $SH)
    $ErrorActionPreference = 'Stop'
    $count = 0
    foreach ($item in $Tweaks) {
        $tName = $item.Name
        try {
            $global:LASTEXITCODE = 0
            if ($Mode -eq 'Apply') {
                Save-VdTweakState $tName $item.State
                foreach ($e in @($item.State)) { if ($e -and $e.Reg -and -not (Test-Path -LiteralPath $e.Reg)) { New-Item -Path $e.Reg -Force | Out-Null } }
                $null = & ([scriptblock]::Create($item.ScriptStr))
                $how = ''
            } else {
                $how = if (Restore-VdTweakState $tName) { ' - original state restored' } else { $null = & ([scriptblock]::Create($item.ScriptStr)); ' - default undo applied (no snapshot)' }
            }
            if ($LASTEXITCODE -ne 0) { throw "command exited with code $LASTEXITCODE" }
            $count++
            Write-VdTaskLog -SH $SH -Text "$(if ($Mode -eq 'Apply') { 'Applied' } else { 'Reverted' }): $tName$how" -Type 'SUCCESS'
        } catch {
            Write-VdTaskLog -SH $SH -Text "Failed to $($Mode.ToLower()): $tName - $($_.Exception.Message)" -Type 'ERROR'
        }
    }
    if ($count -gt 0) {
        Write-VdTaskLog -SH $SH -Text 'Refreshing Windows Explorer...' -Type 'INFO'
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }
    return $count
}

# ---- debloat ------------------------------------------------------------------------------

function Invoke-VdDebloat {
    param([object[]]$Items, [bool]$Provisioned, $SH)
    $removed = 0
    $allPkgs = @(Get-AppxPackage)   # enumerate once, not once per pattern
    $allProv = if ($Provisioned) { @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) } else { @() }
    foreach ($item in $Items) {
        foreach ($p in $item.Patterns) {
            foreach ($pkg in @($allPkgs | Where-Object { $_.Name -like $p })) {
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                    $removed++
                    Write-VdTaskLog -SH $SH -Text "Removed: $($pkg.Name)" -Type 'SUCCESS'
                } catch {
                    Write-VdTaskLog -SH $SH -Text "Could not remove $($pkg.Name): $($_.Exception.Message)" -Type 'WARN'
                }
            }
            foreach ($prov in @($allProv | Where-Object { $_.DisplayName -like $p })) {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
                    $removed++
                    Write-VdTaskLog -SH $SH -Text "Removed provisioned package (new users): $($prov.DisplayName)" -Type 'SUCCESS'
                } catch {
                    Write-VdTaskLog -SH $SH -Text "Could not remove provisioned $($prov.DisplayName): $($_.Exception.Message)" -Type 'WARN'
                }
            }
        }
    }
    return $removed
}

# ---- live console -------------------------------------------------------------------------

# Streams a process' stdout into the log line by line; stderr is drained asynchronously.
function Invoke-VdStream {
    param([string]$FileName, [string]$Arguments, $SH)
    $exitCode = $null
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FileName
        $psi.Arguments = $Arguments
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        # winget writes UTF-8; classic tools use the OEM code page (sfc emits UTF-16, NULs stripped below)
        $enc = Get-VdProcessEncoding $(if ($FileName -match '^winget(\.exe)?$') { 'UTF8' } else { '' })
        $psi.StandardOutputEncoding = $enc
        $psi.StandardErrorEncoding = $enc
        $proc = [System.Diagnostics.Process]::Start($psi)
        $errTask = $proc.StandardError.ReadToEndAsync()
        while ($null -ne ($line = $proc.StandardOutput.ReadLine())) {
            $line = ($line -replace "`0", '').TrimEnd()
            # drop empty lines and winget/dism progress animation
            if ($line.Trim() -eq '' -or $line.Trim() -match '^[-\\|/]$' -or $line -match '[\u2580-\u259F]') { continue }
            Write-VdTaskRaw -SH $SH -Text $line
        }
        $proc.WaitForExit()
        $errOut = ($errTask.Result -replace "`0", '').Trim()
        if ($errOut) { Write-VdTaskRaw -SH $SH -Text $errOut }
        $exitCode = $proc.ExitCode
    } catch {
        Write-VdTaskRaw -SH $SH -Text "ERROR: $($_.Exception.Message)"
    }
    $status = if ($null -eq $exitCode) { 'FAILED TO START' } elseif ($exitCode -eq 0) { 'COMPLETED (exit code 0)' } else { "FINISHED WITH ERRORS (exit code $exitCode)" }
    Write-VdTaskRaw -SH $SH -Text "`r`n--- PROCESS $status ---"
    return $exitCode
}



# ---- backup / restore / Quick Boost (bodies moved verbatim from the click handlers) -------

function Invoke-VdConfigBackup {
    param([string]$DestZip, $SH)
    try {
        $tempDir = Join-Path $env:TEMP "VDOWNS_Backup_Temp"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        # 1. VS Code Settings & Extensions Manifest
        $vscodePath = Join-Path $env:APPDATA "Code\User"
        if (Test-Path $vscodePath) {
            $vsTarget = Join-Path $tempDir "VSCode_User"
            New-Item -ItemType Directory -Path $vsTarget -Force | Out-Null
            Get-ChildItem -Path $vscodePath -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $vsTarget -Recurse -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up VS Code user configurations." -Type "INFO"
        }
        try {
            $codeCmd = Get-Command code -ErrorAction SilentlyContinue
            if ($codeCmd) {
                $r = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--list-extensions') 'UTF8'
                Set-Content -Path (Join-Path $tempDir "vscode_extensions.txt") -Value $r.Output -Encoding UTF8
                Write-VdTaskLog -SH $SH -Text "Exported VS Code extensions manifest." -Type "INFO"
            }
        } catch { Write-VdTaskLog -SH $SH -Text "Could not export the VS Code extension list: $($_.Exception.Message)" -Type "WARN" }

        # 2. Cursor Settings
        $cursorPath = Join-Path $env:APPDATA "Cursor\User"
        if (Test-Path $cursorPath) {
            $curTarget = Join-Path $tempDir "Cursor_User"
            New-Item -ItemType Directory -Path $curTarget -Force | Out-Null
            Get-ChildItem -Path $cursorPath -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $curTarget -Recurse -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up Cursor user configurations." -Type "INFO"
        }

        # 3. Git Config
        $gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
        if (Test-Path $gitConfig) {
            Copy-Item $gitConfig -Destination (Join-Path $tempDir ".gitconfig") -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up Git configuration (.gitconfig)." -Type "INFO"
        }

        # 4. PowerShell Profiles ($PROFILE is not set inside a background runspace)
        $docsDir = [Environment]::GetFolderPath('MyDocuments')
        $winPsProfile = Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        $pwshProfile  = Join-Path $docsDir "PowerShell\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $winPsProfile) {
            Copy-Item $winPsProfile -Destination (Join-Path $tempDir "Microsoft.PowerShell_profile.ps1") -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up Windows PowerShell profile." -Type "INFO"
        }
        if (Test-Path $pwshProfile) {
            Copy-Item $pwshProfile -Destination (Join-Path $tempDir "PowerShell7_profile.ps1") -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up PowerShell 7 profile." -Type "INFO"
        }

        # 5. Windows Terminal
        $wtPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) {
            Copy-Item $wtPath -Destination (Join-Path $tempDir "Terminal_settings.json") -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up Windows Terminal settings." -Type "INFO"
        }

        # 6. Notepad++
        $nppPath = Join-Path $env:APPDATA "Notepad++"
        if (Test-Path $nppPath) {
            Copy-Item $nppPath -Destination (Join-Path $tempDir "NotepadPlusPlus") -Recurse -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up Notepad++ settings." -Type "INFO"
        }

        # 7. SSH Config (host mappings only, keys excluded for safety)
        $sshConfig = Join-Path $env:USERPROFILE ".ssh\config"
        if (Test-Path $sshConfig) {
            $sshTarget = Join-Path $tempDir "SSH_Config"
            New-Item -ItemType Directory -Path $sshTarget -Force | Out-Null
            Copy-Item $sshConfig -Destination (Join-Path $sshTarget "config") -Force -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "Backed up SSH host mappings." -Type "INFO"
        }

        # Compress
        Write-VdTaskLog -SH $SH -Text "Compressing developer backup snapshot into ZIP..." -Type "ACTION"
        if (Test-Path $destZip) { Remove-Item $destZip -Force }
        Compress-Archive -Path "$tempDir\*" -DestinationPath $destZip -Force
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "AppData Developer Backup completed successfully: $destZip" -Type "SUCCESS"
        Show-VdTaskMessage -SH $SH -Text "AppData configurations backup complete!`nFile: $destZip" -Title "Backup Complete" -Buttons "OK" -Icon "Information"
    } catch {
        Write-VdTaskLog -SH $SH -Text "Backup failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Invoke-VdConfigRestore {
    param([string]$SrcZip, $SH)
    try {
        $tempDir = Join-Path $env:TEMP "VDOWNS_Restore_Temp"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
        # Extract manually so no entry can escape the temp folder (zip-slip)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $rootFull = [System.IO.Path]::GetFullPath($tempDir).TrimEnd('\') + '\'
        $zip = [System.IO.Compression.ZipFile]::OpenRead($srcZip)
        try {
            foreach ($entry in $zip.Entries) {
                $target = [System.IO.Path]::GetFullPath((Join-Path $tempDir $entry.FullName))
                if (-not $target.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe path in archive, restore aborted: $($entry.FullName)"
                }
                if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) {
                    New-Item -ItemType Directory -Path $target -Force | Out-Null
                    continue
                }
                New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
            }
        } finally { $zip.Dispose() }

        # Save everything that is about to be overwritten; abort if that fails
        $docsDirSafe = [Environment]::GetFolderPath('MyDocuments')
        $safetyDir = Join-Path $env:LOCALAPPDATA ("VDOWNS\PreRestore_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $currentItems = @(
            @{ Zip = "VSCode_User";                      Path = (Join-Path $env:APPDATA "Code\User"); Dir = $true },
            @{ Zip = "Cursor_User";                      Path = (Join-Path $env:APPDATA "Cursor\User"); Dir = $true },
            @{ Zip = ".gitconfig";                       Path = (Join-Path $env:USERPROFILE ".gitconfig") },
            @{ Zip = "Microsoft.PowerShell_profile.ps1"; Path = (Join-Path $docsDirSafe "WindowsPowerShell\Microsoft.PowerShell_profile.ps1") },
            @{ Zip = "PowerShell7_profile.ps1";          Path = (Join-Path $docsDirSafe "PowerShell\Microsoft.PowerShell_profile.ps1") },
            @{ Zip = "Terminal_settings.json";           Path = (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json") },
            @{ Zip = "NotepadPlusPlus";                  Path = (Join-Path $env:APPDATA "Notepad++"); Dir = $true },
            @{ Zip = "SSH_Config";                       Path = (Join-Path $env:USERPROFILE ".ssh\config") }
        )
        $saved = 0
        foreach ($ci in $currentItems) {
            if (-not (Test-Path (Join-Path $tempDir $ci.Zip)) -or -not (Test-Path $ci.Path)) { continue }
            $dest = Join-Path $safetyDir $ci.Zip
            if ($ci.Dir) {
                New-Item -ItemType Directory -Path $dest -Force -ErrorAction Stop | Out-Null
                Get-ChildItem -Path $ci.Path -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $dest -Recurse -Force -ErrorAction Stop
            } else {
                New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force -ErrorAction Stop | Out-Null
                Copy-Item -Path $ci.Path -Destination $dest -Force -ErrorAction Stop
            }
            $saved++
        }
        if ($saved -gt 0) { Write-VdTaskLog -SH $SH -Text "Current settings saved before restore: $safetyDir" -Type "INFO" }

        # Restore VS Code
        if (Test-Path "$tempDir\VSCode_User") {
            $vscodeDest = Join-Path $env:APPDATA "Code\User"
            New-Item -ItemType Directory -Path $vscodeDest -Force | Out-Null
            Copy-Item "$tempDir\VSCode_User\*" -Destination $vscodeDest -Recurse -Force
            Write-VdTaskLog -SH $SH -Text "Restored VS Code configurations." -Type "SUCCESS"
        }

        # Restore Git Config
        if (Test-Path "$tempDir\.gitconfig") {
            Copy-Item "$tempDir\.gitconfig" -Destination (Join-Path $env:USERPROFILE ".gitconfig") -Force
            Write-VdTaskLog -SH $SH -Text "Restored Git configuration." -Type "SUCCESS"
        }

        # Restore Cursor
        if (Test-Path "$tempDir\Cursor_User") {
            $cursorDest = Join-Path $env:APPDATA "Cursor\User"
            New-Item -ItemType Directory -Path $cursorDest -Force | Out-Null
            Copy-Item "$tempDir\Cursor_User\*" -Destination $cursorDest -Recurse -Force
            Write-VdTaskLog -SH $SH -Text "Restored Cursor configurations." -Type "SUCCESS"
        }

        # Restore PowerShell Profiles ($PROFILE is not set inside a background runspace)
        $docsDir = [Environment]::GetFolderPath('MyDocuments')
        $profileMap = @(
            @{ Src = "Microsoft.PowerShell_profile.ps1"; Dest = Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"; Label = "Windows PowerShell" },
            @{ Src = "PowerShell7_profile.ps1";          Dest = Join-Path $docsDir "PowerShell\Microsoft.PowerShell_profile.ps1";        Label = "PowerShell 7" }
        )
        foreach ($pm in $profileMap) {
            $srcFile = Join-Path $tempDir $pm.Src
            if (Test-Path $srcFile) {
                New-Item -ItemType Directory -Path (Split-Path $pm.Dest -Parent) -Force | Out-Null
                Copy-Item $srcFile -Destination $pm.Dest -Force
                Write-VdTaskLog -SH $SH -Text "Restored $($pm.Label) profile." -Type "SUCCESS"
            }
        }

        # Restore Windows Terminal
        if (Test-Path "$tempDir\Terminal_settings.json") {
            $wtDest = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
            if (Test-Path $wtDest) {
                Copy-Item "$tempDir\Terminal_settings.json" -Destination (Join-Path $wtDest "settings.json") -Force
                Write-VdTaskLog -SH $SH -Text "Restored Windows Terminal settings." -Type "SUCCESS"
            }
        }

        # Restore Notepad++
        if (Test-Path "$tempDir\NotepadPlusPlus") {
            $nppDest = Join-Path $env:APPDATA "Notepad++"
            New-Item -ItemType Directory -Path $nppDest -Force | Out-Null
            Copy-Item "$tempDir\NotepadPlusPlus\*" -Destination $nppDest -Recurse -Force
            Write-VdTaskLog -SH $SH -Text "Restored Notepad++ settings." -Type "SUCCESS"
        }

        # Restore SSH Config
        if (Test-Path "$tempDir\SSH_Config\config") {
            $sshDir = Join-Path $env:USERPROFILE ".ssh"
            New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
            Copy-Item "$tempDir\SSH_Config\config" -Destination (Join-Path $sshDir "config") -Force
            Write-VdTaskLog -SH $SH -Text "Restored SSH host configurations." -Type "SUCCESS"
        }

        # Optional VS Code Extension Reinstall
        $extFile = Join-Path $tempDir "vscode_extensions.txt"
        if (Test-Path $extFile) {
            $codeCmd = Get-Command code -ErrorAction SilentlyContinue
            if ($codeCmd) {
                Write-VdTaskLog -SH $SH -Text "Reinstalling backed up VS Code extensions..." -Type "ACTION"
                $exts = Get-Content $extFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                foreach ($ext in $exts) {
                    Write-VdTaskLog -SH $SH -Text "Installing extension: $ext" -Type "INFO"
                    if ($ext -notmatch '^[A-Za-z0-9][\w\-]*\.[\w\-\.]+$') { Write-VdTaskLog -SH $SH -Text "Skipped invalid extension id: $ext" -Type "WARN"; continue }
                    $null = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--install-extension', $ext, '--force') 'UTF8'
                }
            }
        }

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-VdTaskLog -SH $SH -Text "AppData Developer Restore completed successfully!" -Type "SUCCESS"
        Show-VdTaskMessage -SH $SH -Text "Developer configurations restored successfully!" -Title "Restore Complete" -Buttons "OK" -Icon "Information"
    } catch {
        Write-VdTaskLog -SH $SH -Text "Restore failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Invoke-VdPrimeBoost {
    param($SH)
    try {
        Write-VdTaskLog -SH $SH -Text "[1/6] Creating System Restore Point..." -Type "ACTION"
        try {
            Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
            Checkpoint-Computer -Description "VDOWNS_PrimeBoost" -RestorePointType "MODIFY_SETTINGS" -EA SilentlyContinue
            Write-VdTaskLog -SH $SH -Text "System Restore Point created." -Type "SUCCESS"
        } catch { Write-VdTaskLog -SH $SH -Text "Restore Point skipped: $($_.Exception.Message)" -Type "WARN" }

        Write-VdTaskLog -SH $SH -Text "[2/6] Disabling Windows Telemetry & Advertising ID..." -Type "ACTION"
        foreach ($k in @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR", "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
            if (-not (Test-Path $k)) { New-Item -Path $k -Force -EA SilentlyContinue | Out-Null }
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Stop-Service -Name "DiagTrack" -Force -EA SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled -EA SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "[3/6] Disabling Xbox GameDVR background recording..." -Type "ACTION"
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force -EA SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "[4/6] Disabling SysMain Superfetch..." -Type "ACTION"
        Stop-Service -Name "SysMain" -Force -EA SilentlyContinue
        Set-Service -Name "SysMain" -StartupType Disabled -EA SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "[5/6] Applying Dark Mode & Showing File Extensions..." -Type "ACTION"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force -EA SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "[6/6] Purging Temporary File Caches..." -Type "ACTION"
        Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue

        Write-VdTaskLog -SH $SH -Text "Prime 1-Click Optimization finished. Review the log above for any skipped steps." -Type "SUCCESS"
    } catch {
        Write-VdTaskLog -SH $SH -Text "Optimization error: $($_.Exception.Message)" -Type "ERROR"
    }
}
