#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir(A_ScriptDir)

; ===========================================================================
;  StillKeepWatch  --  让 StillKeep 与 Edge 共存亡
;
;  Edge 有窗口 -> 启动 worker
;  Edge 没窗口 -> 结束 worker
;  worker 自己把 PID 写进数据目录，守护进程据此判断存活。
; ===========================================================================

global DATA_DIR := (EnvGet("LOCALAPPDATA") != "") ? EnvGet("LOCALAPPDATA") . "\StillKeep" : A_ScriptDir
global LOG_FILE := DATA_DIR . "\stillkeep.log"
global PID_FILE := DATA_DIR . "\stillkeep.pid"
global WORKER   := A_ScriptDir . "\StillKeep.ahk"

try DirCreate(DATA_DIR)

Log(text) {
    global LOG_FILE
    try {
        stamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend(stamp . "  watch: " . text . "`n", LOG_FILE, "UTF-8")
    }
}

EdgeAlive() {
    return WinExist("ahk_exe msedge.exe") ? true : false
}

WorkerPid() {
    global PID_FILE
    if (!FileExist(PID_FILE))
        return 0
    try {
        s := Trim(FileRead(PID_FILE))
        return (s = "") ? 0 : Integer(s)
    } catch
        return 0
}

Tick() {
    global WORKER, PID_FILE
    pid   := WorkerPid()
    alive := (pid && ProcessExist(pid))
    edge  := EdgeAlive()

    if (edge && !alive) {
        try {
            Run('"' . A_AhkPath . '" "' . WORKER . '"')
            Log("edge up -> spawn worker")
        } catch as e {
            Log("spawn failed: " . e.Message)
        }
    } else if (!edge && alive) {
        try
            ProcessClose(pid)
        Log("edge gone -> stop worker pid=" . pid)
        try
            FileDelete(PID_FILE)
    }
}

SetTimer(Tick, 1500)
Tick()
