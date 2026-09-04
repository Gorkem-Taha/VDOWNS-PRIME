# ⚡ VDOWNS PRIME v3.3.0 | Fluent System Architect & Optimizer

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-00A8FF?style=for-the-badge&logo=windows)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Language](https://img.shields.io/badge/Language-PowerShell%207%20%2F%205.1%20%2B%20WPF%20XAML-5391FE?style=for-the-badge&logo=powershell)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Architecture](https://img.shields.io/badge/Engine-Async%20ThreadPool%20Runspaces-FF5722?style=for-the-badge)](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
[![Version](https://img.shields.io/badge/Version-v3.3.0%20(SemVer)-2ECC71?style=for-the-badge)](https://github.com/Gorkem-Taha/VDOWNS-PRIME/releases)
[![License](https://img.shields.io/badge/License-MIT-F39C12?style=for-the-badge)](LICENSE)

**VDOWNS PRIME v3.3.0** is an enterprise-grade Windows 10/11 optimization, debloating, package management, developer profile backup, and automated unattended deployment suite. Engineered with a hardware-accelerated Windows 11 Fluent 2.0 interface, vector SVG iconography, real-time hardware telemetry, live PC Health Scoring, DNS latency benchmarking, safe startup item management, in-GUI custom app wizard, and an asynchronous PowerShell Runspace engine, it guarantees a 60 FPS non-blocking user experience while executing deep registry modifications, DISM repairs, and batch winget deployments.

---

## 📸 Architecture & Interface

![VDOWNS PRIME Interface](/Picture/VDOWNS_PRIME_2.0.png)

---

## 🚀 Key Modernizations Across Versions

| Feature | v2.0 (Legacy WinForms) | v3.0.0 (WPF Base) | v3.2.0 (Fluent UI) | v3.3.0 (Prime Optimizer) |
| :--- | :--- | :--- | :--- | :--- |
| **UI / UX Design** | Synchronous WinForms | Basic WPF XAML Grid | Fluent 2.0 Glassmorphic | Top Health Banner + Modal Wizards + SVG Badges |
| **PC Health Benchmark**| Not available | Not available | Not available | Real-time 0-100 Score with 1-Click Prime Optimization |
| **DNS Optimizer** | Not available | Not available | Not available | Cloudflare/Google/AdGuard/Quad9 + Ping Benchmark |
| **Startup Optimizer** | Not available | Not available | Not available | Safe non-destructive toggle via HKCU registry backup |
| **Custom App Wizard** | Manual JSON edits | Manual JSON edits | Manual JSON edits | In-GUI Modal with Regex Winget ID validation |
| **Update Controls** | Not available | Not available | Not available | 35-Day Update Deferral / Instant Resume |
| **Hardware Telemetry**| Static text | Static text | Real-time CPU, RAM, Disk C: | Real-time CPU, RAM, Disk C: + Health Deductions |
| **CI / CD Pipeline** | Not available | Not available | Not available | Automated GitHub Actions release on tag push |
| **Threading Model** | Single UI thread (hangs) | Async Runspaces | Full Async Runspaces | Asynchronous non-blocking multi-runspace execution |
| **Safety Net** | None | Manual Restore Point | Manual Restore Point | Automated VSS Restore Point on 1-Click Boost |

---

## 🛠️ Core Modules

### 1. 🏆 PC Health Score & 1-Click Prime Optimization
- **Dynamic Optimization Scoring (0-100):** Real-time algorithm continuously assesses hardware telemetry, excessive startup items, temporary junk files, telemetry services, and unapplied optimizations.
- **⚡ 1-Click Prime Optimization:** Automatically executes safe temp file purging, DNS flushing, memory working set trimming, and performance service tuning with zero system damage.
- **Automated VSS System Restore Point:** Automatically triggers `Checkpoint-Computer -Description "VDOWNS_PrimeBoost"` before applying optimizations.

### 2. 🌐 High-Performance DNS Benchmark & Optimizer
- **Curated High-Speed Resolvers:** Instant switching between **Cloudflare (1.1.1.1)**, **Google (8.8.8.8)**, **AdGuard Ad-Blocking (94.140.14.14)**, and **Quad9 Security (9.9.9.9)**.
- **Ping Latency Benchmark:** Pings all candidate DNS servers in real time, displaying round-trip millisecond response times in the log console to help choose the fastest server.
- **One-Click DHCP Reset:** Revert all network adapters back to automatic dynamic DHCP configuration instantly.

### 3. 🚀 Windows Startup Programs Manager
- **Non-Destructive Safe Toggle:** Scans `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run` and lists all startup entries.
- **Reversible Registry Archival:** When disabling an item, its full executable path and launch parameters are moved to `HKCU:\Software\VDOWNS\DisabledStartup` rather than being permanently deleted. Can be re-enabled at any time.

### 4. 📦 Dynamic App Center & In-GUI Package Wizard
- **Database-Driven Catalog (`apps.json`):** Curated applications grouped into 7 major categories with instant category filter chips (`All`, `Browsers`, `Dev`, `Gaming`, `Utilities`, `Security`, `Communication`).
- **➕ In-GUI Custom App Addition Modal:** Add custom applications directly from the GUI without touching raw JSON files. Validates Winget package identifiers using strict regex (`^[a-zA-Z0-9_\-\.]+$`) to eliminate CLI/JSON injection risks.
- **Winget Live Search & Quick Install (`⚡`):** Query Microsoft Community Repository in real-time and install/upgrade/uninstall directly from glassmorphic cards.

### 5. ⏸️ Windows Update Deferral Controls
- **35-Day Deferral / Pause:** Safely defers Windows Feature & Quality updates for up to 35 days using native group policy registry keys (`HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`), preventing disruptive reboots during active development or gaming.
- **Instant Resume:** Re-enables automatic update scans and servicing immediately with one click.

### 6. ⚡ Reversible System Tweaks & Debloater
- **Privacy & Telemetry:** Disable Telemetry (DiagTrack), Diagnostics Tracking, Advertising ID, Activity History, and automatic O&O ShutUp10 privacy enforcement.
- **Interface & Explorer:** Force Dark Mode, restore Classic Windows 10 Context Menu on Windows 11, align Taskbar left, show file extensions and hidden files.
- **Performance & Gaming:** Unlock Windows Ultimate Performance power plan, disable Xbox Game DVR background recording, disable SysMain (Superfetch) for NVMe/SSD, disable Sticky Keys, enable Storage Sense.
- **AppX Debloater:** Non-destructively purges non-essential bloatware (Cortana, Bing News, Weather, Microsoft Solitaire, People, Xbox Game Bar) while strictly protecting essential system utilities.

### 7. 💾 Developer Backup & Standalone Unattended Script Generator
- **Asynchronous Runspace Snapshotting:** Archive developer tools into `.zip` without freezing the UI (VS Code, Cursor, Git config, PowerShell profile, Windows Terminal, Notepad++, SSH host keys).
- **Standalone Unattended Script Generator (.ps1):** Export selected apps, tweaks, and debloat settings into a single autonomous, self-elevating script (`VDOWNS_Unattended_Setup.ps1`) for instant bare-metal provisioning.

---

## 🏗️ Project Structure

```
Vdowns_2.0/
├── .github/
│   └── workflows/
│       └── release.yml         # Automated GitHub Actions CI/CD release workflow
├── apps.json                   # Curated software packages catalog (96+ apps)
├── build.ps1                   # Automated build, AST syntax check & ps2exe compilation
├── LICENSE                     # MIT License
├── README.md                   # Complete architectural documentation & user guide
├── VDOWNS_PRIME.exe            # Standalone compiled portable 64-bit binary (v3.3.0)
├── VDOWNS_PRIME.ps1            # Canonical modern WPF + Async Runspace engine
├── vdowns.ps1                  # Backward-compatibility launcher forwarder
├── Picture/                    # Interface assets and screenshots
└── Source/
    ├── apps.json               # Catalog backup / local source copy
    ├── vdowns_2.0.ps1          # Legacy WinForms fallback reference
    └── vdowns_3.0.ps1          # Synced source script (v3.3.0)
```

---

## 💻 Building from Source

### Prerequisites
- Windows 10 (Build 19041+) or Windows 11 (x64)
- PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for system tweaks, debloater, and DNS switching)
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
1. Download `VDOWNS_PRIME.exe` and `apps.json` from [Releases](https://github.com/Gorkem-Taha/VDOWNS-PRIME/releases).
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
> This software directly interfaces with the Windows Registry, Component-Based Servicing (CBS), network adapters, and system services. Always utilize the automated **Create Restore Point** before applying bulk system tweaks, debloater commands, or 1-Click Prime Optimization.

---

## 📜 Versioning & Conventions

This repository adheres to [Semantic Versioning 2.0.0](https://semver.org/) (`vMAJOR.MINOR.PATCH`) and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
- Releases are tagged with standard git tags (e.g. `v3.3.0`).
- Commits are structured as `feat:`, `fix:`, `refactor:`, `chore(release):`.

---

## 👤 Author & License
- **Author:** [Görkem Taha Çanakcı](https://github.com/Gorkem-Taha)
- **Repository:** [VDOWNS-PRIME](https://github.com/Gorkem-Taha/VDOWNS-PRIME)
- **License:** [MIT License](LICENSE)
