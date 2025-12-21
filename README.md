# ⚡ VDOWNS PRIME v1.0 | System Architect

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-00A8FF?style=for-the-badge&logo=windows)
![Language](https://img.shields.io/badge/Language-PowerShell-5391FE?style=for-the-badge&logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Stable-F1C40F?style=for-the-badge)

**VDOWNS PRIME** is an advanced system configuration tool featuring an "Elite Dark" theme, designed to architect your Windows experience. It transforms fresh or existing installations into optimized, structured environments in seconds.

Instead of dealing with complex PowerShell commands, manage your system through a modern GUI. Install applications, optimize performance, and eliminate bloatware effortlessly.

## 📸 Screenshots

*(Add a screenshot of the running program here - recommended)*

---

## 🔥 Key Features

### 1. 📦 Dynamic App Center (Database Driven)
Unlike ordinary installers, **VDOWNS PRIME** draws its power from the `apps.json` database.
- **100+ Popular Apps:** A vast archive ranging from Browsers to Dev Tools, Gaming platforms to Runtime libraries.
- **Winget Integration:** Fetches the latest and most secure versions directly from Microsoft servers.
- **Batch Installation:** Installs dozens of selected apps in a single click, silently.

### 2. ⚡ Advanced System Tweaks
Unlock your computer's true potential.
- **Desktop & Laptop Profiles:** Automatic optimization based on device type.
- **Performance:** Ultimate Performance mode, SysMain optimization.
- **Privacy:** Telemetry blocking, Ad ID disabling, O&O ShutUp10 integration.
- **Interface:** Dark mode, classic context menu, show file extensions.

### 3. 🛡️ Debloater (System Cleanup)
Get rid of the junk that comes pre-installed with Windows.
- Removes unnecessary apps like Bing News, Weather, Cortana, People, and Solitaire in a single click.
- Reduces RAM usage by minimizing background processes.

### 4. 🔧 Configuration & Maintenance
- **WSL 2 & Hyper-V:** Enable virtualization tools for developers with one click.
- **Deep Clean:** Deeply cleans Windows temporary files.
- **Update Center:** Keeps both Windows and all installed apps up to date.

---

## 🚀 Installation & Usage

This tool is portable; no installation is required.

1. Download the latest release (`v1.0.zip`) from the **Releases** section.
2. Extract the folder to your desktop.
3. **⚠️ IMPORTANT:** Ensure `VDOWNS_PRIME.exe` and `apps.json` are located in the **same folder**.
4. Right-click `VDOWNS_PRIME.exe` and select **Run as Administrator**.

### 📂 Create Your Own App List
The `apps.json` file is fully customizable! To add your own favorite apps, open the file with any text editor and use the following format:

```json
{
  "My Category": [
    { 
      "Name": "App Name", 
      "Id": "Winget.ID", 
      "Desc": "Description" 
    }
  ]
}
```
⚠️ Disclaimer
This software makes changes to the Windows Registry and system services. The "Create Restore Point" feature is available within the program; it is highly recommended to use this before applying any changes. The user is responsible for any system errors that may occur.
<br>
## 📜 License

This project is licensed under the [MIT License](LICENSE).  
Developed by **[Görkem Taha Çanakcı](https://github.com/Gorkem-Taha)**