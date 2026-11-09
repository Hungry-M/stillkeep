<#
    StillKeep 卸载器
    只删除能证明属于本程序的内容：卸载项里的 InstallLocation、目录里的文件标记、快捷方式 target。

    用法:
        uninstall.cmd            交互确认
        uninstall.cmd -Yes       静默
        uninstall.cmd -Yes -RemoveBackups
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [string]$DataDir = (Join-Path $env:LOCALAPPDATA 'StillKeep'),
    [switch]$Yes,
    [switch]$RemoveBackups,
    [switch]$Silent,
    [string]$ResultFile
)

$ErrorActionPreference = 'Continue'
$AppName  = 'StillKeep'
$UninstKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"

$result = [ordered]@{
    ok      = $false
    app     = $AppName
    steps   = New-Object System.Collections.ArrayList
    error   = ''
}

function Add-Step([string]$s) { [void]$script:result.steps.Add($s) }

try {
    if (-not $InstallDir) {
        $reg = Get-ItemProperty -Path $UninstKey -ErrorAction SilentlyContinue
        if ($reg -and $reg.InstallLocation) { $InstallDir = $reg.InstallLocation }
    }
    if (-not $InstallDir) { $InstallDir = $PSScriptRoot }
    $InstallDir = $InstallDir.TrimEnd('\')
    $result.install_dir = $InstallDir

    $marker = Join-Path $InstallDir 'StillKeepWatch.ahk'
    $owned  = Test-Path -LiteralPath $marker
    if (-not $owned) {
        Add-Step "marker: 缺失，跳过目录删除 ($InstallDir)"
    }

    if (-not $Yes -and -not $Silent) {
        Write-Host "将卸载 StillKeep，并删除:" -ForegroundColor Yellow
        Write-Host "  程序目录: $InstallDir"
        Write-Host "  数据目录: $DataDir (备份默认保留)"
        $ans = Read-Host '继续? [y/N]'
        if ($ans -notmatch '^[Yy]') {
            $result.error = '用户取消'
            Add-Step 'aborted: user'
            if ($ResultFile) { $result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ResultFile -Encoding UTF8 }
            exit 2
        }
    }

    Get-Process -Name AutoHotkey64 -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $p = $_.Path
            if ($p -and $p.StartsWith($InstallDir, [StringComparison]::OrdinalIgnoreCase)) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    Start-Sleep -Milliseconds 400
    Add-Step 'stop: processes'

    try {
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $AppName -ErrorAction SilentlyContinue
        Add-Step 'autostart: removed'
    } catch { Add-Step "autostart: $($_.Exception.Message)" }

    $reg = Get-ItemProperty -Path $UninstKey -ErrorAction SilentlyContinue
    if ($reg) {
        if ($reg.InstallLocation -and ($reg.InstallLocation.TrimEnd('\') -ieq $InstallDir)) {
            Remove-Item -Path $UninstKey -Recurse -Force -ErrorAction SilentlyContinue
            Add-Step 'registry: removed'
        } else {
            Add-Step "registry: InstallLocation 不匹配，保留 ($($reg.InstallLocation))"
        }
    }

    $lnkPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\StillKeep.lnk'
    if (Test-Path -LiteralPath $lnkPath) {
        try {
            $ws  = New-Object -ComObject WScript.Shell
            $lnk = $ws.CreateShortcut($lnkPath)
            if ($lnk.TargetPath -and $lnk.TargetPath.StartsWith($InstallDir, [StringComparison]::OrdinalIgnoreCase)) {
                Remove-Item -LiteralPath $lnkPath -Force
                Add-Step 'shortcut: removed'
            } else {
                Add-Step "shortcut: target 不匹配，保留 ($($lnk.TargetPath))"
            }
        } catch { Add-Step "shortcut: $($_.Exception.Message)" }
    }

    if ($owned -and (Test-Path -LiteralPath $InstallDir)) {
        Set-Location $env:TEMP
        $removed = $false
        for ($i = 0; $i -lt 3 -and -not $removed; $i++) {
            try {
                Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction Stop
                $removed = $true
            } catch {
                Start-Sleep -Milliseconds 500
            }
        }
        if ($removed) { Add-Step "dir: removed $InstallDir" }
        else { Add-Step "dir: 删除失败，仍被占用 ($InstallDir)"; throw "无法删除安装目录: $InstallDir" }
    }

    if (Test-Path -LiteralPath $DataDir) {
        Get-ChildItem -LiteralPath $DataDir -File -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        if ($RemoveBackups) {
            Get-ChildItem -LiteralPath $DataDir -Directory -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $DataDir -Recurse -Force -ErrorAction SilentlyContinue
            Add-Step 'data: removed (含备份)'
        } else {
            Add-Step 'data: 日志已清，备份保留'
        }
    }

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
            Write-Host 'StillKeep 已卸载。' -ForegroundColor Green
            if (-not $RemoveBackups) { Write-Host "备份保留在: $DataDir\backups" }
        } else {
            Write-Host ''
            Write-Host "卸载未完成: $($result.error)" -ForegroundColor Red
        }
    }
    if (-not $result.ok) { exit 1 }
}
