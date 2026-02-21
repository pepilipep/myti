import SwiftUI

enum ReportViewType: String, CaseIterable {
    case week = "Week"
    case average = "Average"
}

struct ReportsView: View {
    @State private var viewType: ReportViewType = .week
    @State private var date: String = Self.todayStr()
    @State private var weekReport: WeekReport?
    @State private var weekTimeline: WeekTimeline?
    @State private var avgReport: [DayReportEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky header
            VStack(alignment: .leading, spacing: 12) {
                // Tab bar
                HStack(spacing: 8) {
                    ForEach(ReportViewType.allCases, id: \.self) { type in
                        Button(action: { viewType = type }) {
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: viewType == type ? .semibold : .regular))
                                .foregroundColor(AppColors.text)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(viewType == type ? AppColors.accent : AppColors.surface)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Date picker (not for average)
                if viewType == .week {
                    DateRangePickerView(
                        label: dateLabel,
                        onPrev: { date = addDays(date, n: -7) },
                        onNext: { date = addDays(date, n: 7) },
                        onToday: { date = Self.todayStr() }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch viewType {
                    case .week:
                        HStack(alignment: .top, spacing: 16) {
                            if let timeline = weekTimeline {
                                CalendarGridView(report: timeline, onEntryDelete: { entryId in
                                    EntryStore.shared.deleteEntry(id: entryId)
                                    loadData()
                                })
                            }
                            if let report = weekReport {
                                WeekSummaryView(report: report)
                                    .equatable()
                                    .frame(minWidth: 220)
                            }
                        }

                    case .average:
                        AverageView(entries: avgReport)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(AppColors.background)
        .onChange(of: viewType) { _, _ in loadData() }
        .onChange(of: date) { _, _ in loadData() }
        .onAppear { loadData() }
    }

    private var dateLabel: String {
        if let wr = weekReport {
            return "\(wr.startDate) — \(wr.endDate)"
        }
        return date
    }

    private func loadData() {
        switch viewType {
        case .week:
            weekReport = ReportStore.shared.getWeekReport(startDate: date)
            weekTimeline = ReportStore.shared.getWeekTimeline(startDate: date)

        case .average:
            let end = Self.todayStr()
            let start = addDays(end, n: -29)
            avgReport = ReportStore.shared.getAverageReport(startDate: start, endDate: end)
        }
    }

    // MARK: - Date Helpers

    static func todayStr() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func addDays(_ dateStr: String, n: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: dateStr) else { return dateStr }
        let result = Calendar.current.date(byAdding: .day, value: n, to: d)!
        return formatter.string(from: result)
    }
}
