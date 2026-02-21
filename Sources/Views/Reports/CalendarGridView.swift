import SwiftUI

private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private let hourHeight: CGFloat = 36
private let startHour = 6
private let endHour = 24
private let totalHours = endHour - startHour
private let columnHeight = CGFloat(totalHours) * hourHeight

struct CalendarGridView: View {
    let report: WeekTimeline
    var onEntryDelete: ((Int64) -> Void)?

    @State private var hoveredEntry: HoveredEntry?

    private var todayStr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour labels
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear.frame(height: 36)

                ZStack(alignment: .topTrailing) {
                    Color.clear.frame(width: 32, height: columnHeight)

                    ForEach(startHour..<endHour, id: \.self) { h in
                        Text("\(h)")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#555555"))
                            .position(x: 16, y: CGFloat(h - startHour) * hourHeight)
                    }
                }
            }
            .frame(width: 32)

            // Day columns
            HStack(spacing: 3) {
                ForEach(Array(report.days.enumerated()), id: \.offset) { index, day in
                    let isToday = day.date == todayStr
                    let dayDate = parseDateStr(day.date)
                    let dateNum = Calendar.current.component(.day, from: dayDate)
                    let hours = (day.totalMinutes / 60 * 10).rounded() / 10

                    VStack(spacing: 2) {
                        // Day name header
                        Text(dayNames[index])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isToday ? AppColors.accent : AppColors.textDimmer)

                        // Date number
                        Text("\(dateNum)")
                            .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                            .foregroundColor(isToday ? AppColors.accent : Color(hex: "#cccccc"))

                        // Timeline column
                        ZStack(alignment: .topLeading) {
                            // Background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isToday ? AppColors.todayBackground : AppColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isToday ? AppColors.accent : AppColors.borderSubtle, lineWidth: 1)
                                )

                            // Hour gridlines
                            ForEach(startHour..<endHour, id: \.self) { h in
                                Rectangle()
                                    .fill(Color.white.opacity(0.03))
                                    .frame(height: 1)
                                    .offset(y: CGFloat(h - startHour) * hourHeight)
                            }

                            // Entry blocks
                            ForEach(Array(day.entries.enumerated()), id: \.offset) { entryIndex, entry in
                                entryBlock(entry: entry, dayIndex: index, entryIndex: entryIndex)
                            }
                        }
                        .frame(height: columnHeight)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            if let hovered = hoveredEntry, hovered.id.dayIndex == index {
                                Text(hovered.text)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.text)
                                    .fixedSize()
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(hex: "#1a1a2e"))
                                    )
                                    .offset(y: hovered.top + hovered.height / 2 - 10)
                                    .allowsHitTesting(false)
                            }
                        }

                        // Total hours
                        if day.totalMinutes > 0 {
                            Text("\(hours, specifier: "%.1f")h")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textDimmer)
                        } else {
                            Text(" ")
                                .font(.system(size: 11))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .zIndex(hoveredEntry?.id.dayIndex == index ? 1 : 0)
                }
            }
        }
    }

    @ViewBuilder
    private func entryBlock(entry: TimelineEntry, dayIndex: Int, entryIndex: Int) -> some View {
        let endTime = parseISO(entry.promptedAt)
        let startTime = endTime.addingTimeInterval(-entry.creditedMinutes * 60)
        let startMins = Calendar.current.component(.hour, from: startTime) * 60 + Calendar.current.component(.minute, from: startTime)
        let startMinThreshold = startHour * 60

        if startMins >= startMinThreshold {
            let top = CGFloat(startMins - startMinThreshold) / CGFloat(totalHours * 60) * columnHeight
            let height = max(3, entry.creditedMinutes / CGFloat(totalHours * 60) * columnHeight)
            let entryId = EntryId(dayIndex: dayIndex, entryIndex: entryIndex)
            let isHovered = hoveredEntry?.id == entryId

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: entry.color).opacity(isHovered ? 1.0 : 0.85))
                .frame(height: height)
                .padding(.horizontal, 2)
                .offset(y: top)
                .onHover { hovering in
                    if hovering {
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "HH:mm"
                        let label = "\(entry.categoryName) — \(timeFormatter.string(from: startTime))–\(timeFormatter.string(from: endTime))"
                        hoveredEntry = HoveredEntry(id: entryId, text: label, top: top, height: height)
                    } else if hoveredEntry?.id == entryId {
                        hoveredEntry = nil
                    }
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        onEntryDelete?(entry.entryId)
                    }
                }
        }
    }

    private func parseDateStr(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str) ?? Date()
    }

    private func parseISO(_ str: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: str) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: str) ?? Date()
    }
}

private struct EntryId: Equatable {
    let dayIndex: Int
    let entryIndex: Int
}

private struct HoveredEntry {
    let id: EntryId
    let text: String
    let top: CGFloat
    let height: CGFloat
}
