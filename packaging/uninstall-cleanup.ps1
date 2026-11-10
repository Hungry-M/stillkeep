# StillKeep 卸载前清理
# 由 Inno 的 [UninstallRun] 在删除文件之前调用。
# 只处理路径在本程序目录下的 AutoHotkey64 进程，不按进程名一刀切。

$ErrorActionPreference = 'SilentlyContinue'
$app = $PSScriptRoot

Get-Process -Name AutoHotkey64 -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $path = $_.Path
        if ($path -and $path.StartsWith($app, [StringComparison]::OrdinalIgnoreCase)) {
            Stop-Process -Id $_.Id -Force
        }
    } catch {
    }
}

# 兜底：即便安装时没勾自启动，也清掉可能存在的同名 Run 值
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'StillKeep' -ErrorAction SilentlyContinue

exit 0
