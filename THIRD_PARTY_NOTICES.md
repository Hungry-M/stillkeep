# Third-Party Notices

StillKeep itself is MIT-licensed (see [LICENSE](LICENSE)).
It bundles one third-party component.

## AutoHotkey v2.0.31

| | |
| --- | --- |
| 组件 | AutoHotkey（解释器） |
| 文件 | `src/AutoHotkey64.exe` |
| 许可证 | GNU General Public License v2.0 |
| 完整文本 | [`src/LICENSE-AutoHotkey.txt`](src/LICENSE-AutoHotkey.txt) |
| 上游 | <https://www.autohotkey.com/> |
| 对应源码 | <https://www.autohotkey.com/download/ahk-v2.zip> |

分发的二进制未做修改。因为它以 GPL-2.0 授权，对应源码可从上面的上游地址获取；
完整许可证文本已随仓库提供。

## Inno Setup（仅构建期，产物内含其语言文本）

| | |
| --- | --- |
| 组件 | Inno Setup 简体中文语言文件 |
| 文件 | `packaging/languages/ChineseSimplified.isl` |
| 许可证 | 随 Inno Setup 分发，遵循 Inno Setup License |
| 上游 | <https://github.com/jrsoftware/issrc> |

只用于生成 `Setup.exe` 的安装界面文本，不参与运行时。

## 构建与运行依赖

无额外运行时依赖。安装器由 Inno Setup 6 生成；脚本版安装/卸载使用 Windows 自带的
PowerShell 5.1 和 cmd.exe。
