struct DayReportEntry: Identifiable {
    let categoryId: Int64
    let categoryName: String
    let color: String
    let totalMinutes: Double
    let entryCount: Double

    var id: Int64 { categoryId }
}

struct DayReport {
    let date: String
    let entries: [DayReportEntry]
    let totalMinutes: Double
}

struct WeekReport {
    let startDate: String
    let endDate: String
    let days: [DayReport]
    let totals: [DayReportEntry]
    let totalMinutes: Double
}

struct TimelineEntry {
    let promptedAt: String
    let creditedMinutes: Double
    let categoryName: String
    let color: String
}

struct DayTimeline {
    let date: String
    let entries: [TimelineEntry]
    let totalMinutes: Double
}

struct WeekTimeline {
    let startDate: String
    let endDate: String
    let days: [DayTimeline]
}
