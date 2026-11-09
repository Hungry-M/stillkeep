#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir(A_ScriptDir)

; ===========================================================================
;  StillKeep  --  Edge 下载保留确认框补丁（worker）
;
;  实测特性：那个「删除 ▾」的箭头不可见，但焦点在「删除」或那块不可见区域上
;  按 ↓ 都能展开菜单，里面有「仍然保留」。
;
;  补丁只做一件事：把「点 ▾」还原成它本该有的行为——弹出菜单，由你自己选。
;  绝不代替你按 Enter，也不吞掉删除以外的东西。
;
;  由 StillKeepWatch.ahk 随 Edge 启停，不要单独常驻。
; ===========================================================================

global DATA_DIR      := (EnvGet("LOCALAPPDATA") != "") ? EnvGet("LOCALAPPDATA") . "\StillKeep" : A_ScriptDir
global LOG_PATH      := DATA_DIR . "\stillkeep.log"
global PID_PATH      := DATA_DIR . "\stillkeep.pid"
try DirCreate(DATA_DIR)
global GUARD_ON      := true
global GUARD_KEYS    := true
global SELFTEST      := false
global DANGER_H      := 96
global DANGER_XR     := 0.72   ; 底部按钮区右 28%（原「删除 ▾」）

for arg in A_Args {
    if (arg = "--selftest")
        SELFTEST := true
    else if (arg = "--no-keys")
        GUARD_KEYS := false
}

Log(text) {
    global LOG_PATH
    try {
        stamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend(stamp . "  " . text . "`n", LOG_PATH, "UTF-8")
    }
}

; ---------------------------------------------------------------------------
; 窗口判断
; ---------------------------------------------------------------------------
IsEdgeWindow(hwnd) {
    if (!hwnd)
        return false
    try {
        pid := WinGetPID("ahk_id " . hwnd)
        return (pid && ProcessGetName(pid) = "msedge.exe")
    } catch
        return false
}

IsPopup(hwnd) {
    try {
        return ((WinGetStyle("ahk_id " . hwnd) & 0x80000000) != 0)
    } catch
        return false
}

IsOwned(hwnd) {
    try {
        return (DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr") != 0)
    } catch
        return false
}

; 确认框判定：Edge 进程 + Chromium 窗口类 + 非主窗口（有 owner 或 popup）+ 合理尺寸。
; 不再依赖标题，也不再依赖 WS_POPUP 一种形态。
IsKeepDialog(hwnd := 0) {
    if (!hwnd)
        hwnd := WinActive("A")
    if (!hwnd || !IsEdgeWindow(hwnd))
        return false
    try {
        if (WinGetClass("ahk_id " . hwnd) != "Chrome_WidgetWin_1")
            return false
        if (!IsOwned(hwnd) && !IsPopup(hwnd))
            return false
        WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
        return (w >= 420 && w <= 950 && h >= 380 && h <= 1050)
    } catch
        return false
}

InDeleteZone(hwnd := 0) {
    if (!hwnd)
        hwnd := WinActive("A")
    if (!IsKeepDialog(hwnd))
        return false
    try {
        WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
        MouseGetPos(&mx, &my)
        return (my >= y + h - DANGER_H) && (mx >= x + w * DANGER_XR)
    } catch
        return false
}

; 菜单：对话框之外、离它不远的小 popup
FindMenuWindow(dlg) {
    try
        WinGetPos(&dx, &dy, &dw, &dh, "ahk_id " . dlg)
    catch
        return 0
    for hwnd in WinGetList("ahk_exe msedge.exe") {
        if (hwnd = dlg)
            continue
        try {
            if (!IsPopup(hwnd) && !IsOwned(hwnd))
                continue
            WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
            if (w <= 0 || w > 460 || h <= 0 || h > 300)
                continue
            if (x < dx - 260 || x > dx + dw + 120)
                continue
            if (y < dy - 320 || y > dy + dh + 120)
                continue
            return hwnd
        }
    }
    return 0
}

; ---------------------------------------------------------------------------
; 还原「点 ▾ 弹菜单」
; ---------------------------------------------------------------------------
OpenMenu() {
    dlg := WinActive("A")
    if (!IsKeepDialog(dlg)) {
        Log("open-menu: no dialog. fg=[" . WinGetTitle("A") . "] class=[" . WinGetClass("A") . "]")
        TrayTip("没有检测到确认框。", "StillKeep", 2)
        return
    }
    menu := 0
    loop 3 {
        Send("{Down}")          ; 焦点在按钮上时，这一步就展开菜单
        Sleep(220)
        menu := FindMenuWindow(dlg)
        if (menu)
            break
        Send("{Tab}")           ; 否则换一个控件再试
        Sleep(150)
    }
    if (menu) {
        Log("open-menu: menu hwnd=" . menu)
        TrayTip("菜单已打开，选「仍然保留」。", "StillKeep", 1)
    } else {
        Log("open-menu: menu not found")
        TrayTip("没找到菜单。手动 Tab 到第三个控件再按 ↓。", "StillKeep", 2)
    }
}

; 兜底：回车 / 空格 不落到「删除」上
CancelDialog() {
    Log("intercept: enter/space -> Esc")
    Send("{Esc}")
}

DumpEdgeWindows(prefix) {
    n := 0
    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try {
            cls   := WinGetClass("ahk_id " . hwnd)
            title := WinGetTitle("ahk_id " . hwnd)
            WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
            Log(Format("{1}: hwnd={2} popup={3} owned={4} class={5} rect={6},{7} {8}x{9} title=[{10}]",
                prefix, hwnd, IsPopup(hwnd) ? 1 : 0, IsOwned(hwnd) ? 1 : 0,
                cls, x, y, w, h, title))
            n += 1
        } catch {
        }
    }
    return n
}

if (SELFTEST) {
    Log("selftest: begin  ahk=" . A_AhkVersion)
    Log("selftest: IsKeepDialog(0)=" . IsKeepDialog(0))
    n := DumpEdgeWindows("selftest")
    Log("selftest: msedge windows=" . n)
    ExitApp(0)
}

; ---------------------------------------------------------------------------
; 热键
; ---------------------------------------------------------------------------

; 点「删除 ▾」区域 -> 只弹菜单，绝不代替你确认
#HotIf GUARD_ON && IsKeepDialog() && InDeleteZone()
*LButton:: OpenMenu()
#HotIf

; 回车 / 空格 不落到删除上
#HotIf GUARD_ON && GUARD_KEYS && IsKeepDialog()
*Enter:: CancelDialog()
*NumpadEnter:: CancelDialog()
*Space:: CancelDialog()
#HotIf

^!k:: OpenMenu()

^!g:: {
    global GUARD_ON
    GUARD_ON := !GUARD_ON
    TrayTip(GUARD_ON ? "拦截已开启" : "拦截已关闭", "StillKeep", 1)
}

^!F12:: {
    Log("probe: fg=[" . WinGetTitle("A") . "] class=[" . WinGetClass("A") . "]")
    n := DumpEdgeWindows("probe")
    Log("probe: msedge windows=" . n)
    TrayTip("已写入 " . LOG_PATH, "StillKeep", 1)
}

Log("worker start: ahk=" . A_AhkVersion)

; 给守护进程留 PID
try {
    DirCreate(DATA_DIR)
    if (FileExist(PID_PATH))
        FileDelete(PID_PATH)
    FileAppend(String(DllCall("GetCurrentProcessId", "UInt")), PID_PATH)
} catch as e {
    Log("pid write failed: " . e.Message)
}

CleanupPid(*) {
    global PID_PATH
    try FileDelete(PID_PATH)
    return 0
}
OnExit(CleanupPid)
