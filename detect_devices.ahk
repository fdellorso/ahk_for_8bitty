; https://autohotkey.com/board/topic/102735-determining-unique-id-of-input-device/

; RawInputMonitor(1, 2, "Type")	;Monitor Mouse devices raw inputs
RawInputMonitor(1, 6, "Type")	;Monitor Keyboard devices raw inputs

OnMessage(0xff, "WM_Input")
WM_Input(WParam, LParam)
{
    RawInputMonitor(WParam, LParam)
    UpdateGui()
}

gui, add, edit, w600 h300 +HScroll +HwndEditControlId,
gui, add, checkbox, checked vAutoUpdate gAutoUpdate, Auto Update (Press "Esc" to uncheck!)
gui, add, text, , Press any device key\button!!! (Keyboards, Mouses, etc ...)

gui, show

return

Esc::
GuiControl, , AutoUpdate, 0

AutoUpdate:	;__________ Auto Update _____________

GuiControlGet, AutoUpdate

if (AutoUpdate = 1)
OnMessage(0xff, "WM_Input")
else
OnMessage(0xff, "")

return

guiclose:	;_____________ gui close _______________
exitapp


UpdateGui()	;_____________ update gui ______________
{
    Global EditControlId

    Static History

    History := ""
    . RawInputMonitor("LastVk") "`r`n"
    . RawInputMonitor("LastTick") "`r`n"
    . RawInputMonitor("LastDevice") "`r`n`r`n" 
    . History

    ControlSetText, , % History, % "ahk_id" EditControlId
}

RawInputMonitor(wParam, lParam := "", Options := "")	;_____________________ Raw Input Monitor - v1.0 (Function) ___________________
{
    ;to Monitor Mouse devices, use at script execution: RawInputMonitor(1, 2, "Type")
    ;to Monitor Keyboard devices, use at script execution: RawInputMonitor(1, 6, "Type")

    Static LastDevice, LastVK, LastTick
    static RIDEV_INPUTSINK := 0x00000100, RID_INPUT := 0x10000003, RIDI_DEVICENAME  := 0x20000007

    if (wParam = "LastDevice" or wParam = "LastVK" or wParam = "LastTick")
    return, (%wParam%)

        if (Options = "Type")
        { 
            usagePage := wParam, usage := lParam

            VarSetCapacity(rawDevice, 8 + A_PtrSize)
            NumPut(usagePage, rawDevice, 0, "UShort")
            NumPut(usage, rawDevice, 2, "UShort")
            NumPut(RIDEV_INPUTSINK, rawDevice, 4, "UInt")
            NumPut(A_ScriptHWND, rawDevice, 8, "UPtr")

            ;The DllCall below monitors any Raw Inputs from specified type of Devices and send them to the script hidden Main Window through "A_ScriptHWND" built-in var!
            if !DllCall("RegisterRawInputDevices", "Ptr", &rawDevice, "UInt", 1, "UInt", 8 + A_PtrSize)
            throw "Fail"

            return
        }

    Critical

    DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", 0, "UIntP", size, "UInt", 8 + A_PtrSize * 2)
    VarSetCapacity(buffer, size)
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", &buffer, "UIntP", size, "UInt", 8 + A_PtrSize * 2)

    devHandle := NumGet(buffer, 8)
    LastVK := NumGet(buffer, 8 + 2 * A_PtrSize + 6, "UShort")

    DllCall("GetRawInputDeviceInfo", "Ptr", devHandle, "UInt", RIDI_DEVICENAME, "Ptr", 0, "UIntP",  size)
    VarSetCapacity(info, size)
    DllCall("GetRawInputDeviceInfo", "Ptr", devHandle, "UInt", RIDI_DEVICENAME, "Ptr", &info, "UIntP", size)
    LastDevice := StrGet(&info)

    LastTick := A_TickCount
}