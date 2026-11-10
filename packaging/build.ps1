# 构建 StillKeep 发布产物
#   dist\StillKeep-<ver>-Setup.exe      Inno Setup 安装器
#   dist\StillKeep-<ver>-portable.zip   解压即用（run.cmd）
#   dist\SHA256SUMS.txt                 两个产物的校验值

[CmdletBinding()]
param(
    [string]$Iscc,
    [switch]$SkipPortable
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$dist = Join-Path $root 'dist'

if (-not $version -match '^\d+\.\d+\.\d+$') {
    throw "VERSION 不是 x.y.z：$version"
}

if (-not $Iscc) {
    foreach ($c in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe')
    )) {
        if (Test-Path -LiteralPath $c) { $Iscc = $c; break }
    }
}
if (-not $Iscc -or -not (Test-Path -LiteralPath $Iscc)) {
    throw '找不到 ISCC.exe，请安装 Inno Setup 6，或用 -Iscc 指定路径'
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
Remove-Item (Join-Path $dist '*.exe'), (Join-Path $dist '*.zip'), (Join-Path $dist 'SHA256SUMS.txt') -Force -ErrorAction SilentlyContinue

Write-Host "version : $version"
Write-Host "iscc    : $Iscc"

# --- Setup.exe ---
Write-Host 'building Setup.exe ...'
& $Iscc "/DVersion=$version" (Join-Path $PSScriptRoot 'stillkeep.iss') | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { throw "ISCC 失败，退出码 $LASTEXITCODE" }

$setup = Join-Path $dist "StillKeep-$version-Setup.exe"
if (-not (Test-Path -LiteralPath $setup)) { throw "没有生成 $setup" }

# --- portable.zip ---
$portable = $null
if (-not $SkipPortable) {
    Write-Host 'building portable.zip ...'
    $stage = Join-Path $dist ("_portable\" + "StillKeep-$version")
    Remove-Item (Join-Path $dist '_portable') -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $stage | Out-Null

    Copy-Item (Join-Path $root 'src') -Destination $stage -Recurse -Force
    foreach ($f in 'run.cmd', 'VERSION', 'LICENSE', 'README.md', 'README.zh.md', 'CHANGELOG.md', 'THIRD_PARTY_NOTICES.md') {
        Copy-Item (Join-Path $root $f) -Destination $stage -Force
    }

    $portable = Join-Path $dist "StillKeep-$version-portable.zip"
    Compress-Archive -Path $stage -DestinationPath $portable -CompressionLevel Optimal -Force
    Remove-Item (Join-Path $dist '_portable') -Recurse -Force -ErrorAction SilentlyContinue
}

# --- checksums ---
$lines = @()
foreach ($f in @($setup, $portable)) {
    if ($f -and (Test-Path -LiteralPath $f)) {
        $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower()
        $lines += "$h  $(Split-Path -Leaf $f)"
    }
}
$sums = Join-Path $dist 'SHA256SUMS.txt'
[System.IO.File]::WriteAllText($sums, (($lines -join "`r`n") + "`r`n"), [System.Text.Encoding]::ASCII)

Write-Host ''
Write-Host 'artifacts:' -ForegroundColor Green
Get-ChildItem $dist -File | ForEach-Object {
    Write-Host ("  {0,-34} {1,10:N0} bytes" -f $_.Name, $_.Length)
}
Write-Host ''
Get-Content $sums | ForEach-Object { Write-Host "  $_" }
