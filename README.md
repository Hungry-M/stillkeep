# StillKeep

A patch for Edge's download confirmation dialog. Installs per user, starts with Windows by default.

Tested on Edge `157.0.4341.42` / Windows 10 `19045`.

> Unofficial project, not affiliated with Microsoft. The patch works at the Windows input
> layer and does not modify any Edge file.
> [简体中文](README.zh.md) · other documents in this repo are Chinese-only for now.

---

## What it fixes

When SmartScreen blocks a download and you click **Keep** in the toolbar download menu, Edge
shows a confirmation dialog. The `Delete ▾` arrow in that dialog is rendered invisible: clicking
it deletes the file, and pressing `Enter` on it deletes too — but pressing `↓` correctly opens the
dropdown containing **Keep anyway**.

**Same control: the mouse takes the destructive branch, `↓` takes the menu branch.**

The patch does one thing: it restores what clicking `▾` was supposed to do — open the menu and let
you decide. It never presses Enter for you, never patches binaries, never disables SmartScreen.

---

## Download

Grab one of these from [Releases](https://github.com/Hungry-M/stillkeep/releases):

| Asset | Purpose |
| --- | --- |
| `StillKeep-0.1.1-Setup.exe` | Installer (recommended). Installs to `%LOCALAPPDATA%\Programs\StillKeep` with an uninstall entry, Start Menu shortcut and autostart |
| `StillKeep-0.1.1-portable.zip` | Extract and run. No registry, no service |

Verify before running:

```powershell
Get-FileHash .\StillKeep-0.1.1-Setup.exe -Algorithm SHA256
```

Compare with the value in `SHA256SUMS.txt`.

---

## Install

Double-click `StillKeep-0.1.1-Setup.exe`. No administrator rights required.

- Install dir: `%LOCALAPPDATA%\Programs\StillKeep`
- Data dir: `%LOCALAPPDATA%\StillKeep` (logs)
- Writes: Start Menu shortcut, `HKCU` uninstall entry
- **Autostart is checked by default** (`HKCU\...\Run`). Uncheck it, or pass `/TASKS=""`, to skip

The wizard asks for a language first (English or 简体中文).

Silent install:

```powershell
StillKeep-0.1.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
StillKeep-0.1.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS=""   # no autostart
```

> Do not launch the installer from a restricted terminal or sandbox. Child processes inherit a
> restricted token, creating `%APPDATA%` and `HKCU` entries fails with `Error 5`, and Inno rolls
> the install back. Launch it from Explorer.

### Portable

Extract `portable.zip` and run `run.cmd`. It only starts the watchdog — no registry, no shortcuts.

### From source (no installer)

The source tree ships `install.cmd` / `uninstall.cmd`:

```powershell
install.cmd -NoAutostart
install.cmd -Silent -ResultFile r.json
install.cmd -InstallDir D:\Apps\StillKeep
```

---

## Uninstall

**Installed via Setup.exe**: Settings → Apps → Installed apps → StillKeep, or the Start Menu
shortcut "卸载 StillKeep".

The Inno uninstaller calls `uninstall-cleanup.ps1` first: it stops only the `AutoHotkey64.exe`
processes whose path is inside the install dir, clears the `Run` value, then removes files,
shortcuts and the uninstall entry.

**Installed from source**: `uninstall.cmd` in the install dir, or `uninstall.cmd -Yes`.

- Only provably-ours artifacts are removed: install location, the `StillKeepWatch.ahk` marker in
  the directory, shortcut targets. Anything that does not match is skipped, never guessed.
- The log dir `%LOCALAPPDATA%\StillKeep` is kept by default; so are backups from the script
  uninstaller (`-RemoveBackups` removes them).

---

## Autostart

The installer writes:

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
  StillKeep = "<install>\AutoHotkey64.exe" "<install>\StillKeepWatch.ahk"
```

It starts the **watchdog**, which keeps the worker tied to Edge:

```text
watchdog (always resident)
  ├─ Edge has a window → start worker (the actual patch)
  └─ no Edge window     → stop worker
```

---

## Hotkeys

| Key | Action |
|---|---|
| `Ctrl+Alt+K` | Open the "Keep anyway" menu |
| `Ctrl+Alt+G` | Toggle click interception |
| `Ctrl+Alt+F12` | Probe: dump Edge window info to the log |

---

## Layout

```text
StillKeep/
├─ install.cmd          script installer entry (pure ASCII)
├─ install.ps1          installer logic (UTF-8 BOM)
├─ uninstall.cmd        script uninstaller entry
├─ uninstall.ps1        uninstaller logic
├─ run.cmd              portable launcher
├─ VERSION
├─ LICENSE
├─ README.md            this file
├─ README.zh.md         Chinese README
├─ CHANGELOG.md
├─ CONTRIBUTING.md
├─ SECURITY.md
├─ THIRD_PARTY_NOTICES.md
├─ packaging/
│  ├─ stillkeep.iss          Inno Setup script
│  ├─ build.ps1              builds Setup.exe + portable.zip
│  ├─ uninstall-cleanup.ps1  stops processes before uninstall
│  └─ languages/             installer UI language files
└─ src/
   ├─ StillKeep.ahk          worker: window matching + click remap
   ├─ StillKeepWatch.ahk     watchdog: starts/stops worker with Edge
   ├─ AutoHotkey64.exe       AutoHotkey v2.0.31
   └─ LICENSE-AutoHotkey.txt
```

`.cmd` files must be pure ASCII with CRLF (cmd.exe reads them in the OEM code page; non-ASCII
comments get parsed as commands). `.ps1` files containing non-ASCII must be UTF-8 **with BOM**
(PowerShell 5.1 falls back to ANSI otherwise).

---

## Troubleshooting

Log: `%LOCALAPPDATA%\StillKeep\stillkeep.log`

| Line | Meaning |
|---|---|
| `watch: edge up -> spawn worker` | Watchdog saw Edge and started the worker |
| `watch: edge gone -> stop worker` | Edge closed, worker stopped |
| `open-menu: menu hwnd=...` | Menu opened successfully |
| `open-menu: menu not found` | Menu window not recognised; adjust `FindMenuWindow` |
| `open-menu: no dialog` | Confirmation dialog not recognised; adjust `IsKeepDialog` |

Press `Ctrl+Alt+F12` while the dialog is up; the log lists every Edge window with
`popup / owned / rect / title`, which is what you need to tune the matching.

---

## Verification status

**Verified** (locally, or in an isolated sandbox):

- The failure mode itself, and that `↓` opens the menu (on both "Delete" and the invisible control)
- Watchdog starts and stops the worker as Edge opens and closes; PID file handling
- Script installer/uninstaller run end to end in an isolated directory
- `.cmd` / `.ps1` encoding and line endings
- Inno script compiles; file copy stage completes

**Not verified** (environment blocks it; needs a normal desktop):

- Full Setup.exe install (registry + Start Menu shortcut) — their child processes are denied
  `%APPDATA%` and `HKCU` writes here (`Error 5`), and Inno rolls back
- Uninstall via Settings → Apps

---

## Reporting upstream

This bug is worth reporting to Microsoft at `edge://feedback`:

> After SmartScreen blocks a download, clicking "Keep" in the toolbar download menu opens a
> confirmation dialog. The dropdown arrow next to "Delete" is invisible; clicking that area
> deletes the file, the control is present but not rendered in the Tab order, and pressing Enter
> on it also deletes. Only ↓ opens the dropdown (which contains "Keep anyway"). One control,
> mouse takes the destructive branch, keyboard takes the menu branch. The same keep action works
> in edge://downloads.

---

## Known limitations

- Window matching is heuristic. A new same-sized popup could be misidentified; the consequence is
  interception doing nothing or sending `Esc`, never a deleted file.
- An Edge update may change the window structure and break the patch. When it breaks, it stops
  acting — it does not damage the browser.
- Only tested on Edge `157.0.4341.42` / Windows 10 `19045`.
- The installer is unsigned, so Windows may warn about an unknown publisher. That is expected.
- Other Chromium browsers are untested; the same approach should apply.

## License

[MIT](LICENSE) — commercial use and modification allowed; redistributions must keep the copyright
and license notice.

The bundled AutoHotkey interpreter is GPL-2.0; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Commits need a DCO sign-off (`git commit -s`).
