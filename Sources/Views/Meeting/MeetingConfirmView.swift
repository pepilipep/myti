import SwiftUI

struct MeetingConfirmView: View {
    let title: String
    let formattedTime: String
    let onConfirm: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Upcoming meeting")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textBright)
                .multilineTextAlignment(.center)

            Text(formattedTime)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textDim)

            Text("Are you going to attend?")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Button(action: onConfirm) {
                    Text("Yes (Y)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 20)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#4a9eff")))
                }
                .buttonStyle(.plain)

                Button(action: onDecline) {
                    Text("No (N)")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textMuted)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "#404050"), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            KeyMonitor.shared.start(categoryCount: 0) { _ in }
            MeetingKeyMonitor.shared.start(onConfirm: onConfirm, onDecline: onDecline)
        }
        .onDisappear {
            MeetingKeyMonitor.shared.stop()
        }
    }
}

/// Captures Y/N/Escape key presses for the meeting confirmation panel.
final class MeetingKeyMonitor {
    static let shared = MeetingKeyMonitor()
    private var monitor: Any?

    func start(onConfirm: @escaping () -> Void, onDecline: @escaping () -> Void) {
        stop()
        // Stop the popup key monitor so number keys don't interfere
        KeyMonitor.shared.stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let char = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if char == "y" {
                onConfirm()
                return nil
            } else if char == "n" || event.keyCode == 53 /* Escape */ {
                onDecline()
                return nil
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
