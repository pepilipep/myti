import SwiftUI

struct PopupView: View {
    let activities: [Activity]
    let categoryColors: [Int64: String]  // categoryId -> hex color
    let categoryNames: [Int64: String]   // categoryId -> name
    let promptedAt: String
    let onSubmit: (Int64, String) -> Void  // activityId, promptedAt
    let onCreateAndSubmit: (String, String) -> Void  // new activity name, promptedAt

    @State private var searchText = ""

    private var filteredActivities: [Activity] {
        if searchText.isEmpty { return activities }
        let query = searchText.lowercased()
        return activities.filter { $0.name.lowercased().contains(query) }
    }

    private var hasExactMatch: Bool {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        return activities.contains { $0.name.lowercased() == query }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("What were you doing?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textMuted)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Search / new activity input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textDim)

                Text(searchText.isEmpty ? "Search or type new..." : searchText)
                    .font(.system(size: 13))
                    .foregroundColor(searchText.isEmpty ? AppColors.textDim : AppColors.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !searchText.isEmpty {
                    Text("ESC")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textDimmest)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.surface)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Activity list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(filteredActivities.enumerated()), id: \.element.id) { index, activity in
                        ActivityRowView(
                            activity: activity,
                            color: activityColor(activity),
                            categoryName: activityCategoryName(activity),
                            index: index,
                            action: {
                                guard let id = activity.id else { return }
                                onSubmit(id, promptedAt)
                            }
                        )
                    }

                    // "Create new" row when typing something that doesn't exist
                    if !searchText.isEmpty && !hasExactMatch {
                        Button(action: {
                            let name = searchText.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            onCreateAndSubmit(name, promptedAt)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.accent)

                                Text("Create \"\(searchText.trimmingCharacters(in: .whitespaces))\"")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.accent)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Spacer()

                                Text("↵")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.textDimmest)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppColors.accent.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 12)
        }
        .onAppear {
            KeyMonitor.shared.start(
                activityCount: { self.filteredActivities.count },
                searchText: { self.searchText },
                onNumber: { num in
                    let acts = filteredActivities
                    guard num >= 1, num <= acts.count else { return }
                    let act = acts[num - 1]
                    if let id = act.id {
                        onSubmit(id, promptedAt)
                    }
                },
                onChar: { char in
                    searchText.append(char)
                },
                onBackspace: {
                    if !searchText.isEmpty {
                        searchText.removeLast()
                    }
                },
                onEnter: {
                    let acts = filteredActivities
                    if let first = acts.first, let id = first.id {
                        // If there are filtered results, submit the first one
                        onSubmit(id, promptedAt)
                    } else if !searchText.isEmpty {
                        // No matches — create new activity
                        let name = searchText.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        onCreateAndSubmit(name, promptedAt)
                    }
                },
                onEscape: {
                    if !searchText.isEmpty {
                        searchText = ""
                    } else {
                        WindowManager.shared.closePopup()
                    }
                }
            )
        }
        .onDisappear {
            KeyMonitor.shared.stop()
        }
    }

    private func activityColor(_ activity: Activity) -> String {
        if let catId = activity.categoryId, let color = categoryColors[catId] {
            return color
        }
        return "#6B7280"  // gray for uncategorized
    }

    private func activityCategoryName(_ activity: Activity) -> String? {
        guard let catId = activity.categoryId else { return nil }
        return categoryNames[catId]
    }
}

struct ActivityRowView: View {
    let activity: Activity
    let color: String
    let categoryName: String?
    let index: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Number badge (only for top 9)
                if index < 9 {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: color))
                        )
                } else {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 8, height: 8)
                        .padding(.horizontal, 6)
                }

                // Activity name
                Text(activity.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                // Category label
                if let categoryName {
                    Text(categoryName)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: color).opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: color).opacity(isHovered ? 0.27 : 0.13))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Captures key events via NSEvent local monitor.
/// Handles number shortcuts (when search is empty), text input, backspace, enter, escape.
final class KeyMonitor {
    static let shared = KeyMonitor()
    private var monitor: Any?

    func start(
        activityCount: @escaping () -> Int,
        searchText: @escaping () -> String,
        onNumber: @escaping (Int) -> Void,
        onChar: @escaping (Character) -> Void,
        onBackspace: @escaping () -> Void,
        onEnter: @escaping () -> Void,
        onEscape: @escaping () -> Void
    ) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode

            // Escape
            if keyCode == 53 {
                onEscape()
                return nil
            }

            // Enter / Return
            if keyCode == 36 || keyCode == 76 {
                onEnter()
                return nil
            }

            // Backspace
            if keyCode == 51 {
                onBackspace()
                return nil
            }

            // Character input
            if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                let char = chars.first!

                // Number shortcut: only when search is empty and no modifiers
                if searchText().isEmpty && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [] {
                    if let num = Int(String(char)), num >= 1, num <= activityCount() {
                        onNumber(num)
                        return nil
                    }
                }

                // Regular text input (printable characters)
                if char.isLetter || char.isNumber || char.isPunctuation || char.isSymbol || char == " " {
                    onChar(char)
                    return nil
                }
            }

            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
