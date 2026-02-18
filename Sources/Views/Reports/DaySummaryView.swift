import SwiftUI
import Charts

struct DaySummaryView: View {
    let report: DayReport

    @State private var hoveredCategory: String?

    var body: some View {
        if report.entries.isEmpty {
            Text("No entries for this day")
                .foregroundColor(AppColors.textDimmest)
                .frame(maxWidth: .infinity)
                .padding(20)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total: \(formatMinutes(report.totalMinutes))")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textDimmer)

                Chart {
                    ForEach(report.entries) { entry in
                        BarMark(
                            x: .value("Minutes", entry.totalMinutes),
                            y: .value("Category", entry.categoryName)
                        )
                        .foregroundStyle(Color(hex: entry.color).opacity(
                            hoveredCategory == nil || hoveredCategory == entry.categoryName ? 1.0 : 0.4
                        ))
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            if hoveredCategory == entry.categoryName {
                                Text(formatMinutes(entry.totalMinutes))
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
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))m")
                                    .foregroundColor(AppColors.textDimmest)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.borderSubtle)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textDimmer)
                            }
                        }
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
                                    if let category: String = proxy.value(atY: location.y) {
                                        hoveredCategory = category
                                    }
                                case .ended:
                                    hoveredCategory = nil
                                }
                            }
                    }
                }
                .frame(height: CGFloat(max(200, report.entries.count * 40)))
            }
        }
    }
}
