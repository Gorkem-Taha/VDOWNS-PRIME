# The OO ShutUp10 binary only runs if Windows reports a valid Authenticode signature from O&O Software.
$essentialTweaks = @(
    @{Name="Create Restore Point"; Tag="Essential";
      Do={ Checkpoint-Computer -Description "VDOWNSPrimeRestore" -RestorePointType "MODIFY_SETTINGS" };
      Undo={ throw "Restore points are not removed automatically; use System Protection to manage them." } },
    @{Name="Run OO ShutUp10"; Tag="Essential";
      Do={ $url = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"; $dir = Join-Path $env:TEMP ("VDOWNS_OOSU_" + [guid]::NewGuid().ToString("N")); New-Item -ItemType Directory -Path $dir -Force | Out-Null; $exe = Join-Path $dir "OOSU10.exe"; Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing -ErrorAction Stop; $sig = Get-AuthenticodeSignature -FilePath $exe; if ($sig.Status -ne "Valid" -or $sig.SignerCertificate.Subject -notmatch "O&O Software") { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue; throw "OOSU10.exe signature check failed ($($sig.Status)); file deleted, not executed." }; Start-Process -FilePath $exe };
      Undo={ throw "Open O&O ShutUp10 and use its own undo to revert its settings." } },
    @{Name="Disable Telemetry"; Tag="Essential"; State=@(@{Svc="DiagTrack"});
      Do={ Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue; Stop-Service DiagTrack -EA SilentlyContinue };
      Undo={ Set-Service DiagTrack -StartupType Automatic; Start-Service DiagTrack } },
    @{Name="Disable Ad ID"; Tag="Essential"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 1 } }
)

$uiTweaks = @(
    @{Name="Dark Mode (System)"; Tag="UI"; State=@(@{Reg="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="SystemUsesLightTheme"});
      Do={ Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 } },
    @{Name="Dark Mode (Apps)"; Tag="UI"; State=@(@{Reg="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="AppsUseLightTheme"});
      Do={ Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1 } },
    @{Name="Show Hidden Files"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="Hidden"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 } },
    @{Name="Show File Extensions"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="HideFileExt"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 } },
    @{Name="Launch to 'This PC'"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="LaunchTo"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 2 } },
    @{Name="Classic Context Menu"; Tag="UI"; State=@(@{Key="HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"});
      Do={ $k = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"; New-Item -Path $k -Force | Out-Null; Set-Item -Path $k -Value "" };
      Undo={ Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue } },
    @{Name="Align Taskbar Left"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarAl"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 } },
    @{Name="Hide Search Icon"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name="SearchboxTaskbarMode"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 } },
    @{Name="Clipboard History"; Tag="UI"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard"; Name="EnableClipboardHistory"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" -Name "EnableClipboardHistory" -Value 1 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" -Name "EnableClipboardHistory" -Value 0 } }
)

$perfTweaks = @(
    @{Name="Disable Sticky Keys"; Tag="Power"; State=@(@{Reg="HKCU:\Control Panel\Accessibility\StickyKeys"; Name="Flags"});
      Do={ Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" };
      Undo={ Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "510" } },
    @{Name="Enable Hibernate"; Tag="Power"; State=@(@{Hibernate=$true});
      Do={ powercfg /hibernate on };
      Undo={ powercfg /hibernate off } },
    @{Name="Storage Sense"; Tag="Power"; State=@(@{Reg="HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"; Name="01"});
      Do={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 };
      Undo={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 } },
    @{Name="Ultimate Performance"; Tag="Power"; State=@(@{PowerPlan=$true});
      Do={ $g = "c4e0702f-b217-4220-b268-5cbd645bac82"; if ((powercfg /list | Out-String) -notmatch $g) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $g | Out-Null }; powercfg /setactive $g };
      Undo={ powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e; powercfg /delete c4e0702f-b217-4220-b268-5cbd645bac82 } },
    @{Name="Disable SysMain"; Tag="Power"; State=@(@{Svc="SysMain"});
      Do={ Set-Service SysMain -StartupType Disabled -EA SilentlyContinue; Stop-Service SysMain -EA SilentlyContinue };
      Undo={ Set-Service SysMain -StartupType Automatic; Start-Service SysMain } },
    @{Name="Disable Game DVR"; Tag="Power"; State=@(@{Reg="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"});
      Do={ Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 };
      Undo={ Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 } }
)

