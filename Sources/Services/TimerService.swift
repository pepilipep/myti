import Foundation
import AppKit

final class TimerService: ObservableObject {
    static let shared = TimerService()

    private let pollInterval: TimeInterval = 10
    private var timer: Timer?
    @Published var currentPromptedAt: String?

    private init() {}

    func start() {
        stop()
        guard SettingsStore.shared.isTrackingActive() else { return }

        let settings = SettingsStore.shared.getAll()

        // Initialize or fix stale next_prompt_at
        if let stored = SettingsStore.shared.getNextPromptAt() {
            let staleThreshold = Double(settings.intervalMinutes) * 60
            let msSinceNext = Date().timeIntervalSince1970 - isoToDate(stored).timeIntervalSince1970
            if msSinceNext > staleThreshold {
                scheduleNext()
            }
        } else {
            scheduleNext()
        }

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        if SettingsStore.shared.isTrackingActive() {
            start()
        }
    }

    func toggleTracking() -> Bool {
        let current = SettingsStore.shared.isTrackingActive()
        let next = !current
        SettingsStore.shared.set(key: "tracking_active", value: next ? "1" : "0")
        if next {
            start()
        } else {
            stop()
        }
        return next
    }

    func clearCurrentPromptedAt() {
        currentPromptedAt = nil
    }

    func setNextPromptAt(_ iso: String) {
        SettingsStore.shared.setNextPromptAt(iso)
    }

    func rescheduleFromNow() {
        scheduleNext()
    }

    // MARK: - Private

    private func scheduleNext() {
        let settings = SettingsStore.shared.getAll()
        let next = Date().addingTimeInterval(Double(settings.intervalMinutes) * 60)
        let iso = dateToISO(next)
        SettingsStore.shared.setNextPromptAt(iso)
    }

    private func poll() {
        guard SettingsStore.shared.isTrackingActive() else { return }

        guard let nextStr = SettingsStore.shared.getNextPromptAt() else {
            scheduleNext()
            return
        }

        let now = Date()
        let nextDate = isoToDate(nextStr)
        guard now >= nextDate else { return }

        // Time to prompt — schedule the next one first
        scheduleNext()

        // Don't stack popups
        if WindowManager.shared.isPopupVisible { return }

        let categories = CategoryStore.shared.listCategories()
        guard !categories.isEmpty else { return }

        currentPromptedAt = dateToISO(Date())
        WindowManager.shared.showPopup(categories: categories, promptedAt: currentPromptedAt!)
    }

    // MARK: - Date Helpers

    private func isoToDate(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso) ?? Date()
    }

    private func dateToISO(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
