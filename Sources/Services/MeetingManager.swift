import Foundation

final class MeetingManager {
    static let shared = MeetingManager()
    private init() {}

    func createMeetingEntries(busyBlock: BusyBlock) {
        // Find the "Meetings" category, then find or create an "unspecified" activity for it
        let categories = CategoryStore.shared.listCategories()
        guard let meetingsCat = categories.first(where: { $0.name == "Meetings" }),
              let categoryId = meetingsCat.id else {
            Logger.shared.error("No active \"Meetings\" category found — skipping meeting entries")
            return
        }

        guard let activity = ActivityStore.shared.findOrCreate(name: "unspecified", categoryId: categoryId),
              let activityId = activity.id else {
            Logger.shared.error("Failed to find/create meeting activity")
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startDate = formatter.date(from: busyBlock.start),
              let endDate = formatter.date(from: busyBlock.end) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let startDate = formatter.date(from: busyBlock.start),
                  let endDate = formatter.date(from: busyBlock.end) else {
                Logger.shared.error("Failed to parse meeting dates")
                return
            }
            let durationMinutes = endDate.timeIntervalSince(startDate) / 60
            EntryStore.shared.createEntry(
                activityId: activityId,
                promptedAt: busyBlock.end,
                respondedAt: busyBlock.end,
                creditedMinutes: durationMinutes.rounded()
            )
            return
        }

        let durationMinutes = endDate.timeIntervalSince(startDate) / 60
        EntryStore.shared.createEntry(
            activityId: activityId,
            promptedAt: busyBlock.end,
            respondedAt: busyBlock.end,
            creditedMinutes: durationMinutes.rounded()
        )
    }
}
