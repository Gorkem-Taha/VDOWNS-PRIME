# ⚡ VDOWNS PRIME v3.0.0 | Windows System Architect

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-00A8FF?style=for-the-badge&logo=windows)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Language](https://img.shields.io/badge/Language-PowerShell%207%20%2F%205.1%20%2B%20WPF%20XAML-5391FE?style=for-the-badge&logo=powershell)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Architecture](https://img.shields.io/badge/Engine-Async%20ThreadPool%20Runspaces-FF5722?style=for-the-badge)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Version](https://img.shields.io/badge/Version-v3.0.0%20(SemVer)-2ECC71?style=for-the-badge)](https://github.com/Gorkem-Taha/VDOWNS-PRIME/releases)
[![License](https://img.shields.io/badge/License-MIT-F39C12?style=for-the-badge)](LICENSE)

**VDOWNS PRIME v3.0.0** is an enterprise-grade Windows 10/11 optimization, debloating, package management, and system maintenance suite. Engineered with hardware-accelerated WPF (Windows Presentation Foundation) and an asynchronous PowerShell Runspace engine, it ensures a responsive, non-blocking 60 FPS user interface while executing deep registry modifications, DISM repairs, and batch winget operations.

---

## 📸 Architecture & Interface

![VDOWNS PRIME Interface](/Picture/VDOWNS_PRIME_2.0.png)

---

## 🚀 Key Modernizations in v3.0.0

| Feature | v2.0 (Legacy WinForms) | v3.0.0 (Prime WPF Edition) |
| :--- | :--- | :--- |
| **UI Framework** | Synchronous Windows Forms | Hardware-accelerated WPF XAML |
| **Threading Model** | Single UI thread (prone to freezing) | Multi-Threaded PowerShell Runspaces + Dispatcher Marshalling |
| **Package Management** | Fixed static buttons | Dynamic Winget Search & Batch Catalog (`apps.json`) |
| **Debloater Safety** | Basic script execution | Granular Package Audit + Restore Point Protection |
| **Log Streaming** | Delayed textbox appends | Real-time Thread-Safe Log Console with colored status |
| **Compilation Pipeline** | Manual bundling | Automated `build.ps1` with AST syntax checks & `ps2exe` |

---

## 🛠️ Core Modules

### 1. 📦 Dynamic App Center & Winget Manager
- **Database-Driven Catalog (`apps.json`):** 96 curated applications grouped into 7 major categories (Browsers, Development, Gaming, Media, Utilities, Security, Communication).
- **Customizable:** Add custom Winget IDs or local installers directly into `apps.json`.
- **Winget Live Search:** Query Microsoft Community Repository in real-time, view package metadata, and install/upgrade/uninstall directly from individual cards.
- **Batch Processing:** Multi-select items across tabs and queue background silent installations (`winget install --id <ID> --silent --accept-source-agreements --accept-package-agreements`).

### 2. ⚡ Reversible System Tweaks
Every tweak is strictly reversible with dedicated Do/Undo logic:
- **Privacy & Telemetry:** Disable Telemetry (DiagTrack), Diagnostics Tracking, Advertising ID, Activity History, and automatic O&O ShutUp10 privacy enforcement.
- **Interface & Explorer:** Force System/App Dark Mode, restore Classic Windows 10 Context Menu on Windows 11, align Taskbar left, show file extensions and hidden files, configure Explorer to launch into "This PC".
- **Performance & Gaming:** Unlock the Windows Ultimate Performance power plan, disable Xbox Game DVR background recording, disable SysMain (Superfetch) for NVMe/SSD life extension, disable Sticky Keys accessibility traps, and enable Storage Sense.
- **Automated Restore Point:** One-click automated VSS System Restore Point generation before applying any destructive modifications.

### 3. 🛡️ Granular Windows Debloater
Eliminate pre-installed consumer bloatware consuming background CPU cycles and memory:
- Safely targets non-essential Windows AppX packages: Cortana, Bing News, Weather, Microsoft Solitaire, People App, Xbox Game Bar, and Get Help.
- Non-destructive filtering prevents purging core Windows subsystem apps (Calculator, Photos, Store, Terminal).

### 4. 🔄 System Repair & Update Center
Embedded live console running background system maintenance without blocking the desktop:
- **SFC /scannow:** Verify system file integrity and automatically replace damaged files from cached image.
- **DISM Component Cleanup & Repair:** Execute deep image repair utilizing Microsoft Update servers (`DISM /Online /Cleanup-Image /RestoreHealth`).
- **Network Stack Reset:** Flush DNS cache, reset Winsock catalog, and reset TCP/IP stack in an automated sequence.
- **Emergency Windows Update Cache Purge:** Stop update services, clear corrupted `%windir%\SoftwareDistribution\Download` cache, and re-register BITS/WUAENG services.

---

## 🏗️ Project Structure

```
Vdowns_2.0/
├── apps.json               # Curated software packages catalog (96 apps)
├── build.ps1               # Automated build & compilation script
├── LICENSE                 # MIT License
├── README.md               # Architecture documentation & guide
├── VDOWNS_PRIME.exe        # Standalone compiled portable binary (v3.0.0)
├── VDOWNS_PRIME.ps1        # Canonical modern WPF + Async Runspace engine
├── vdowns.ps1              # Backward-compatibility launcher forwarder
├── Picture/                # Interface assets and screenshots
└── Source/
    ├── apps.json           # Catalog backup / local source copy
    ├── vdowns_2.0.ps1      # Legacy WinForms fallback reference
    └── vdowns_3.0.ps1      # Synced source script
```

---

## 💻 Building from Source

### Prerequisites
- Windows 10 (Build 19041+) or Windows 11 (x64)
- PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for system tweaks and debloater)
- Optional: `ps2exe` module (`Install-Module -Name ps2exe -Scope CurrentUser`)

### Automated Build Pipeline
Run the included build script to validate AST syntax, check JSON integrity, and compile the standalone executable:

```powershell
# In PowerShell as Administrator:
.\build.ps1
```

To run syntax and integrity verification without re-compiling the binary:
```powershell
.\build.ps1 -SkipCompile
```

---

## 🏃 Execution

### Option A: Portable Binary (Recommended)
1. Download `VDOWNS_PRIME.exe` and `apps.json` into the same folder.
2. Right-click `VDOWNS_PRIME.exe` and select **Run as Administrator**.

### Option B: PowerShell Direct
```powershell
# Set ExecutionPolicy for process scope
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Launch canonical engine
.\VDOWNS_PRIME.ps1
```

---

## 🛡️ Safety & Disclaimer

> [!WARNING]
> This software directly interfaces with the Windows Registry, Component-Based Servicing (CBS), and system services. Always click **Create Restore Point** in the Privacy tab before applying bulk system tweaks or debloater commands.

---

## 📜 Versioning & Conventions

This repository adheres to [Semantic Versioning 2.0.0](https://semver.org/) (`vMAJOR.MINOR.PATCH`) and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
- Releases are tagged with standard git tags (e.g. `v3.0.0`).
- Commits are structured as `feat:`, `fix:`, `refactor:`, `chore(release):`.

---

## 👤 Author & License
- **Author:** [Görkem Taha Çanakcı](https://github.com/Gorkem-Taha)
- **Repository:** [VDOWNS-PRIME](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
- **License:** [MIT License](LICENSE)