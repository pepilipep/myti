import GRDB
import Foundation

final class ReportStore {
    static let shared = ReportStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    // MARK: - Day Report

    func getDayReport(date: String) -> DayReport {
        do {
            let entries: [DayReportEntry] = try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT
                        e.category_id,
                        c.name as category_name,
                        c.color,
                        SUM(e.credited_minutes) as total_minutes,
                        COUNT(*) as entry_count
                    FROM entries e
                    JOIN categories c ON c.id = e.category_id
                    WHERE date(e.prompted_at) = date(?)
                    GROUP BY e.category_id
                    ORDER BY total_minutes DESC
                """, arguments: [date])

                return rows.map { row in
                    DayReportEntry(
                        categoryId: row["category_id"],
                        categoryName: row["category_name"],
                        color: row["color"],
                        totalMinutes: row["total_minutes"],
                        entryCount: row["entry_count"]
                    )
                }
            }
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
            let entries: [TimelineEntry] = try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT
                        e.prompted_at,
                        e.credited_minutes,
                        c.name as category_name,
                        c.color
                    FROM entries e
                    JOIN categories c ON c.id = e.category_id
                    WHERE date(e.prompted_at) = date(?)
                    ORDER BY e.prompted_at ASC
                """, arguments: [date])

                return rows.map { row in
                    TimelineEntry(
                        promptedAt: row["prompted_at"],
                        creditedMinutes: row["credited_minutes"],
                        categoryName: row["category_name"],
                        color: row["color"]
                    )
                }
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
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT
                        e.category_id,
                        c.name as category_name,
                        c.color,
                        SUM(e.credited_minutes) as total_minutes,
                        COUNT(*) as entry_count
                    FROM entries e
                    JOIN categories c ON c.id = e.category_id
                    WHERE date(e.prompted_at) BETWEEN date(?) AND date(?)
                    GROUP BY e.category_id
                    ORDER BY total_minutes DESC
                """, arguments: [startDate, endDate])

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone.current

                let start = formatter.date(from: startDate)!.timeIntervalSince1970
                let end = formatter.date(from: endDate)!.timeIntervalSince1970
                let numDays = max(1, Int(round((end - start) / 86400)) + 1)

                return rows.map { row in
                    let totalMins: Double = row["total_minutes"]
                    let count: Int = row["entry_count"]
                    return DayReportEntry(
                        categoryId: row["category_id"],
                        categoryName: row["category_name"],
                        color: row["color"],
                        totalMinutes: (totalMins / Double(numDays) * 10).rounded() / 10,
                        entryCount: (Double(count) / Double(numDays) * 10).rounded() / 10
                    )
                }
            }
        } catch {
            Logger.shared.error("getAverageReport failed", error: error)
            return []
        }
    }
}
