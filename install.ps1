<#
    StillKeep 安装器
    按当前用户安装，不需要管理员权限，不写 Program Files。

    用法:
        install.cmd                 正常安装（默认开机自启）
        install.cmd -NoAutostart    不写开机自启
        install.cmd -Silent -ResultFile out.json
#>
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\StillKeep'),
    [string]$DataDir    = (Join-Path $env:LOCALAPPDATA 'StillKeep'),
    [switch]$NoRegistry,
    [switch]$NoShortcut,
    [switch]$NoAutostart,
    [switch]$SkipStart,
    [switch]$Silent,
    [string]$ResultFile
)

$ErrorActionPreference = 'Stop'
$AppName   = 'StillKeep'
$Publisher = 'Hungry-M'
$InstallDir = $InstallDir.TrimEnd('\')

$result = [ordered]@{
    ok          = $false
    app         = $AppName
    version     = ''
    install_dir = $InstallDir
    steps       = New-Object System.Collections.ArrayList
    error       = ''
}

function Add-Step([string]$s) { [void]$script:result.steps.Add($s) }

try {
    $version = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'VERSION') -Raw).Trim()
    $result.version = $version
    $src = Join-Path $PSScriptRoot 'src'

    if (-not (Test-Path -LiteralPath (Join-Path $src 'AutoHotkey64.exe'))) {
        throw '安装包不完整：缺少 src\AutoHotkey64.exe'
    }
    Add-Step 'payload: ok'

    if (Test-Path -LiteralPath $InstallDir) {
        $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = Join-Path $DataDir (Join-Path 'backups' $stamp)
        New-Item -ItemType Directory -Force -Path $backup | Out-Null
        Get-ChildItem -LiteralPath $InstallDir -Force | Copy-Item -Destination $backup -Recurse -Force
        Add-Step "backup: $backup"
    }

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Get-ChildItem -LiteralPath $src -Force | Copy-Item -Destination $InstallDir -Recurse -Force
    foreach ($f in 'VERSION', 'uninstall.cmd', 'uninstall.ps1', 'LICENSE') {
        $p = Join-Path $PSScriptRoot $f
        if (Test-Path -LiteralPath $p) {
            Copy-Item -LiteralPath $p -Destination $InstallDir -Force
        }
    }
    Add-Step "copy: $InstallDir"

    if (-not $NoShortcut) {
        $lnkPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\StillKeep.lnk'
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkPath)
        $lnk.TargetPath       = Join-Path $InstallDir 'AutoHotkey64.exe'
        $lnk.Arguments        = '"' + (Join-Path $InstallDir 'StillKeepWatch.ahk') + '"'
        $lnk.WorkingDirectory = $InstallDir
        $lnk.IconLocation     = (Join-Path $InstallDir 'AutoHotkey64.exe') + ',0'
        $lnk.Description      = 'StillKeep'
        $lnk.Save()
        Add-Step "shortcut: $lnkPath"
    }

    if (-not $NoRegistry) {
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"
        New-Item -Path $key -Force | Out-Null
        $exe = Join-Path $InstallDir 'AutoHotkey64.exe'
        $ps  = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $ps1 = Join-Path $InstallDir 'uninstall.ps1'
        # 直接用 powershell 调 uninstall.ps1，不经过 .cmd：
        # 批处理删除自己所在的目录后，cmd 读不到后续行，会报错并返回 1。
        $unc = '"' + $ps + '" -NoProfile -ExecutionPolicy Bypass -File "' + $ps1 + '" -InstallDir "' + $InstallDir + '" -Yes'
        Set-ItemProperty -Path $key -Name 'DisplayName'          -Value 'StillKeep'
        Set-ItemProperty -Path $key -Name 'DisplayVersion'       -Value $version
        Set-ItemProperty -Path $key -Name 'Publisher'            -Value $Publisher
        Set-ItemProperty -Path $key -Name 'InstallLocation'      -Value $InstallDir
        Set-ItemProperty -Path $key -Name 'DisplayIcon'          -Value $exe
        Set-ItemProperty -Path $key -Name 'UninstallString'      -Value $unc
        Set-ItemProperty -Path $key -Name 'QuietUninstallString' -Value $unc
        New-ItemProperty -Path $key -Name 'NoModify'      -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $key -Name 'NoRepair'      -Value 1 -PropertyType DWord -Force | Out-Null
        $size = 0
        Get-ChildItem -LiteralPath $InstallDir -Recurse -File | ForEach-Object { $size += $_.Length }
        New-ItemProperty -Path $key -Name 'EstimatedSize' -Value ([int]($size / 1KB)) -PropertyType DWord -Force | Out-Null
        Add-Step "registry: $key"
    }

    if (-not $NoAutostart) {
        $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $val = '"' + (Join-Path $InstallDir 'AutoHotkey64.exe') + '" "' + (Join-Path $InstallDir 'StillKeepWatch.ahk') + '"'
        Set-ItemProperty -Path $run -Name $AppName -Value $val
        Add-Step "autostart: HKCU Run\$AppName"
    }

    if (-not $SkipStart) {
        Get-Process -Name AutoHotkey64 -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $p = $_.Path
                if ($p -and $p.StartsWith($InstallDir, [StringComparison]::OrdinalIgnoreCase)) {
                    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                }
            } catch { }
        }
        Start-Sleep -Milliseconds 300
        Start-Process -FilePath (Join-Path $InstallDir 'AutoHotkey64.exe') `
                      -ArgumentList ('"' + (Join-Path $InstallDir 'StillKeepWatch.ahk') + '"') `
                      -WorkingDirectory $InstallDir
        Start-Sleep -Milliseconds 900
        Add-Step 'start: watcher'
    }

    $missing = @()
    foreach ($f in 'AutoHotkey64.exe', 'StillKeep.ahk', 'StillKeepWatch.ahk', 'uninstall.cmd') {
        if (-not (Test-Path -LiteralPath (Join-Path $InstallDir $f))) { $missing += $f }
    }
    if ($missing.Count -gt 0) { throw ('安装后缺少文件: ' + ($missing -join ', ')) }
    Add-Step 'verify: files ok'

    $result.ok = $true
}
catch {
    $result.error = $_.Exception.Message
}
finally {
    if ($ResultFile) {
        try {
            $json = $result | ConvertTo-Json -Depth 4
            [System.IO.File]::WriteAllText($ResultFile, $json, (New-Object System.Text.UTF8Encoding($false)))
        } catch { }
    }
    if (-not $Silent) {
        if ($result.ok) {
            Write-Host ''
            Write-Host "StillKeep $version 已安装" -ForegroundColor Green
            Write-Host "  目录    : $InstallDir"
            Write-Host "  数据    : $DataDir"
            Write-Host "  自启动  : " -NoNewline
            if ($NoAutostart) { Write-Host '未启用' } else { Write-Host '已启用 (HKCU Run)' }
            Write-Host ''
            Write-Host '卸载: 设置 > 应用 > 安装的应用 > StillKeep'
        } else {
            Write-Host ''
            Write-Host "安装失败: $($result.error)" -ForegroundColor Red
            Write-Host '已复制的内容和备份都保留，没有做清理。'
            Write-Host "清理可运行: $(Join-Path $InstallDir 'uninstall.cmd')"
        }
    }
    if (-not $result.ok) { exit 1 }
}
