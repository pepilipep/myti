import GRDB
import Foundation

final class ReportStore {
    static let shared = ReportStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    // MARK: - Overlap Deduplication

    private struct RawEntry {
        let entryId: Int64
        let categoryId: Int64
        let categoryName: String
        let color: String
        let promptedAt: String
        var creditedMinutes: Double
    }

    /// Fetches entries matching a WHERE clause, then trims overlapping time ranges.
    /// Each entry covers [promptedAt - creditedMinutes, promptedAt].
    /// Entries are walked in chronological order; if one overlaps a previous entry,
    /// its start is trimmed so no time is double-counted.
    private func fetchDeduped(whereClause: String, arguments: StatementArguments) throws -> [RawEntry] {
        let rows = try db.read { db in
            try Row.fetchAll(db, sql: """
                SELECT
                    e.id as entry_id,
                    e.category_id,
                    c.name as category_name,
                    c.color,
                    e.prompted_at,
                    e.credited_minutes
                FROM entries e
                JOIN categories c ON c.id = e.category_id
                WHERE \(whereClause)
                ORDER BY e.prompted_at ASC
            """, arguments: arguments)
        }

        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFmtNoFrac = ISO8601DateFormatter()
        isoFmtNoFrac.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String) -> Date {
            isoFmt.date(from: s) ?? isoFmtNoFrac.date(from: s) ?? Date()
        }

        var entries: [RawEntry] = []
        var latestEnd: Date = .distantPast

        for row in rows {
            let promptedAt: String = row["prompted_at"]
            let creditedMinutes: Double = row["credited_minutes"]
            let end = parseDate(promptedAt)
            let start = end.addingTimeInterval(-creditedMinutes * 60)

            var adjustedStart = start
            if adjustedStart < latestEnd {
                adjustedStart = latestEnd
            }

            let adjustedMinutes = end.timeIntervalSince(adjustedStart) / 60
            if adjustedMinutes <= 0 { continue }

            entries.append(RawEntry(
                entryId: row["entry_id"],
                categoryId: row["category_id"],
                categoryName: row["category_name"],
                color: row["color"],
                promptedAt: promptedAt,
                creditedMinutes: adjustedMinutes
            ))

            if end > latestEnd {
                latestEnd = end
            }
        }

        return entries
    }

    // MARK: - Day Report

    func getDayReport(date: String) -> DayReport {
        do {
            let raw = try fetchDeduped(
                whereClause: "date(e.prompted_at) = date(?)",
                arguments: [date]
            )

            var totalsMap: [Int64: (name: String, color: String, minutes: Double, count: Double)] = [:]
            for entry in raw {
                if let existing = totalsMap[entry.categoryId] {
                    totalsMap[entry.categoryId] = (existing.name, existing.color, existing.minutes + entry.creditedMinutes, existing.count + 1)
                } else {
                    totalsMap[entry.categoryId] = (entry.categoryName, entry.color, entry.creditedMinutes, 1)
                }
            }

            let entries = totalsMap.map { (id, val) in
                DayReportEntry(
                    categoryId: id,
                    categoryName: val.name,
                    color: val.color,
                    totalMinutes: val.minutes,
                    entryCount: val.count
                )
            }.sorted { $0.totalMinutes > $1.totalMinutes }

            let total = entries.reduce(0.0) { $0 + $1.totalMinutes }
            return DayReport(date: date, entries: entries, totalMinutes: total)
        } catch {
            Logger.shared.error("getDayReport failed", error: error)
            return DayReport(date: date, entries: [], totalMinutes: 0)
        }
    }

    // MARK: - Week Report

    func getWeekReport(startDate: String) -> WeekReport {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current

        guard var start = formatter.date(from: startDate) else {
            return WeekReport(startDate: startDate, endDate: startDate, days: [], totals: [], totalMinutes: 0)
        }

        // Adjust to Monday (ISO weekday: Mon=2, Sun=1 in Calendar)
        let cal = Calendar(identifier: .iso8601)
        let weekday = cal.component(.weekday, from: start)
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat
        let diff = weekday == 1 ? -6 : (2 - weekday)
        start = cal.date(byAdding: .day, value: diff, to: start)!

        var days: [DayReport] = []
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: i, to: start)!
            let dateStr = formatter.string(from: d)
            days.append(getDayReport(date: dateStr))
        }

        let endDate = cal.date(byAdding: .day, value: 6, to: start)!

        // Aggregate totals across the week
        var totalsMap: [Int64: DayReportEntry] = [:]
        for day in days {
            for entry in day.entries {
                if let existing = totalsMap[entry.categoryId] {
                    totalsMap[entry.categoryId] = DayReportEntry(
                        categoryId: existing.categoryId,
                        categoryName: existing.categoryName,
                        color: existing.color,
                        totalMinutes: existing.totalMinutes + entry.totalMinutes,
                        entryCount: existing.entryCount + entry.entryCount
                    )
                } else {
                    totalsMap[entry.categoryId] = entry
                }
            }
        }

        let totals = Array(totalsMap.values).sorted { $0.totalMinutes > $1.totalMinutes }
        let totalMinutes = totals.reduce(0.0) { $0 + $1.totalMinutes }

        return WeekReport(
            startDate: formatter.string(from: start),
            endDate: formatter.string(from: endDate),
            days: days,
            totals: totals,
            totalMinutes: totalMinutes
        )
    }

    // MARK: - Week Timeline

    private func getDayTimeline(date: String) -> DayTimeline {
        do {
            let raw = try fetchDeduped(
                whereClause: "date(e.prompted_at) = date(?)",
                arguments: [date]
            )

            let entries = raw.map { entry in
                TimelineEntry(
                    entryId: entry.entryId,
                    promptedAt: entry.promptedAt,
                    creditedMinutes: entry.creditedMinutes,
                    categoryName: entry.categoryName,
                    color: entry.color
                )
            }

            let total = entries.reduce(0.0) { $0 + $1.creditedMinutes }
            return DayTimeline(date: date, entries: entries, totalMinutes: total)
        } catch {
            Logger.shared.error("getDayTimeline failed", error: error)
            return DayTimeline(date: date, entries: [], totalMinutes: 0)
        }
    }

    func getWeekTimeline(startDate: String) -> WeekTimeline {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current

        guard var start = formatter.date(from: startDate) else {
            return WeekTimeline(startDate: startDate, endDate: startDate, days: [])
        }

        let cal = Calendar(identifier: .iso8601)
        let weekday = cal.component(.weekday, from: start)
        let diff = weekday == 1 ? -6 : (2 - weekday)
        start = cal.date(byAdding: .day, value: diff, to: start)!

        var days: [DayTimeline] = []
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: i, to: start)!
            days.append(getDayTimeline(date: formatter.string(from: d)))
        }

        let endDate = cal.date(byAdding: .day, value: 6, to: start)!

        return WeekTimeline(
            startDate: formatter.string(from: start),
            endDate: formatter.string(from: endDate),
            days: days
        )
    }

    // MARK: - Average Report

    func getAverageReport(startDate: String, endDate: String) -> [DayReportEntry] {
        do {
            let raw = try fetchDeduped(
                whereClause: "date(e.prompted_at) BETWEEN date(?) AND date(?)",
                arguments: [startDate, endDate]
            )

            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoFmtNoFrac = ISO8601DateFormatter()
            isoFmtNoFrac.formatOptions = [.withInternetDateTime]
            let dayFmt = DateFormatter()
            dayFmt.dateFormat = "yyyy-MM-dd"
            dayFmt.timeZone = TimeZone.current

            let datesWithEntries = Set(raw.compactMap { entry -> String? in
                guard let d = isoFmt.date(from: entry.promptedAt) ?? isoFmtNoFrac.date(from: entry.promptedAt) else { return nil }
                return dayFmt.string(from: d)
            })
            let numDays = max(1, datesWithEntries.count)

            var totalsMap: [Int64: (name: String, color: String, minutes: Double, count: Double)] = [:]
            for entry in raw {
                if let existing = totalsMap[entry.categoryId] {
                    totalsMap[entry.categoryId] = (existing.name, existing.color, existing.minutes + entry.creditedMinutes, existing.count + 1)
                } else {
                    totalsMap[entry.categoryId] = (entry.categoryName, entry.color, entry.creditedMinutes, 1)
                }
            }

            return totalsMap.map { (id, val) in
                DayReportEntry(
                    categoryId: id,
                    categoryName: val.name,
                    color: val.color,
                    totalMinutes: (val.minutes / Double(numDays) * 10).rounded() / 10,
                    entryCount: (val.count / Double(numDays) * 10).rounded() / 10
                )
            }.sorted { $0.totalMinutes > $1.totalMinutes }
        } catch {
            Logger.shared.error("getAverageReport failed", error: error)
            return []
        }
    }
}
