# Contributing

## 开发环境

- Windows 10 / 11
- AutoHotkey v2 —— 仓库内已带 `src/AutoHotkey64.exe`，不需要另外安装
- PowerShell 5.1（Windows 自带）

## 本地验证

改动后至少跑一遍冒烟：

```powershell
# 1. 语法与自检，会写一行日志
src\AutoHotkey64.exe src\StillKeep.ahk --selftest

# 2. 安装/卸载冒烟：装到临时目录，不碰注册表和快捷方式
install.cmd -InstallDir .\_tmp\app -DataDir .\_tmp\data -NoRegistry -NoShortcut -NoAutostart -SkipStart
_tmp\app\uninstall.cmd -Yes -RemoveBackups
```

第二步结束时 `_tmp\app` 应当被删掉，退出码 0。

## 编码规则（硬性）

| 文件 | 要求 |
| --- | --- |
| `.cmd` / `.bat` | 纯 ASCII，CRLF 换行 |
| `.ps1` 含非 ASCII | UTF-8 **带 BOM** |
| 其他文本 | UTF-8 |

`.cmd` 里写中文会被 cmd.exe 按 OEM 代码页解析，直接把脚本拆碎；
`.ps1` 缺 BOM 时 PowerShell 5.1 按 ANSI 解析，中文注释会吃掉引号。

仓库用 `.gitattributes` 强制 `.cmd` 检出为 CRLF，不要删掉那几行。

## 提交约定

- 一个 commit 只做一类变更；提交信息写清“为什么”。
- 每个 commit 必须带 DCO 签署：

  ```text
  Signed-off-by: Your Name <you@example.com>
  ```

  用 `git commit -s` 自动添加。没有 `Signed-off-by` 的 PR 不会被合并。

## 再许可授权

By submitting a contribution, you grant the maintainer a perpetual,
worldwide, non-exclusive, royalty-free, irrevocable license to reproduce,
modify, distribute, and relicense your contribution, alone or as part of this
project, under any OSI-approved license, including future versions of this
project's license. You retain copyright in your contribution.

中文要点：非独占、全球、免版税、不可撤销、允许随项目整体重新许可；
你保留著作权，这不是版权转让。

这条款比 DCO 强、比签署式 CLA 弱，目的只是给未来换许可证留出空间。
