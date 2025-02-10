import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerHotkey()
    }

    func registerHotkey() {
        var hotKeyRef: EventHotKeyRef?
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 9
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            let scriptPath = NSString(string: "~/.clipboard-history/picker.sh").expandingTildeInPath
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = [scriptPath]
            task.terminationHandler = { _ in
                let flagFile = NSString(string: "~/.clipboard-history/.do_paste").expandingTildeInPath
                if FileManager.default.fileExists(atPath: flagFile) {
                    try? FileManager.default.removeItem(atPath: flagFile)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AppDelegate.simulatePaste()
                    }
                }
            }
            task.launch()
            return noErr
        }, 1, &eventType, nil, nil)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) else { return }
        keyDown.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
        keyUp.flags = .maskCommand
        keyUp.post(tap: .cghidEventTap)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
