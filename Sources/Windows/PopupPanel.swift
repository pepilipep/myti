import AppKit

/// NSPanel subclass for the popup prompt.
/// Uses .nonactivatingPanel so it appears without stealing focus from other apps.
/// Keyboard input is handled via NSEvent local monitor (not SwiftUI .onKeyPress)
/// since nonactivating panels don't receive standard key events.
final class PopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Frameless look
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true

        // Popup behavior
        level = .popUpMenu
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }
}
