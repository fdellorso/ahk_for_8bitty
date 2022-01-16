; https://autohotkey.com/board/topic/102735-determining-unique-id-of-input-device/

; RawInputMonitor(1, 2, "Type")	;Monitor Mouse devices raw inputs
RawInputMonitor(1, 6, "Type")	;Monitor Keyboard devices raw inputs

OnMessage(0xff, "WM_Input")
WM_Input(WParam, LParam)
{
    RawInputMonitor(WParam, LParam)
}

UsbMouse := "\\?\HID#VID_7838&PID_1320&MI_02#8&&0&0000#{884b96c3-56ef-11d1-bc8c-00a0405dd}"
UsbKeyboard := "\\?\HID#VID_062A&PID_0107&MI_00#8&28882&0&0#{884b96c3-56ef-11d1-a0c998705dd}"
LapTopKeyboard := "\\?\ACPI#PNP0893#4&17dfc6af&0#{8876544b96c3-56ef-11d1-bc8c-00a0c91405dd}"


b::

sleep, 200

if (RawInputMonitor("LastDevice") = UsbMouse)
send x

if (RawInputMonitor("LastDevice") = UsbKeyboard)
send y

if (RawInputMonitor("LastDevice") = LapTopKeyboard)
send z

return


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