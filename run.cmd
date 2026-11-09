@echo off
setlocal
cd /d "%~dp0"
set "AHK=%~dp0src\AutoHotkey64.exe"
if not exist "%AHK%" goto noahk
start "" "%AHK%" "%~dp0src\StillKeepWatch.ahk"
exit /b 0
:noahk
echo [!] src\AutoHotkey64.exe not found.
pause
exit /b 1
