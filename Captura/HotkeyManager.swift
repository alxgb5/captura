import Cocoa
import Carbon

class HotkeyManager {
    var onCaptureRegion: (() -> Void)?
    var onCaptureFullscreen: (() -> Void)?

    private var regionHotKeyRef: EventHotKeyRef?
    private var fullscreenHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private static var shared: HotkeyManager?

    func register() {
        HotkeyManager.shared = self

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
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
                    default: break
                    }
                }
                return noErr
            },
            1, &eventType, nil, &eventHandlerRef
        )

        // Cmd+Shift+2 → region capture
        let regionID = EventHotKeyID(signature: OSType(0x43415052), id: 1) // 'CAPR'
        let cmdShift = UInt32(cmdKey | shiftKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_2), cmdShift, regionID, GetApplicationEventTarget(), 0, &regionHotKeyRef)

        // Cmd+Shift+3 → fullscreen capture
        let fullID = EventHotKeyID(signature: OSType(0x43415046), id: 2) // 'CAPF'
        RegisterEventHotKey(UInt32(kVK_ANSI_3), cmdShift, fullID, GetApplicationEventTarget(), 0, &fullscreenHotKeyRef)
    }

    func unregister() {
        if let ref = regionHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = fullscreenHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        HotkeyManager.shared = nil
    }
}
