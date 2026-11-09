# StillKeep

Edge 下载保留确认框的补丁。按当前用户安装，默认开机自启。

适用：Edge `157.0.4341.42` / Windows 10 `19045`。

---

## 它修什么

下载被 SmartScreen 拦下后，从工具栏下载菜单点「保留」，会弹一个确认框。
框里 `删除 ▾` 的箭头不可见：点它执行删除，Tab 到它按 `Enter` 也执行删除，
但按 `↓` 能正常展开菜单，里面有「仍然保留」。

**同一个控件，鼠标走销毁分支，键盘 `↓` 走菜单分支。**

补丁只做一件事：把点 `▾` 还原成它本来该有的行为——弹菜单，由你自己选。
它不替你按回车，不改二进制，不关 SmartScreen。

---

## 安装

双击 `install.cmd`。不需要管理员权限。

- 安装目录：`%LOCALAPPDATA%\Programs\StillKeep`
- 数据目录：`%LOCALAPPDATA%\StillKeep`（日志、备份）
- 同时写入：开始菜单快捷方式、`HKCU` 卸载项、开机自启（`HKCU\...\Run`）
- 安装完成后立即启动守护进程

参数：

```powershell
install.cmd -NoAutostart          # 不写自启动
install.cmd -Silent -ResultFile r.json
install.cmd -InstallDir D:\Apps\StillKeep
```

> 不要在受限终端/沙箱里运行安装器。请从资源管理器双击，
> 否则可能继承受限令牌，写 `%LOCALAPPDATA%` 被拒。

---

## 卸载

三种入口，效果一样：

1. 设置 → 应用 → 安装的应用 → StillKeep
2. 安装目录里的 `uninstall.cmd`
3. `uninstall.cmd -Yes`（静默）

卸载顺序：停进程 → 删自启动 → 删卸载项 → 删快捷方式 → 删程序目录 → 清数据目录。

一个实现细节：注册表里的 `UninstallString` **直接调 powershell 跑 `uninstall.ps1`**，
不经过 `.cmd`。因为批处理删掉自己所在的目录后，cmd 读不到后续行，会报
`The system cannot find the path specified.` 并返回 1（删是删掉了，但退出码是错的）。
`uninstall.cmd` 保留给双击用，它只做一件事：把 PowerShell 分离出去，然后立刻退出。

- 只删除能证明属于本程序的东西：卸载项里的 `InstallLocation`、目录里的
  `StillKeepWatch.ahk` 标记、快捷方式 target。任一不匹配就跳过，不猜。
- 备份默认保留在 `%LOCALAPPDATA%\StillKeep\backups`；
  `uninstall.cmd -Yes -RemoveBackups` 才一并删除。

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
├─ README.md
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
- 安装/卸载脚本在隔离目录下跑通，文件复制、目录删除、结果 JSON 正常
- 守护进程随 Edge 拉起/停止 worker，PID 文件写入
- `install.cmd` / `uninstall.cmd` 编码与换行符合上面两条规范

**未验证**（沙箱不允许，需在你机器上确认）：

- 注册表写入（`HKCU` 卸载项、`Run`）——沙箱里被拒绝（`Access to the registry key ... is denied`），代码路径未实跑
- 开始菜单快捷方式：`WScript.Shell` 的创建/读回已单独验证通过，但写进 `%APPDATA%` 的整链未跑
- 从「设置 → 应用」发起卸载的完整链路

---

## 上报

这个 bug 值得报给微软，`edge://feedback`：

> 下载被 SmartScreen 拦截后，工具栏下载菜单里点「保留」弹出确认框。
> 确认框的 `删除` 右侧下拉箭头不可见；点击该区域执行删除，Tab 焦点链中
> 该控件存在但无视觉呈现，在其上按 Enter 同样删除；而按 ↓ 能正常打开
> 下拉菜单（内有「仍然保留」）。同一控件、鼠标走销毁分支、键盘走菜单分支。
> 相同保留操作在 edge://downloads 页面内正常。
