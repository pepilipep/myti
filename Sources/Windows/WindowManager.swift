import AppKit
import SwiftUI

final class WindowManager {
    static let shared = WindowManager()

    private var popupPanel: PopupPanel?
    private var meetingPanel: PopupPanel?
    private var reportsPanel: FloatingPanel?
    private var settingsPanel: FloatingPanel?

    private init() {}

    // MARK: - Popup

    var isPopupVisible: Bool {
        popupPanel?.isVisible ?? false
    }

    func showPopup(categories: [Category], promptedAt: String) {
        if let existing = popupPanel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let screenSize = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        let width: CGFloat = 320
        let height: CGFloat = 260
        let x = (screenSize.width - width) / 2
        let y = (screenSize.height - height) / 2

        let panel = PopupPanel(contentRect: NSRect(x: x, y: y, width: width, height: height))

        let popupView = PopupView(
            categories: categories,
            promptedAt: promptedAt,
            onSubmit: { [weak self] categoryId, promptedAt in
                self?.handleEntrySubmit(categoryId: categoryId, promptedAt: promptedAt)
            }
        )
        .frame(width: width, height: height)
        .background(AppColors.background)

        PanelHosting.setContent(popupView, in: panel)
        panel.makeKeyAndOrderFront(nil)

        self.popupPanel = panel
    }

    func closePopup() {
        popupPanel?.close()
        popupPanel = nil
    }

    private func handleEntrySubmit(categoryId: Int64, promptedAt: String) {
        let now = Date()
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let respondedAt = isoFmt.string(from: now)
        let settings = SettingsStore.shared.getAll()
        EntryStore.shared.createEntry(
            categoryId: categoryId,
            promptedAt: promptedAt,
            respondedAt: respondedAt,
            creditedMinutes: Double(settings.intervalMinutes)
        )
        TimerService.shared.clearCurrentPromptedAt()
        closePopup()

        // If the user was AFK too long, reschedule from now instead of from the original prompt
        if let promptDate = isoFmt.date(from: promptedAt) {
            let delaySec = now.timeIntervalSince(promptDate)
            let thresholdSec = Double(settings.intervalMinutes) * 60.0 / 5.0
            if delaySec > thresholdSec {
                TimerService.shared.rescheduleFromNow()
            }
        }

        // Check for upcoming meetings
        CalendarService.shared.getUpcomingBusyBlock { [weak self] block in
            guard let block = block else { return }
            DispatchQueue.main.async {
                self?.showMeetingPopup(block: block)
            }
        }
    }

    // MARK: - Meeting Popup

    func showMeetingPopup(block: BusyBlock) {
        if let existing = meetingPanel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let screenSize = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        let width: CGFloat = 320
        let height: CGFloat = 160
        let x = (screenSize.width - width) / 2
        let y = (screenSize.height - height) / 2

        let panel = PopupPanel(contentRect: NSRect(x: x, y: y, width: width, height: height))

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDate = isoFormatter.date(from: block.start) ?? Date()
        let endDate = isoFormatter.date(from: block.end) ?? Date()
        let formattedTime = "\(formatter.string(from: startDate))–\(formatter.string(from: endDate))"

        let meetingView = MeetingConfirmView(
            title: block.title,
            formattedTime: formattedTime,
            onConfirm: { [weak self] in
                MeetingManager.shared.createMeetingEntries(busyBlock: block)
                let isoFmt = ISO8601DateFormatter()
                isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let endDate = isoFmt.date(from: block.end) ?? Date()
                let settings = SettingsStore.shared.getAll()
                let nextPrompt = endDate.addingTimeInterval(Double(settings.intervalMinutes) * 60)
                TimerService.shared.setNextPromptAt(isoFmt.string(from: nextPrompt))
                self?.closeMeetingPopup()
            },
            onDecline: { [weak self] in
                self?.closeMeetingPopup()
            }
        )
        .frame(width: width, height: height)
        .background(AppColors.background)

        PanelHosting.setContent(meetingView, in: panel)
        panel.makeKeyAndOrderFront(nil)

        self.meetingPanel = panel
    }

    func closeMeetingPopup() {
        meetingPanel?.close()
        meetingPanel = nil
    }

    // MARK: - Reports

    func showReports() {
        if let existing = reportsPanel {
            existing.showAndFocus()
            return
        }

        let panel = FloatingPanel(
            contentRect: NSRect(x: 200, y: 200, width: 800, height: 600),
            title: "myti — Reports"
        )

        let reportsView = ReportsView()
            .frame(minWidth: 800, minHeight: 600)
            .background(AppColors.background)

        PanelHosting.setContent(reportsView, in: panel)

        panel.center()
        panel.showAndFocus()

        panel.delegate = PanelCloseDelegate.shared
        PanelCloseDelegate.shared.onClose[ObjectIdentifier(panel)] = { [weak self] in
            self?.reportsPanel = nil
        }

        self.reportsPanel = panel
    }

    // MARK: - Settings

    func showSettings() {
        if let existing = settingsPanel {
            existing.showAndFocus()
            return
        }

        let panel = FloatingPanel(
            contentRect: NSRect(x: 200, y: 200, width: 500, height: 400),
            title: "myti — Settings"
        )

        let settingsView = SettingsView()
            .frame(minWidth: 500, minHeight: 400)
            .background(AppColors.background)

        PanelHosting.setContent(settingsView, in: panel)

        panel.center()
        panel.showAndFocus()

        panel.delegate = PanelCloseDelegate.shared
        PanelCloseDelegate.shared.onClose[ObjectIdentifier(panel)] = { [weak self] in
            self?.settingsPanel = nil
        }

        self.settingsPanel = panel
    }
}

// MARK: - Panel Close Delegate

final class PanelCloseDelegate: NSObject, NSWindowDelegate {
    static let shared = PanelCloseDelegate()
    var onClose: [ObjectIdentifier: () -> Void] = [:]

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let id = ObjectIdentifier(window)
        onClose[id]?()
        onClose[id] = nil
    }
}
