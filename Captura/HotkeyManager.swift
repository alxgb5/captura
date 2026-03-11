import Cocoa
import Carbon

class HotkeyManager {
    var onCaptureRegion: (() -> Void)?
    var onCaptureFullscreen: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    var onToggleRecording: (() -> Void)?

    private var regionHotKeyRef: EventHotKeyRef?
    private var fullscreenHotKeyRef: EventHotKeyRef?
    private var windowHotKeyRef: EventHotKeyRef?
    private var recordingHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private static var shared: HotkeyManager?

    func register() {
        HotkeyManager.shared = self

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                DispatchQueue.main.async {
                    switch hotkeyID.id {
                    case 1: HotkeyManager.shared?.onCaptureRegion?()
                    case 2: HotkeyManager.shared?.onCaptureFullscreen?()
                    case 3: HotkeyManager.shared?.onCaptureWindow?()
                    case 4: HotkeyManager.shared?.onToggleRecording?()
                    default: break
                    }
                }
                return noErr
            },
            1, &eventType, nil, &eventHandlerRef
        )

        let cmdShift = UInt32(cmdKey | shiftKey)

        // Cmd+Shift+2 → region
        let regionID = EventHotKeyID(signature: OSType(0x43415052), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_2), cmdShift, regionID, GetApplicationEventTarget(), 0, &regionHotKeyRef)

        // Cmd+Shift+3 → fullscreen
        let fullID = EventHotKeyID(signature: OSType(0x43415046), id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_3), cmdShift, fullID, GetApplicationEventTarget(), 0, &fullscreenHotKeyRef)

        // Cmd+Shift+4 → window capture
        let winID = EventHotKeyID(signature: OSType(0x43415057), id: 3)
        RegisterEventHotKey(UInt32(kVK_ANSI_4), cmdShift, winID, GetApplicationEventTarget(), 0, &windowHotKeyRef)

        // Cmd+Shift+5 → recording toggle
        let recID = EventHotKeyID(signature: OSType(0x43415255), id: 4)
        RegisterEventHotKey(UInt32(kVK_ANSI_5), cmdShift, recID, GetApplicationEventTarget(), 0, &recordingHotKeyRef)
    }

    func unregister() {
        if let ref = regionHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = fullscreenHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = windowHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = recordingHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        HotkeyManager.shared = nil
    }
}
