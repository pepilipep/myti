import AppKit
import SwiftUI

/// Helper to host a SwiftUI view inside an NSPanel.
enum PanelHosting {
    static func setContent<V: View>(_ view: V, in panel: NSPanel) {
        let hostingView = NSHostingView(rootView: view)
        panel.contentView = hostingView
    }
}
