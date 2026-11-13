# Changelog

All notable changes to VDOWNS PRIME. Format based on [Keep a Changelog](https://keepachangelog.com/),
versions follow [Semantic Versioning](https://semver.org/).

## [3.4.0] - unreleased

A reliability and safety release based on a full code review. Several features advertised in 3.3.x
did not work; they are fixed here.

### Fixed
- **Add App wizard** could never save (its category list was empty).
- **Debloater "Select Recommended"** selected everything and immediately cleared it again; a
  separate *Clear Selection* button was added.
- **Unattended script generator** exported only 7 of 19 tweaks and used display labels as package
  patterns, so almost nothing was removed. It now embeds the exact tweak code and real patterns.
- **15 catalog IDs** did not exist in winget (Signal, AnyDesk, Krita, Ditto, ImageGlass, Python, …);
  Wallpaper Engine and LosslessCut (not on winget) were replaced with Lively Wallpaper and Shotcut,
  Meslo Nerd Font with JetBrainsMono Nerd Font;
  UniGetUI moved to `Devolutions.UniGetUI`.
- **Developer backup** aborted at the PowerShell profile step; Cursor settings were backed up but
  never restored.
- Health score was not refreshed after Quick Boost; feature/maintenance headings were not shown;
  *Update Drivers* installed all updates instead of drivers only.
- Tweak failures were logged as SUCCESS; tweaks now stop on errors and check exit codes.
- File dialogs failed when running the `.ps1` directly (WinForms was not loaded); handlers relied
  on closures that cannot see script functions when started with `-File`.
- Background tasks leaked timers/runspaces; errors in background tasks were swallowed.
- Winget list/search parsing broke on truncated names and adjacent columns.
- `winget install --force` reinstalled already installed apps.
- Possible deadlock when a tool wrote a lot to stderr; console windows flashing in the exe.
- Script saved as UTF-8 without BOM (garbled UI text in Windows PowerShell 5.1).

### Security / data safety
- **Revert** restores the exact pre-tweak state (snapshots in `HKCU\Software\VDOWNS\TweakState`)
  instead of writing fixed values.
- **Deep Clean** uses a safe allow-list; it previously selected every Disk Cleanup handler,
  including Downloads, previous Windows installations and ESD recovery files.
- O&O ShutUp10 runs only with a valid O&O Software signature.
- PSWindowsUpdate pinned to 2.2.1.5 and signature-checked; `-SkipPublisherCheck` removed.
- Startup manager keeps each entry's origin (HKCU/HKLM/WOW6432Node) and value type.
- Backup restore: confirmation, zip-slip protection, automatic copy of the current files.
- Catalog web links open only `http(s)` URLs.
- Warning when the app is elevated as a different account than the signed-in user.
- Build pins ps2exe 1.0.18; CI actions pinned to commit SHAs; releases ship `SHA256SUMS`.

### Added
- Category filter chips and a busy indicator on the Winget tab.
- Optional removal of provisioned Store packages (new user accounts).
- DNS: IPv6 resolvers, all active adapters, real lookup benchmark in the background.
- WSL 2 also enables Virtual Machine Platform; Home edition hint for Hyper-V/Sandbox.
- Single version source (`$script:VdownsVersion`), used by the UI, generated scripts and the build.

### Development
- Source split into `src/app` fragments, `src/lib` helper libraries and `src/ui/MainWindow.xaml`;
  `tools/Merge-Source.ps1` generates the single-file `VDOWNS_PRIME.ps1` (verified byte-identical
  when introduced) and embeds `apps.json` directly, so the fallback catalog can no longer drift.
- Pester 5 test suites (catalog, source rules, native runner, winget parser, tweak snapshot/revert,
  generators, UI filter, WPF load) and a CI workflow on Linux + Windows PowerShell 5.1 with a real
  registry round trip and smoke tests of the `.ps1` and the compiled exe; releases require CI.
- `VDOWNS_SMOKE_TEST=1` startup mode for automated testing (no dialogs, writes a report, exits).

### Removed
- Compiled exe and duplicate `Source/` copies from the repository (the exe is a release asset).
- Unreachable handlers for buttons that no longer exist in the UI.

## [3.3.1] - 2026-09-05
- Null-safe control lookups, line ending normalization, dispatcher hardening.

## [3.3.0] - 2026-09-04
- PC health score and Quick Boost, DNS switcher, startup manager, custom app wizard,
  35-day Windows Update pause, GitHub Actions release workflow.

## [3.2.0] - 2026-09-04
- Fluent-style interface with vector icons, live CPU/RAM/disk telemetry, collapsible log.

## [3.1.0] - 2026-09-04
- Embedded fallback catalog, asynchronous developer backup, unattended setup script generator.

## [3.0.0] - 2026-09-04
- Rewrite from WinForms to WPF with background runspaces and a winget manager.

## [2.0.0] - 2025-12-23
- WinForms release (kept in `legacy/`).
