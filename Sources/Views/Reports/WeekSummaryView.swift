import SwiftUI
import Charts

private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

struct WeekSummaryView: View {
    let report: WeekReport

    @State private var hoveredDay: String?

    var body: some View {
        if report.totalMinutes == 0 {
            Text("No entries for this week")
                .foregroundColor(AppColors.textDimmest)
                .frame(maxWidth: .infinity)
                .padding(20)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Week total: \(formatMinutes(report.totalMinutes))")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textDimmer)

                Chart {
                    ForEach(Array(report.days.enumerated()), id: \.offset) { dayIndex, day in
                        ForEach(day.entries) { entry in
                            BarMark(
                                x: .value("Day", dayNames[dayIndex]),
                                y: .value("Minutes", entry.totalMinutes)
                            )
                            .foregroundStyle(Color(hex: entry.color).opacity(
                                hoveredDay == nil || hoveredDay == dayNames[dayIndex] ? 1.0 : 0.4
                            ))
                        }
                    }

                    if let hDay = hoveredDay,
                       let dayIndex = dayNames.firstIndex(of: hDay),
                       dayIndex < report.days.count {
                        let dayTotal = report.days[dayIndex].totalMinutes
                        if dayTotal > 0 {
                            RuleMark(x: .value("Day", hDay))
                                .foregroundStyle(AppColors.textDimmest)
                                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .annotation(position: .top) {
                                    Text(formatMinutes(dayTotal))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColors.text)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: "#1a1a2e"))
                                        )
                                }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .foregroundColor(AppColors.textDimmer)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))m")
                                    .foregroundColor(AppColors.textDimmest)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.borderSubtle)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    if let day: String = proxy.value(atX: location.x) {
                                        hoveredDay = day
                                    }
                                case .ended:
                                    hoveredDay = nil
                                }
                            }
                    }
                }
                .frame(height: 300)

                // Legend
                legendView
            }
        }
    }

    @ViewBuilder
    private var legendView: some View {
        let categories = report.totals
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], spacing: 4) {
            ForEach(categories) { entry in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: entry.color))
                        .frame(width: 8, height: 8)
                    Text(entry.categoryName)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textDimmer)
                }
            }
        }
    }
}
