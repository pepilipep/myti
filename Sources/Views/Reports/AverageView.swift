import SwiftUI

struct AverageView: View {
    let entries: [DayReportEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Daily average (last 30 days)")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textDimmer)
                .padding(.bottom, 6)

            if entries.isEmpty {
                Text("No data yet")
                    .foregroundColor(AppColors.textDimmest)
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else {
                ForEach(entries) { entry in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: entry.color))
                            .frame(width: 12, height: 12)

                        Text(entry.categoryName)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.text)

                        Spacer()

                        Text("\(entry.totalMinutes, specifier: "%.1f")m/day")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textDimmer)
                    }
                }
            }
        }
    }
}
