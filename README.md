# ⚡ VDOWNS PRIME v2.0 | System Architect

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-00A8FF?style=for-the-badge&logo=windows)
![Language](https://img.shields.io/badge/Language-PowerShell-5391FE?style=for-the-badge&logo=powershell)
![Version](https://img.shields.io/badge/Version-v2.0%20Prime-E74C3C?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**VDOWNS PRIME v2.0** is the ultimate system configuration tool designed for power users, gamers, and system administrators. It combines a sleek "Elite Dark" GUI with powerful backend scripting to architect your Windows experience.

Unlike v1.0, the **Prime v2.0** update introduces a **Live Process Monitor**, allowing you to see exactly what is happening in the background during updates and repairs, integrated directly into the interface.

---

## 📸 Screenshots

![VDOWNS PRIME](/Picture/VDOWNS_PRIME_2.0.png)

---

## 🔥 Key Features & Detailed Documentation

### 1. 📦 Dynamic App Center (Fully Customizable)
The App Center allows you to batch-install or batch-uninstall applications using the native **Windows Package Manager (Winget)**.

- **Bulk Installation:** Select multiple apps and install them all silently in the background.
- **Bulk Uninstallation:** Remove unwanted apps cleanly.
- **Database Driven:** The app list is not hardcoded. It is pulled from an external `apps.json` file.

#### ⚙️ How to Customize `apps.json`
You can add your own favorite programs or remove existing ones by editing the `apps.json` file found in the script directory.

**Structure:**
```json
{
  "Browsers": [
    { "Name": "Google Chrome", "Id": "Google.Chrome" },
    { "Name": "Firefox", "Id": "Mozilla.Firefox" }
  ],
  "Development": [
    { "Name": "VS Code", "Id": "Microsoft.VisualStudioCode" }
  ]
}
```
### 2. ⚡ System Tweaks (Do & Undo)
This module directly manipulates the Windows Registry and System Services to optimize the OS. Every tweak includes a Revert (Undo) capability.
<br>
### 🛡️ Essential Privacy

| Name | Description | 
| --- | --- |
| `Create Restore Point` | Creates a Windows System Restore point before you make changes. Highly Recommended.| 
| `Run O&O ShutUp10` | Downloads and launches the industry-standard privacy tool O&O ShutUp10 for granular privacy control.| 
| `Disable Telemetry` | Disables the "Connected User Experiences and Telemetry" (DiagTrack) service to stop data collection. | 
| `Disable Ad ID` | Prevents Windows from creating a unique advertising ID for tracking your usage. |

 ### 🎨 Interface Explorer

| Name | Description | 
| --- | --- |
| `Dark Mode (System)` | Forces Windows System elements (Taskbar, Start Menu) into Dark Mode.| 
| `Dark Mode (Apps)` | Forces supported apps (Explorer, Settings) into Dark Mode.| 
| `Show Hidden Files` | Reveals hidden files and folders in File Explorer. | 
| `Show File Extensions` | Shows file extensions (e.g., .txt, .exe) for security and clarity. |
| `Launch to 'This PC'` | Sets File Explorer to open "This PC" instead of "Quick Access".| 
| `Classic Context Menu` | Restores the Windows 10 style right-click menu on Windows 11.| 
| `Align Taskbar Left` | Moves the Windows 11 Taskbar icons to the left (Classic style). | 
| `Hide Search Icon` | Removes the Search icon/bar from the taskbar to save space. |
| `Clipboard History` | Enables the `Win+V` clipboard history feature. |

 ### 🚀 Performance Power

| Name | Description | 
| --- | --- |
| `Disable Sticky Keys` | Disables the "Sticky Keys" shortcut (pressing Shift 5 times), crucial for gamers.| 
| `Enable Hibernate` | Enables the Hibernation power state option in the Start Menu.| 
| `Storage Sense` | Enables Windows Storage Sense to automatically clean up temp files. | 
| `Ultimate Performance` | Unlocks and adds the "Ultimate Performance" power plan (requires manual selection in Control Panel). |
| `Disable SysMain` | Disables the SysMain (Superfetch) service to reduce high disk usage on SSDs.| 
| `Disable Game DVR` | Disables Xbox Game DVR background recording to improve FPS in games.| 

### 3. 🔧 Features & Configuration

Manage optional Windows components and perform deep maintenance.

- **Hyper-V Platform:** Enables hardware virtualization (Required for Docker/VMs).
- **WSL 2 (Linux):** Enables the Windows Subsystem for Linux.
- **Windows Sandbox:** Enables a lightweight desktop environment to safely run applications in isolation.
- **Net Framework 3.5:** Installs older .NET libraries required by many legacy games and apps.

### 🧹 Deep System Clean
This is not a standard disk cleanup. It:

1.Configures the registry to select all cleanup categories (Update Cleanup, Temp Files, Logs, etc.).
2.Runs the Windows Disk Cleanup utility `(cleanmgr.exe)` in extended mode.
<br>

### 4. 🛡️ Advanced Debloater
Remove pre-installed bloatware that consumes RAM and CPU.
> [!WARNING]
> This process permanently removes applications. A backup is recommended.

- **Bloatware Categories:** Targets specific groups like "News & Weather", "Solitaire", "Cortana", "Xbox Overlay", "People App", and "Get Help".
- **Safety First:** Critical system components are not targeted, but items like "Calculator" or "Photos" are optional choices if you use 3rd party alternatives.
- **Mechanism:** Uses `Remove-AppxPackage` commands to wipe the apps from the current user profile.

### 4. 🔄 Update & Repair Center
This embedded console allows you to watch the real-time output of PowerShell commands directly inside the GUI, ensuring you know exactly when a task is finished.

### 📥 Update Modules

- **UPDATE ALL APPS (Winget):** Checks every installed program on your PC against the Winget database and updates them to the latest version. Includes apps not originally installed by Winget.
- **UPDATE WINDOWS (OS Only):** Uses the `PSWindowsUpdate` module to download and install cumulative updates, security patches, and feature updates directly from Microsoft Update servers.
- **UPDATE DRIVERS ONLY:** Scans specifically for hardware driver updates (GPU, Chipset, Audio) and installs them.
- **FORCE MS STORE UPDATES:** Forces the Microsoft Store itself and all Store apps (UWP) to update.

### 🛠️ System Repair Tools

- **RUN SFC /SCANNOW:** Runs the System File Checker to repair corrupted Windows system files.
- **RUN DISM REPAIR:** Runs the Deployment Image Servicing and Management tool to repair the Windows System Image using Windows Update as the source.
- **RESET NETWORK STACK:** Flushes DNS, resets Winsock, and resets the IP stack. Useful if you have internet connection issues.
- **EMERGENCY: FIX STUCK UPDATES:** A powerful script that forcibly stops Windows Update services, deletes the `SoftwareDistribution` cache folder (where corrupt update files often live), and restarts the services. Use this if Windows Update is stuck at 0%.
---

### 🚀 Installation & Usage
This tool is portable; no installation is required.

1. Download the latest release (`v2.0.zip`) from the **Releases** section.
2. Extract the folder to your desktop.
3. **⚠️ IMPORTANT:** Ensure `VDOWNS_PRIME.exe` and `apps.json` are located in the **same folder**.
4. Right-click `VDOWNS_PRIME.exe` and select **Run as Administrator**.
---
<br>

> [!NOTE]
> If running as a .ps1 script, you may need to allow script execution: `Set-ExecutionPolicy Bypass -Scope Process`
<br>

> [!WARNING]
> This software makes changes to the Windows Registry and system services. The `Create Restore Point` feature is available within the program; it is highly recommended to use this before applying any changes. The user is responsible for any system errors that may occur.
---
<br>

## 📜 License
This project is licensed under the [MIT License](LICENSE).  
Developed by **[Görkem Taha Çanakcı](https://github.com/Gorkem-Taha)**
