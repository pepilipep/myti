import SwiftUI
import Charts

private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

struct WeekSummaryView: View, Equatable {
    let report: WeekReport

    @State private var hoveredDay: String?
    @State private var mouseLocation: CGPoint = .zero

    static func == (lhs: WeekSummaryView, rhs: WeekSummaryView) -> Bool {
        lhs.report == rhs.report
    }

    private var maxDayMinutes: Double {
        report.days.map(\.totalMinutes).max() ?? 0
    }

    private var hoveredDayData: DayReport? {
        guard let hDay = hoveredDay,
              let dayIndex = dayNames.firstIndex(of: hDay),
              dayIndex < report.days.count,
              report.days[dayIndex].totalMinutes > 0 else { return nil }
        return report.days[dayIndex]
    }

    var body: some View {
        if report.totalMinutes == 0 {
            Text("No entries")
                .foregroundColor(AppColors.textDimmest)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Week: \(formatMinutes(report.totalMinutes))")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textDimmer)

                Chart {
                    ForEach(Array(report.days.enumerated()), id: \.offset) { dayIndex, day in
                        ForEach(day.entries) { entry in
                                BarMark(
                                    x: .value("Minutes", entry.totalMinutes),
                                    y: .value("Day", dayNames[dayIndex]),
                                    height: 8
                                )
                                .foregroundStyle(Color(hex: entry.color).opacity(
                                    hoveredDay == nil || hoveredDay == dayNames[dayIndex] ? 1.0 : 0.4
                                ))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.textDimmer)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))m")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.textDimmest)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.borderSubtle)
                    }
                }
                .chartXScale(domain: 0 ... maxDayMinutes * 1.15)
                .chartYScale(domain: dayNames)
                .chartPlotStyle { plot in
                    plot.frame(height: 200)
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    mouseLocation = location
                                    if let day: String = proxy.value(atY: location.y) {
                                        hoveredDay = day
                                    }
                                case .ended:
                                    hoveredDay = nil
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let day = hoveredDayData {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(day.entries) { entry in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: entry.color))
                                        .frame(width: 6, height: 6)
                                    Text("\(entry.categoryName) \(formatMinutes(entry.totalMinutes))")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppColors.text)
                                }
                            }
                            Text(formatMinutes(day.totalMinutes))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppColors.textDimmer)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "#1a1a2e"))
                        )
                        .fixedSize()
                        .offset(x: mouseLocation.x + 12, y: mouseLocation.y + 12)
                        .allowsHitTesting(false)
                        .zIndex(1)
                    }
                }

            }
        }
    }
}
