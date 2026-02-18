import EventKit
import Foundation

final class CalendarService {
    static let shared = CalendarService()
    private let store = EKEventStore()

    private init() {}

    func getUpcomingBusyBlock(completion: @escaping (BusyBlock?) -> Void) {
        store.requestFullAccessToEvents { [weak self] granted, error in
            guard granted, error == nil, let self = self else {
                if let error = error {
                    Logger.shared.error("Calendar access denied", error: error)
                }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let now = Date()
            let intervalMinutes = Double(SettingsStore.shared.getAll().intervalMinutes)
            let later = now.addingTimeInterval(intervalMinutes * 60)
            let predicate = self.store.predicateForEvents(withStart: now, end: later, calendars: nil)
            let events = self.store.events(matching: predicate).filter { !$0.isAllDay }

            if events.isEmpty {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Convert to internal type
            struct CalEvent {
                var title: String
                var start: Date
                var end: Date
            }

            let calEvents: [CalEvent] = events.map {
                CalEvent(title: $0.title ?? "Untitled", start: $0.startDate, end: $0.endDate)
            }.sorted { $0.start < $1.start }

            // Merge overlapping / adjacent (within 5 min gap)
            var merged: [CalEvent] = [calEvents[0]]
            for i in 1..<calEvents.count {
                var last = merged[merged.count - 1]
                let curr = calEvents[i]
                if curr.start.timeIntervalSince(last.end) <= 5 * 60 {
                    if curr.end > last.end { last.end = curr.end }
                    if last.title != curr.title { last.title += " + " + curr.title }
                    merged[merged.count - 1] = last
                } else {
                    merged.append(curr)
                }
            }

            // Find first block that hasn't ended
            let firstBlock = merged.first { $0.end > now }

            guard let block = firstBlock else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let busyBlock = BusyBlock(
                start: formatter.string(from: block.start),
                end: formatter.string(from: block.end),
                title: block.title
            )

            DispatchQueue.main.async { completion(busyBlock) }
        }
    }
}
