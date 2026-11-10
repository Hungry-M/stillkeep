# StillKeep

Edge 下载保留确认框的补丁。按当前用户安装，默认开机自启。

适用：Edge `157.0.4341.42` / Windows 10 `19045`。

> 非官方项目，与 Microsoft 无关。补丁在 Windows 输入层工作，不修改 Edge 的任何文件。
> [English](README.md) · 其他文档目前只有中文。

---

## 它修什么

下载被 SmartScreen 拦下后，从工具栏下载菜单点「保留」，会弹一个确认框。
框里 `删除 ▾` 的箭头不可见：点它执行删除，Tab 到它按 `Enter` 也执行删除，
但按 `↓` 能正常展开菜单，里面有「仍然保留」。

**同一个控件，鼠标走销毁分支，键盘 `↓` 走菜单分支。**

补丁只做一件事：把点 `▾` 还原成它本来该有的行为——弹菜单，由你自己选。
它不替你按回车，不改二进制，不关 SmartScreen。

---

## 下载

从 [Releases](https://github.com/Hungry-M/stillkeep/releases) 取其中一个：

| 资产 | 用途 |
| --- | --- |
| `StillKeep-0.1.1-Setup.exe` | 安装器（推荐）。装进 `%LOCALAPPDATA%\Programs\StillKeep`，带卸载项、开始菜单、开机自启 |
| `StillKeep-0.1.1-portable.zip` | 解压即用，不写注册表、不装服务。解压后跑 `run.cmd` |

校验后再用：

```powershell
Get-FileHash .\StillKeep-0.1.1-Setup.exe -Algorithm SHA256
```

把结果和 `SHA256SUMS.txt` 里的值比对，一致再运行。

---

## 安装

双击 `StillKeep-0.1.1-Setup.exe`。按当前用户安装，不需要管理员权限。

- 安装目录：`%LOCALAPPDATA%\Programs\StillKeep`
- 数据目录：`%LOCALAPPDATA%\StillKeep`（日志）
- 同时写入：开始菜单快捷方式、`HKCU` 卸载项
- **开机自启默认勾选**（`HKCU\...\Run`）；想关就取消勾选，或者用 `/TASKS=""` 静默安装

安装向导会先让你选语言（English / 简体中文）。

静默安装：

```powershell
StillKeep-0.1.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
StillKeep-0.1.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS=""   # 不自启
```

> 不要从受限终端或沙箱里启动安装器。子进程会继承受限令牌，创建 `%APPDATA%`
> 和 `HKCU` 时被拒（`Error 5`），安装会回滚。请从资源管理器双击。

### 免安装

解压 `portable.zip`，双击 `run.cmd`。它只启动守护进程，不写注册表、不建快捷方式。

### 从源码安装（不用安装器）

仓库源码里带 `install.cmd` / `uninstall.cmd`，参数：

```powershell
install.cmd -NoAutostart
install.cmd -Silent -ResultFile r.json
install.cmd -InstallDir D:\Apps\StillKeep
```

---

## 卸载

**安装器装的**：设置 → 应用 → 安装的应用 → StillKeep，或开始菜单里的「卸载 StillKeep」。

Inno 卸载器会先调用 `uninstall-cleanup.ps1`：只结束路径在本程序目录下的
`AutoHotkey64.exe`，并清掉 `Run` 值；然后再删文件、快捷方式和卸载项。

**脚本装的**：安装目录里的 `uninstall.cmd`，或 `uninstall.cmd -Yes`（静默）。

脚本版有个实现细节：注册表里的 `UninstallString` **直接调 powershell 跑
`uninstall.ps1`**，不经过 `.cmd`。因为批处理删掉自己所在的目录后，cmd 读不到后续行，
会报 `The system cannot find the path specified.` 并返回 1（删是删掉了，但退出码是错的）。
`uninstall.cmd` 只做一件事：把 PowerShell 分离出去，然后立刻退出。

- 只删除能证明属于本程序的东西：安装位置、目录里的 `StillKeepWatch.ahk` 标记、
  快捷方式 target。任一不匹配就跳过，不猜。
- 日志目录 `%LOCALAPPDATA%\StillKeep` 默认保留；脚本版卸载的备份也默认保留，
  `-RemoveBackups` 才一并删除。

---

## 自启动

默认写入：

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
  StillKeep = "<install>\AutoHotkey64.exe" "<install>\StillKeepWatch.ahk"
```

启动的是**守护进程**，它负责让 worker 与 Edge 共存亡：

```text
守护进程常驻
  ├─ Edge 有窗口 → 启动 worker（真正干活的补丁）
  └─ Edge 没窗口 → 结束 worker
```

---

## 快捷键

| 键 | 作用 |
|---|---|
| `Ctrl+Alt+K` | 叫出「仍然保留」菜单 |
| `Ctrl+Alt+G` | 开 / 关点按拦截 |
| `Ctrl+Alt+F12` | 探针，把 Edge 窗口信息写进日志 |

---

## 目录布局

```text
StillKeep/
├─ install.cmd          安装入口（纯 ASCII）
├─ install.ps1          安装逻辑（UTF-8 BOM）
├─ uninstall.cmd        卸载入口
├─ uninstall.ps1        卸载逻辑
├─ run.cmd              免安装试跑
├─ VERSION
├─ LICENSE
├─ README.md            英文说明
├─ README.zh.md         本文件
├─ CHANGELOG.md
├─ CONTRIBUTING.md
├─ SECURITY.md
├─ THIRD_PARTY_NOTICES.md
├─ packaging/
│  ├─ stillkeep.iss          Inno Setup 脚本
│  ├─ build.ps1              构建 Setup.exe + portable.zip
│  ├─ uninstall-cleanup.ps1  卸载前停进程
│  └─ languages/             安装器界面语言文件
└─ src/
   ├─ StillKeep.ahk    worker：窗口判定 + 点按还原
   ├─ StillKeepWatch.ahk    守护：随 Edge 启停 worker
   ├─ AutoHotkey64.exe     AutoHotkey v2.0.31
   └─ LICENSE-AutoHotkey.txt
```

`.cmd` 必须是纯 ASCII + CRLF（cmd.exe 按 OEM 代码页读，中文注释会被当成命令）；
`.ps1` 含中文时必须是 UTF-8 带 BOM（PowerShell 5.1 无 BOM 会按 ANSI 解析）。

---

## 排错

日志：`%LOCALAPPDATA%\StillKeep\stillkeep.log`

| 行 | 含义 |
|---|---|
| `watch: edge up -> spawn worker` | 守护进程发现 Edge，拉起 worker |
| `watch: edge gone -> stop worker` | Edge 关闭，worker 已退出 |
| `open-menu: menu hwnd=...` | 菜单成功展开 |
| `open-menu: menu not found` | 没识别到菜单窗口，需调 `FindMenuWindow` 阈值 |
| `open-menu: no dialog` | 没识别出确认框，需调 `IsKeepDialog` 判定 |

框出现时按 `Ctrl+Alt+F12`，日志会列出所有 Edge 窗口的
`popup / owned / rect / title`，据此调判定条件。

---

## 验证状态

**已验证**（本机实测或沙箱内流程测试）：

- 故障形态，以及 `↓` 能展开菜单（「删除」和不可见控件上都成立）
- 守护进程随 Edge 拉起/停止 worker，PID 文件写入
- 脚本版安装/卸载在隔离目录下跑通
- `.cmd` / `.ps1` 的编码与换行符合上面两条规范
- Inno 脚本编译通过，文件复制阶段完成

**未验证**（环境不允许，需在普通桌面确认）：

- Setup.exe 的完整安装（注册表 + 开始菜单快捷方式）：这里的子进程写 `%APPDATA%`
  和 `HKCU` 被拒（`Error 5`），Inno 会回滚
- 从「设置 → 应用」发起卸载的完整链路

---

## 上报

这个 bug 值得报给微软，`edge://feedback`：

> 下载被 SmartScreen 拦截后，工具栏下载菜单里点「保留」弹出确认框。
> 确认框的 `删除` 右侧下拉箭头不可见；点击该区域执行删除，Tab 焦点链中
> 该控件存在但无视觉呈现，在其上按 Enter 同样删除；而按 ↓ 能正常打开
> 下拉菜单（内有「仍然保留」）。同一控件、鼠标走销毁分支、键盘走菜单分支。
> 相同保留操作在 edge://downloads 页面内正常。

---

## 已知限制

- 尺寸判定是启发式的。Edge 若新增同尺寸的弹层，可能误判；误判的后果是拦截不生效
  或误发 `Esc`，**不会删文件**。
- Edge 更新后窗口结构可能变，补丁可能失效。失效时它不动作，不会把浏览器搞坏。
- 只在 Edge `157.0.4341.42` / Windows 10 `19045` 上验证过，其他版本未测。
- 安装包没有代码签名，Windows 可能提示「未知发布者」。这是预期行为，不是安装失败。
- 其他 Chromium 浏览器未测试，理论上同样的问题可以用同一思路处理。

## 许可

[MIT](LICENSE)，允许商业使用与修改；再分发需保留版权与许可声明。

捆绑的 AutoHotkey 解释器是 GPL-2.0，见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。提交需带 DCO 签署（`git commit -s`）。
