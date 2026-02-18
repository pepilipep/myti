import SwiftUI

struct PopupView: View {
    let categories: [Category]
    let promptedAt: String
    let onSubmit: (Int64, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("What were you doing?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textMuted)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Category buttons
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryButtonView(
                            category: category,
                            index: index,
                            action: {
                                guard let id = category.id else { return }
                                onSubmit(id, promptedAt)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 12)
        }
        .onAppear {
            KeyMonitor.shared.start(categoryCount: categories.count) { num in
                let cat = categories[num - 1]
                if let id = cat.id {
                    onSubmit(id, promptedAt)
                }
            }
        }
        .onDisappear {
            KeyMonitor.shared.stop()
        }
    }
}

/// Captures number key presses via NSEvent local monitor.
/// Works with .nonactivatingPanel where SwiftUI .onKeyPress does not.
final class KeyMonitor {
    static let shared = KeyMonitor()
    private var monitor: Any?

    func start(categoryCount: Int, handler: @escaping (Int) -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let chars = event.charactersIgnoringModifiers,
               let num = Int(chars), num >= 1, num <= categoryCount {
                handler(num)
                return nil // consume the event
            }
            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
