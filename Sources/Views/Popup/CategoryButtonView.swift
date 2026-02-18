import SwiftUI

struct CategoryButtonView: View {
    let category: Category
    let index: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Number badge with category color
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: category.color))
                    )

                // Category name
                Text(category.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: category.color).opacity(isHovered ? 0.27 : 0.13))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
