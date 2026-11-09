@echo off
setlocal
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"
if not exist "%HERE%\uninstall.ps1" (
  echo [!] uninstall.ps1 not found next to this file.
  pause
  exit /b 1
)
rem Detach on purpose: PowerShell deletes the very folder this script lives in,
rem so this script must not wait for it (cmd cannot resume reading a deleted file).
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HERE%\uninstall.ps1" -InstallDir "%HERE%" %*
exit /b 0
