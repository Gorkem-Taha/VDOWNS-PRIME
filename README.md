# ⚡ VDOWNS PRIME | Windows System Architect

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-00A8FF?style=for-the-badge&logo=windows)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Language](https://img.shields.io/badge/PowerShell%205.1%20%2B%20WPF-5391FE?style=for-the-badge&logo=powershell)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Version](https://img.shields.io/badge/Version-v3.4.0-2ECC71?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-F39C12?style=for-the-badge)](LICENSE)

VDOWNS PRIME is a portable Windows 10/11 post-install tool written in PowerShell with a WPF interface.
It installs software through **winget**, applies **reversible** system tweaks, removes pre-installed
Store apps, runs repair tools with live output, and backs up developer configuration — without any
third-party runtime or telemetry.

> [!WARNING]
> VDOWNS PRIME runs as Administrator and changes the registry, services, power plans and installed
> apps. Read what each module does below, create a restore point first, and test on a non-critical
> machine before using it on your daily system.

---

## Modules

### 📦 App Center
- Curated catalog of 96 apps in 7 categories (`apps.json`), with search and category filter chips.
- Batch install / uninstall with `winget` (exact IDs, silent, already-installed apps are detected
  instead of reinstalled). Every catalog ID is checked against
  [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs).
- **Add App** wizard: adds your own winget ID (validated) and an optional `http(s)` link to the catalog.
- **Winget tab**: scan installed packages, search the winget repository, install/uninstall single
  packages, upgrade all, export/import winget package lists.
- If `apps.json` is missing or corrupt, the built-in copy of the catalog is used and restored.

### ⚡ System Tweaks (reversible)
Privacy, interface and performance tweaks (telemetry service, advertising ID, dark mode, Explorer
options, classic context menu, taskbar alignment, clipboard history, Sticky Keys, hibernate,
Storage Sense, Ultimate Performance plan, SysMain, Game DVR, O&O ShutUp10, restore point).

- Before a tweak is applied for the first time, every registry value, service start mode,
  hibernate state and active power plan it touches is saved to `HKCU\Software\VDOWNS\TweakState`.
- **Revert** restores exactly that state (including "value did not exist") and removes the snapshot.
- Failures are reported as failures in the activity log.
- O&O ShutUp10 is downloaded fresh and only started if its Authenticode signature is valid and
  issued to O&O Software.

### 🧩 Features & Maintenance
- Enable Hyper-V, WSL 2 (incl. Virtual Machine Platform), Windows Sandbox and .NET 3.5 in a
  background process with live output.
- **Deep Clean** runs Disk Cleanup for a safe allow-list of categories (temp files, caches, logs,
  crash dumps, Delivery Optimization, superseded updates). It never selects Downloads, the Recycle
  Bin, previous Windows installations, Windows ESD files ("Reset this PC") or language packs.

### 🛡️ Debloater
- Removes selected pre-installed Store apps for the current user; optionally also the provisioned
  copies so they do not come back for new user accounts.
- "Select Recommended" picks a conservative default set; removal is not reversible from the app
  (reinstall from the Microsoft Store if needed).

### 🔄 Update & Repair
- `winget upgrade --all`, Microsoft Store updates, Windows updates and driver-only updates via
  [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate) **2.2.1.5**
  (pinned version, Authenticode-verified before it is loaded).
- SFC, DISM RestoreHealth, network stack reset and a Windows Update component reset, all with live
  output and exit codes.
- Pause Windows Update for 35 days / resume.

### 🏆 Health score, DNS and startup
- **Health score**: a 0–100 indicator built from six configuration checks (telemetry service and
  policy, Game DVR, SysMain, restore points, hidden file extensions). It is a checklist, not a
  performance benchmark.
- **Quick Boost**: restore point, then the recommended privacy/performance settings and a temp clean.
- **DNS**: Cloudflare, Google, AdGuard or Quad9 (IPv4 + IPv6) on every active physical adapter,
  reset to DHCP, and a background benchmark that measures real DNS lookups per resolver.
- **Startup manager**: disables `Run` entries (HKCU, HKLM, HKLM 32-bit) by moving them to
  `HKCU\Software\VDOWNS\DisabledStartupV2` together with their origin and value type; re-enabling
  puts them back where they came from.

### 💾 Backup & Profiles
- **Developer backup** (`.zip`): VS Code and Cursor user settings, VS Code extension list, `.gitconfig`,
  PowerShell 5.1/7 profiles, Windows Terminal settings, Notepad++ settings, SSH `config` (keys are
  never included).
- **Restore** shows what will be overwritten, rejects archives with unsafe paths, and first copies
  your current files to `%LOCALAPPDATA%\VDOWNS\PreRestore_<date>`.
- **Profiles** (`.vdowns`): save/load your selection of apps, tweaks and debloat items.
- **Unattended script**: export the current selection as a self-elevating `.ps1` that installs the
  apps, applies exactly the selected tweaks and removes the selected packages on a fresh machine.

---

## What VDOWNS PRIME leaves on your system

| Location | Purpose | Safe to delete? |
| --- | --- | --- |
| `HKCU\Software\VDOWNS\TweakState` | Original values for **Revert** | Yes, but Revert then falls back to generic defaults |
| `HKCU\Software\VDOWNS\DisabledStartupV2` | Disabled startup entries | Only after re-enabling what you need |
| `HKCU\Software\VDOWNS\DisabledStartup` | Disabled startup entries from v3.3.x | Same as above |
| `%LOCALAPPDATA%\VDOWNS\PreRestore_*` | Your files from before a backup restore | Yes, once you are happy with the restore |
| Power plan `c4e0702f-b217-4220-b268-5cbd645bac82` | Ultimate Performance copy | Revert removes it |

---

## Download and run

1. Download `VDOWNS_PRIME.exe`, `apps.json` and `SHA256SUMS` from
   [Releases](https://github.com/Gorkem-Taha/VDOWNS-PRIME/releases) into one folder.
2. Verify the download:
   ```powershell
   Get-FileHash .\VDOWNS_PRIME.exe, .\apps.json -Algorithm SHA256
   Get-Content .\SHA256SUMS
   ```
   The hashes must match. The exe is built by GitHub Actions from the tagged source and is not
   code-signed, so SmartScreen will warn about an unknown publisher.
3. Run `VDOWNS_PRIME.exe` (it requests Administrator rights).

**Or run the script directly** (Windows PowerShell 5.1):
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\VDOWNS_PRIME.ps1
```

**Requirements:** Windows 10 (19041+) or Windows 11 x64, winget (App Installer) for the App Center,
Administrator rights.

---

## Building from source

```powershell
.\build.ps1               # checks + compile + SHA256SUMS
.\build.ps1 -SkipCompile  # checks only
```

`build.ps1` reads the version from `$script:VdownsVersion` in `VDOWNS_PRIME.ps1`, verifies the UTF-8
BOM, checks `apps.json` (duplicates, ID format, embedded copy in sync), parses all scripts and compiles
with **ps2exe 1.0.18**. Pushing a `v*` tag runs the same build in GitHub Actions (actions pinned to
commit SHAs) and publishes `VDOWNS_PRIME.exe`, `apps.json` and `SHA256SUMS`; the tag must match the
script version.

## Project structure

```
VDOWNS-PRIME/
├── VDOWNS_PRIME.ps1        # GENERATED single-file app (do not edit by hand), UTF-8 with BOM
├── apps.json               # App catalog (also embedded into the script as offline fallback)
├── src/
│   ├── app/NN-*.ps1        # Fragments of the app, concatenated in file-name order
│   ├── lib/*.ps1           # Self-contained helpers loaded into background runspaces
│   │                       #   (VdNative, TweakState, Tasks, PSWUBootstrap, DnsBenchmark)
│   └── ui/MainWindow.xaml  # WPF markup
├── tools/Merge-Source.ps1  # Builds VDOWNS_PRIME.ps1 from src/ (-Check verifies it is in sync)
├── tools/Invoke-Lint.ps1   # PSScriptAnalyzer with PSScriptAnalyzerSettings.psd1
├── tests/*.Tests.ps1       # Pester 5 suites
├── build.ps1               # Checks, pinned ps2exe compile, SHA256SUMS
├── vdowns.ps1              # Legacy entry point, forwards to VDOWNS_PRIME.ps1
├── CHANGELOG.md
├── .github/workflows/      # ci.yml (tests + smoke), release.yml (tag -> CI -> release)
└── legacy/                 # v2.0 WinForms script and its screenshot (reference only)
```

## Development

The app ships as one script because ps2exe compiles a single file and many users run the `.ps1`
directly, but it is developed as separate files under `src/`:

```powershell
# 1. edit files under src/ (or apps.json)
# 2. regenerate the single-file script
pwsh ./tools/Merge-Source.ps1
# 3. run the tests (Pester 5.7.1) and the linter (PSScriptAnalyzer 1.25.0)
Invoke-Pester ./tests
./tools/Invoke-Lint.ps1
```

- `src/app/` fragments share one script scope; `#@include <path>` lines paste `src/lib`, `src/ui`
  or `apps.json` verbatim into here-strings.
- Background work goes through `Start-VdTask '<function>' @{ ... } -OnComplete { ... }`: the function
  lives in `src/lib/Tasks.ps1` (unit-testable, no WPF access) and reports through
  `Write-VdTaskLog` / `Set-VdTaskProgress` / `Show-VdTaskMessage`; `OnComplete` runs on the UI thread.
- Never use `GetNewClosure` (script functions disappear under `-File`); pass state through `.Tag`
  and `$this`. Controls live in script scope only (`$btnInstall`, `Get-UIElement 'name'`).
  Run console tools through `Invoke-VdNative` (no window flashes, no stdout/stderr deadlock).
- `tests/TweakState.Windows.Tests.ps1` applies real tweaks to the machine and only runs when
  `VDOWNS_ALLOW_SYSTEM_TESTS=1`. CI sets it on a throwaway runner — **do not set it on your PC**.
- CI (`ci.yml`) runs on Linux (PowerShell 7) and Windows (Windows PowerShell 5.1): source sync,
  build checks, Pester including a real-registry apply/revert round trip and a WPF load test, then
  starts the full app from the `.ps1` and from the compiled exe in smoke mode
  (`VDOWNS_SMOKE_TEST=1`: the UI loads, writes a report and closes itself). The CI exe is uploaded
  as a build artifact. A `v*` tag runs the same CI before publishing a release.

## Versioning

[Semantic Versioning](https://semver.org/) and [Conventional Commits](https://www.conventionalcommits.org/).
See [CHANGELOG.md](CHANGELOG.md).

## Author & License

- **Author:** [Görkem Taha Çanakcı](https://github.com/Gorkem-Taha)
- **License:** [MIT](LICENSE)
