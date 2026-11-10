; StillKeep installer script (Inno Setup 6)
; 版本号由 build.ps1 通过 /DVersion= 传入，不在本文件里重复。

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
MinVersion=10.0
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\AutoHotkey64.exe
VersionInfoVersion={#Version}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#Version}
VersionInfoDescription=StillKeep Setup

[Languages]
Name: "chinesesimplified"; MessagesFile: "languages\ChineseSimplified.isl"

[Tasks]
Name: "autostart"; Description: "开机自动启动（随 Edge 启停）"; GroupDescription: "附加任务："; Flags: checkedonce
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: unchecked

[Files]
Source: "{#Src}\src\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Src}\VERSION"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\packaging\uninstall-cleanup.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; WorkingDir: "{app}"; Comment: "启动 StillKeep"
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; WorkingDir: "{app}"; Comment: "启动 StillKeep"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "StillKeep"; ValueData: """{app}\AutoHotkey64.exe"" ""{app}\StillKeepWatch.ahk"""; Flags: uninsdeletevalue; Tasks: autostart

[Run]
Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\StillKeepWatch.ahk"""; Description: "立即启动 {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall-cleanup.ps1"""; Flags: runhidden waituntilterminated; RunOnceId: "StopStillKeep"

[UninstallDelete]
Type: files; Name: "{app}\*.log"
Type: files; Name: "{app}\*.pid"
