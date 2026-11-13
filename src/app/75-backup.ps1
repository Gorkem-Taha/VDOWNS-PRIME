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

        Start-VdTask 'Invoke-VdConfigBackup' @{ DestZip = $destZip; SH = (New-VdTaskContext) } -OnComplete { $btnBackupConfig.IsEnabled = $true }
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

        Start-VdTask 'Invoke-VdConfigRestore' @{ SrcZip = $srcZip; SH = (New-VdTaskContext) } -OnComplete { $btnRestoreConfig.IsEnabled = $true }
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

