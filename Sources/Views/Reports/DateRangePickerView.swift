import SwiftUI

struct DateRangePickerView: View {
    let label: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.text)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.text)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.text)
            }
            .buttonStyle(.plain)

            Button(action: onToday) {
                Text("Today")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.accent)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(AppColors.accent, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
