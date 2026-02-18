import AppKit

// Manual NSApplication entry point — required for tray-only apps.
// SwiftUI's App lifecycle terminates when no scenes are visible.
@main
enum MytiApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // No dock icon (equivalent to LSUIElement=YES)

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run()
    }
}
