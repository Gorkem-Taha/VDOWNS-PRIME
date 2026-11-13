# =============================================================================
# 13. BACKUP & RESTORE CENTER
# =============================================================================

# Export .vdowns System Profile
if ($btnExportProfile) {
    $btnExportProfile.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "VDOWNS Profile (*.vdowns)|*.vdowns|JSON Files (*.json)|*.json"
        $sfd.FileName = "VDOWNS_Profile_$(Get-Date -Format 'yyyyMMdd').vdowns"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $profileObj = @{
                    Version = "3.1"
                    Date = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    SelectedApps = @($script:InstallList | Where-Object { $_.Check.IsChecked } | ForEach-Object { @{ Id = $_.Id; Name = $_.Name } })
                    SelectedTweaks = @($script:TweakList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                    SelectedDebloat = @($script:DebloatList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Name })
                }
                $jsonStr = $profileObj | ConvertTo-Json -Depth 5
                Set-Content -Path $sfd.FileName -Value $jsonStr -Encoding UTF8
                Write-AppLog "Profile exported to: $($sfd.FileName)" "SUCCESS"
                [System.Windows.MessageBox]::Show("Profile saved successfully!`nPath: $($sfd.FileName)", "Profile Saved", "OK", "Information")
            } catch {
                Write-AppLog "Failed to export profile: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Import .vdowns System Profile
if ($btnImportProfile) {
    $btnImportProfile.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "VDOWNS Profile (*.vdowns)|*.vdowns|JSON Files (*.json)|*.json"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $rawJson = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
                
                # Check matching apps (support both raw ID list and object list)
                $importedApps = @($rawJson.SelectedApps | ForEach-Object { if ($_.Id) { $_.Id } else { $_ } })
                $appCount = 0
                foreach ($item in $script:InstallList) {
                    if ($importedApps -contains $item.Id) {
                        $item.Check.IsChecked = $true
                        $appCount++
                    }
                }

                # Check matching tweaks
                $importedTweaks = @($rawJson.SelectedTweaks)
                foreach ($t in $script:TweakList) {
                    if ($importedTweaks -contains $t.Name) { $t.Check.IsChecked = $true }
                }

                # Check matching debloat
                $importedDebloat = @($rawJson.SelectedDebloat)
                foreach ($d in $script:DebloatList) {
                    if ($importedDebloat -contains $d.Name) { $d.Check.IsChecked = $true }
                }

                Write-AppLog "Profile imported from: $($ofd.FileName) ($appCount apps selected)" "SUCCESS"
                Show-Page "install"
                [System.Windows.MessageBox]::Show("Profile imported successfully!`n$appCount apps and corresponding tweaks/debloat selected.`nClick INSTALL SELECTED to begin installation.", "Profile Loaded", "OK", "Information")
            } catch {
                Write-AppLog "Failed to import profile: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Generate Unattended Standalone Setup Script (.ps1)
if ($btnExportUnattendedScript) {
    $btnExportUnattendedScript.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "PowerShell Script (*.ps1)|*.ps1"
        $sfd.FileName = "VDOWNS_Unattended_Setup_$(Get-Date -Format 'yyyyMMdd').ps1"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $selectedApps = @($script:InstallList | Where-Object { $_.Check.IsChecked } | ForEach-Object { $_.Id })
                $selectedTweakItems = @($script:TweakList | Where-Object { $_.Check.IsChecked })
                $selectedDebloatItems = @($script:DebloatList | Where-Object { $_.Check.IsChecked })

                # Single-quoted literals in the generated script: nothing in the data gets expanded there
                $appsLines = ($selectedApps | ForEach-Object { "    '" + ($_ -replace "'", "''") + "'" }) -join "`r`n"
                $debloatPatterns = @($selectedDebloatItems | ForEach-Object { $_.Pat } | ForEach-Object { $_ })
                $debloatLines = ($debloatPatterns | ForEach-Object { "    '" + ($_ -replace "'", "''") + "'" }) -join "`r`n"

                # Embed the exact Do block the GUI runs for every selected tweak
                $tweakBlocks = foreach ($t in $selectedTweakItems) {
                    $tn = $t.Name -replace "'", "''"
                    $body = $t.Do.ToString().Trim()
@"
try {
    Write-Host 'Applying: $tn' -ForegroundColor Cyan
    & {
        `$ErrorActionPreference = 'Stop'
        $body
    }
    `$tweaksApplied++
} catch {
    Write-Host ('Failed: $tn - ' + `$_.Exception.Message) -ForegroundColor Red
}
"@
                }
                $tweaksBlock = if ($tweakBlocks) { ($tweakBlocks -join "`r`n") } else { "Write-Host 'No tweaks selected.' -ForegroundColor DarkGray" }

                $scriptContent = @"
<#
.SYNOPSIS
    VDOWNS PRIME v$($script:VdownsVersion) - Automated Standalone Unattended Deployment Script
    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
#>
# Self-elevation check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"`$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VDOWNS PRIME - Standalone Unattended Deployment Engine  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Restore Point
try {
    Write-Host "`n[1/4] Creating System Restore Point..." -ForegroundColor Yellow
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "VDOWNS_Automated_Setup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Write-Host "Restore point initiated." -ForegroundColor Green
} catch {
    Write-Host "Restore point skipped: `$(`$_.Exception.Message)" -ForegroundColor DarkGray
}

# 2. Batch Winget Installations
Write-Host "`n[2/4] Installing Applications via Winget..." -ForegroundColor Yellow
`$appsToInstall = @(
$appsLines
)
foreach (`$appId in `$appsToInstall) {
    if ([string]::IsNullOrWhiteSpace(`$appId)) { continue }
    Write-Host "Installing `$appId..." -ForegroundColor Cyan
    winget install --id `$appId -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
}

# 3. System Tweaks Execution
Write-Host "`n[3/4] Applying System Tweaks..." -ForegroundColor Yellow
`$tweaksApplied = 0
$tweaksBlock

# 4. Debloater Execution
Write-Host "`n[4/4] Removing Selected Bloatware Packages..." -ForegroundColor Yellow
`$debloatPatterns = @(
$debloatLines
)
foreach (`$pattern in `$debloatPatterns) {
    `$found = @(Get-AppxPackage -AllUsers -Name `$pattern -EA SilentlyContinue)
    foreach (`$pkg in `$found) {
        Write-Host "Removing: `$(`$pkg.Name)" -ForegroundColor Cyan
        try { Remove-AppxPackage -Package `$pkg.PackageFullName -AllUsers -ErrorAction Stop }
        catch { Write-Host "Could not remove `$(`$pkg.Name): `$(`$_.Exception.Message)" -ForegroundColor Red }
    }
}

# Explorer Refresh
if (`$tweaksApplied -gt 0) { Stop-Process -Name explorer -Force -EA SilentlyContinue }
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
"@
                Set-Content -Path $sfd.FileName -Value $scriptContent -Encoding UTF8
                Write-AppLog "Unattended setup script generated: $($sfd.FileName)" "SUCCESS"
                [System.Windows.MessageBox]::Show("Standalone setup script generated successfully!`nPath: $($sfd.FileName)", "Script Generated", "OK", "Information")
            } catch {
                Write-AppLog "Failed to generate script: $($_.Exception.Message)" "ERROR"
            }
        }
    })
}

# Backup AppData Configurations (.zip) (Asynchronous Runspace)
if ($btnBackupConfig) {
    $btnBackupConfig.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "Zip Files (*.zip)|*.zip"
        $sfd.FileName = "VDOWNS_ConfigBackup_$(Get-Date -Format 'yyyyMMdd').zip"
        if ($sfd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $destZip = $sfd.FileName

        Write-AppLog "Starting AppData Configuration Backup in background..." "ACTION"
        $btnBackupConfig.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("destZip", $destZip)
        $runspace.SessionStateProxy.SetVariable("btnBackupConfig", $btnBackupConfig)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

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
                    Log-Msg "Backed up VS Code user configurations." "INFO"
                }
                try {
                    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
                    if ($codeCmd) {
                        $r = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--list-extensions') 'UTF8'
                        Set-Content -Path (Join-Path $tempDir "vscode_extensions.txt") -Value $r.Output -Encoding UTF8
                        Log-Msg "Exported VS Code extensions manifest." "INFO"
                    }
                } catch {}

                # 2. Cursor Settings
                $cursorPath = Join-Path $env:APPDATA "Cursor\User"
                if (Test-Path $cursorPath) {
                    $curTarget = Join-Path $tempDir "Cursor_User"
                    New-Item -ItemType Directory -Path $curTarget -Force | Out-Null
                    Get-ChildItem -Path $cursorPath -Exclude "workspaceStorage", "globalStorage", "History" | Copy-Item -Destination $curTarget -Recurse -Force -EA SilentlyContinue
                    Log-Msg "Backed up Cursor user configurations." "INFO"
                }

                # 3. Git Config
                $gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
                if (Test-Path $gitConfig) {
                    Copy-Item $gitConfig -Destination (Join-Path $tempDir ".gitconfig") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Git configuration (.gitconfig)." "INFO"
                }

                # 4. PowerShell Profiles ($PROFILE is not set inside a background runspace)
                $docsDir = [Environment]::GetFolderPath('MyDocuments')
                $winPsProfile = Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
                $pwshProfile  = Join-Path $docsDir "PowerShell\Microsoft.PowerShell_profile.ps1"
                if (Test-Path $winPsProfile) {
                    Copy-Item $winPsProfile -Destination (Join-Path $tempDir "Microsoft.PowerShell_profile.ps1") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Windows PowerShell profile." "INFO"
                }
                if (Test-Path $pwshProfile) {
                    Copy-Item $pwshProfile -Destination (Join-Path $tempDir "PowerShell7_profile.ps1") -Force -EA SilentlyContinue
                    Log-Msg "Backed up PowerShell 7 profile." "INFO"
                }

                # 5. Windows Terminal
                $wtPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
                if (Test-Path $wtPath) {
                    Copy-Item $wtPath -Destination (Join-Path $tempDir "Terminal_settings.json") -Force -EA SilentlyContinue
                    Log-Msg "Backed up Windows Terminal settings." "INFO"
                }

                # 6. Notepad++
                $nppPath = Join-Path $env:APPDATA "Notepad++"
                if (Test-Path $nppPath) {
                    Copy-Item $nppPath -Destination (Join-Path $tempDir "NotepadPlusPlus") -Recurse -Force -EA SilentlyContinue
                    Log-Msg "Backed up Notepad++ settings." "INFO"
                }

                # 7. SSH Config (host mappings only, keys excluded for safety)
                $sshConfig = Join-Path $env:USERPROFILE ".ssh\config"
                if (Test-Path $sshConfig) {
                    $sshTarget = Join-Path $tempDir "SSH_Config"
                    New-Item -ItemType Directory -Path $sshTarget -Force | Out-Null
                    Copy-Item $sshConfig -Destination (Join-Path $sshTarget "config") -Force -EA SilentlyContinue
                    Log-Msg "Backed up SSH host mappings." "INFO"
                }

                # Compress
                Log-Msg "Compressing developer backup snapshot into ZIP..." "ACTION"
                if (Test-Path $destZip) { Remove-Item $destZip -Force }
                Compress-Archive -Path "$tempDir\*" -DestinationPath $destZip -Force
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

                Log-Msg "AppData Developer Backup completed successfully: $destZip" "SUCCESS"
                $window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show("AppData configurations backup complete!`nFile: $destZip", "Backup Complete", "OK", "Information")
                })
            } catch {
                Log-Msg "Backup failed: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnBackupConfig) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnBackupConfig.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
        }
    })
}

# Restore AppData Configurations (.zip) (Asynchronous Runspace)
if ($btnRestoreConfig) {
    $btnRestoreConfig.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Zip Files (*.zip)|*.zip"
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $srcZip = $ofd.FileName

        # Show what the archive will overwrite before touching anything
        $knownItems = [ordered]@{
            "VSCode_User"                      = "VS Code settings"
            "Cursor_User"                      = "Cursor settings"
            ".gitconfig"                       = "Git config"
            "Microsoft.PowerShell_profile.ps1" = "Windows PowerShell profile (runs code every time PowerShell starts)"
            "PowerShell7_profile.ps1"          = "PowerShell 7 profile (runs code every time PowerShell starts)"
            "Terminal_settings.json"           = "Windows Terminal settings"
            "NotepadPlusPlus"                  = "Notepad++ settings"
            "SSH_Config"                       = "SSH config"
            "vscode_extensions.txt"            = "VS Code extension list (extensions will be installed from the Marketplace)"
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zipPeek = [System.IO.Compression.ZipFile]::OpenRead($srcZip)
            $topNames = @($zipPeek.Entries | ForEach-Object { ($_.FullName -replace '\\', '/').Split('/')[0] } | Sort-Object -Unique)
            $zipPeek.Dispose()
        } catch {
            Write-AppLog "Cannot read backup archive: $($_.Exception.Message)" "ERROR"
            return
        }
        $found = @($knownItems.Keys | Where-Object { $topNames -contains $_ } | ForEach-Object { " - " + $knownItems[$_] })
        if ($found.Count -eq 0) {
            [System.Windows.MessageBox]::Show("This file does not look like a VDOWNS configuration backup.", "Restore", "OK", "Warning")
            return
        }
        $confirmMsg = "The following will be overwritten:`n" + ($found -join "`n") + "`n`nOnly restore backups you created yourself: profiles and extensions can run code.`nYour current files are first saved to %LOCALAPPDATA%\VDOWNS\PreRestore_<date>.`n`nContinue?"
        $res = [System.Windows.MessageBox]::Show($confirmMsg, "Confirm Restore", "YesNo", "Warning")
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        Write-AppLog "Restoring AppData Configuration Backup in background..." "WARN"
        $btnRestoreConfig.IsEnabled = $false

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("window", $script:window)
        $runspace.SessionStateProxy.SetVariable("logBox", $script:logBox)
        $runspace.SessionStateProxy.SetVariable("srcZip", $srcZip)
        $runspace.SessionStateProxy.SetVariable("btnRestoreConfig", $btnRestoreConfig)

        $runspace.SessionStateProxy.SetVariable("VdNativeLib", $script:VdNativeLib)
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        $ps.AddScript({
            . ([scriptblock]::Create($VdNativeLib))
            function Log-Msg($txt, $type="INFO") {
                if ($window -and $logBox) {
                    $window.Dispatcher.Invoke([Action]{
                        $ts = Get-Date -Format 'HH:mm:ss'
                        $logBox.AppendText("[$ts] [$type] $txt`r`n")
                        $logBox.ScrollToEnd()
                    })
                }
            }

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
                if ($saved -gt 0) { Log-Msg "Current settings saved before restore: $safetyDir" "INFO" }

                # Restore VS Code
                if (Test-Path "$tempDir\VSCode_User") {
                    $vscodeDest = Join-Path $env:APPDATA "Code\User"
                    New-Item -ItemType Directory -Path $vscodeDest -Force | Out-Null
                    Copy-Item "$tempDir\VSCode_User\*" -Destination $vscodeDest -Recurse -Force
                    Log-Msg "Restored VS Code configurations." "SUCCESS"
                }

                # Restore Git Config
                if (Test-Path "$tempDir\.gitconfig") {
                    Copy-Item "$tempDir\.gitconfig" -Destination (Join-Path $env:USERPROFILE ".gitconfig") -Force
                    Log-Msg "Restored Git configuration." "SUCCESS"
                }

                # Restore Cursor
                if (Test-Path "$tempDir\Cursor_User") {
                    $cursorDest = Join-Path $env:APPDATA "Cursor\User"
                    New-Item -ItemType Directory -Path $cursorDest -Force | Out-Null
                    Copy-Item "$tempDir\Cursor_User\*" -Destination $cursorDest -Recurse -Force
                    Log-Msg "Restored Cursor configurations." "SUCCESS"
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
                        Log-Msg "Restored $($pm.Label) profile." "SUCCESS"
                    }
                }

                # Restore Windows Terminal
                if (Test-Path "$tempDir\Terminal_settings.json") {
                    $wtDest = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
                    if (Test-Path $wtDest) {
                        Copy-Item "$tempDir\Terminal_settings.json" -Destination (Join-Path $wtDest "settings.json") -Force
                        Log-Msg "Restored Windows Terminal settings." "SUCCESS"
                    }
                }

                # Restore Notepad++
                if (Test-Path "$tempDir\NotepadPlusPlus") {
                    $nppDest = Join-Path $env:APPDATA "Notepad++"
                    New-Item -ItemType Directory -Path $nppDest -Force | Out-Null
                    Copy-Item "$tempDir\NotepadPlusPlus\*" -Destination $nppDest -Recurse -Force
                    Log-Msg "Restored Notepad++ settings." "SUCCESS"
                }

                # Restore SSH Config
                if (Test-Path "$tempDir\SSH_Config\config") {
                    $sshDir = Join-Path $env:USERPROFILE ".ssh"
                    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
                    Copy-Item "$tempDir\SSH_Config\config" -Destination (Join-Path $sshDir "config") -Force
                    Log-Msg "Restored SSH host configurations." "SUCCESS"
                }

                # Optional VS Code Extension Reinstall
                $extFile = Join-Path $tempDir "vscode_extensions.txt"
                if (Test-Path $extFile) {
                    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
                    if ($codeCmd) {
                        Log-Msg "Reinstalling backed up VS Code extensions..." "ACTION"
                        $exts = Get-Content $extFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                        foreach ($ext in $exts) {
                            Log-Msg "Installing extension: $ext" "INFO"
                            if ($ext -notmatch '^[A-Za-z0-9][\w\-]*\.[\w\-\.]+$') { Log-Msg "Skipped invalid extension id: $ext" "WARN"; continue }
                            $null = Invoke-VdNative 'cmd.exe' @('/d', '/c', 'code', '--install-extension', $ext, '--force') 'UTF8'
                        }
                    }
                }

                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                Log-Msg "AppData Developer Restore completed successfully!" "SUCCESS"
                $window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show("Developer configurations restored successfully!", "Restore Complete", "OK", "Information")
                })
            } catch {
                Log-Msg "Restore failed: $($_.Exception.Message)" "ERROR"
            } finally {
                if ($window -and $btnRestoreConfig) {
                    $window.Dispatcher.Invoke([Action]{
                        $btnRestoreConfig.IsEnabled = $true
                    })
                }
            }
        })

        $handle = $ps.BeginInvoke()
        Watch-Runspace -PS $ps -Handle $handle -Runspace $runspace -OnComplete {
            param($result)
        }
    })
}

# Winget Native Export
if ($btnWingetExport) {
    $btnWingetExport.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "JSON Files (*.json)|*.json"
        $sfd.FileName = "Winget_Installed_$(Get-Date -Format 'yyyyMMdd').json"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Write-AppLog "Exporting Winget package list..." "ACTION"
            Start-StreamingCommand "winget" "export -o `"$($sfd.FileName)`" --accept-source-agreements"
        }
    })
}

# Winget Native Import
if ($btnWingetImport) {
    $btnWingetImport.Add_Click({
        if (-not (Test-WingetAvailable)) { return }
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "JSON Files (*.json)|*.json"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Write-AppLog "Importing Winget package list..." "ACTION"
            Start-StreamingCommand "winget" "import -i `"$($ofd.FileName)`" --accept-package-agreements --accept-source-agreements"
        }
    })
}

