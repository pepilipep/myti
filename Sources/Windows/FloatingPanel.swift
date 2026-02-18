import AppKit

/// NSPanel for reports/settings windows in a tray-only (accessory) app.
/// Uses .floating level so the window appears above other apps without
/// needing to activate/deactivate the application policy.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentRect: NSRect, title: String) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = title
        isReleasedWhenClosed = false
        level = .floating
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func showAndFocus() {
        makeKeyAndOrderFront(nil)
    }
}
