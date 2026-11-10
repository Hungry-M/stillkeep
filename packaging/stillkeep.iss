; StillKeep installer script (Inno Setup 6)
; 鐗堟湰鍙风敱 build.ps1 閫氳繃 /DVersion= 浼犲叆锛屼笉鍦ㄦ湰鏂囦欢閲岄噸澶嶃€?
#ifndef Version
  #define Version "0.0.0"
#endif

#define AppName "StillKeep"
#define AppPublisher "Hungry-M"
#define AppUrl "https://github.com/Hungry-M/stillkeep"
#define Src AddBackslash(SourcePath) + ".."

[Setup]
AppId={{6A1F3D2C-9B47-4E85-A0C3-2D7E5B1F9A64}
AppName={#AppName}
AppVersion={#Version}
AppVerName={#AppName} {#Version}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#Src}\dist
OutputBaseFilename={#AppName}-{#Version}-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=auto
MinVersion=10.0
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\AutoHotkey64.exe
VersionInfoVersion={#Version}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#Version}
VersionInfoDescription=StillKeep Setup

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "languages\ChineseSimplified.isl"

[CustomMessages]
TaskAutostart=Start with Windows (follows Edge)
TaskDesktopIcon=Create a desktop shortcut
GroupAdditional=Additional tasks:
RunApp=Launch StillKeep now
UninstallShortcut=Uninstall StillKeep

chinesesimplified.TaskAutostart=寮€鏈鸿嚜鍔ㄥ惎鍔紙闅?Edge 鍚仠锛?chinesesimplified.TaskDesktopIcon=鍒涘缓妗岄潰蹇嵎鏂瑰紡
chinesesimplified.GroupAdditional=闄勫姞浠诲姟锛?chinesesimplified.RunApp=绔嬪嵆鍚姩 StillKeep
chinesesimplified.UninstallShortcut=鍗歌浇 StillKeep

[Tasks]
Name: "autostart"; Description: "{cm:TaskAutostart}"; GroupDescription: "{cm:GroupAdditional}"; Flags: checkedonce
Name: "desktopicon"; Description: "{cm:TaskDesktopIcon}"; GroupDescription: "{cm:GroupAdditional}"; Flags: unchecked

[Files]
Source: "{#Src}\src\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Src}\VERSION"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\README.zh.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\packaging\uninstall-cleanup.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; WorkingDir: "{app}"; Comment: "{cm:RunApp}"
Name: "{group}\{cm:UninstallShortcut}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; WorkingDir: "{app}"; Comment: "{cm:RunApp}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "StillKeep"; ValueData: """{app}\AutoHotkey64.exe"" ""{app}\StillKeepWatch.ahk"""; Flags: uninsdeletevalue; Tasks: autostart

[Run]
Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; Description: "{cm:RunApp}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall-cleanup.ps1"""; Flags: runhidden waituntilterminated; RunOnceId: "StopStillKeep"

[UninstallDelete]
Type: files; Name: "{app}\*.log"
Type: files; Name: "{app}\*.pid"
