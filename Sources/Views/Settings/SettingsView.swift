import SwiftUI

struct SettingsView: View {
    @State private var settings: AppSettings?
    @State private var categories: [Category] = []
    @State private var editingCat: EditingCategory?
    @State private var intervalText: String = "20"

    struct EditingCategory {
        var id: Int64?
        var name: String
        var color: Color

        var hexColor: String {
            let nsColor = NSColor(color)
            guard let rgb = nsColor.usingColorSpace(.sRGB) else { return "#3B82F6" }
            let r = Int(rgb.redComponent * 255)
            let g = Int(rgb.greenComponent * 255)
            let b = Int(rgb.blueComponent * 255)
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.text)

                // Interval setting
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt interval (minutes)")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textDimmer)

                    TextField("", text: $intervalText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.text)
                        .frame(width: 80)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.border, lineWidth: 1))
                        )
                        .onSubmit { saveInterval() }
                }

                // Categories
                Text("Categories")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.text)

                VStack(spacing: 6) {
                    ForEach(categories) { cat in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: cat.color))
                                .frame(width: 16, height: 16)

                            Text(cat.name)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.text)

                            Spacer()

                            Button("Edit") {
                                editingCat = EditingCategory(
                                    id: cat.id,
                                    name: cat.name,
                                    color: Color(hex: cat.color)
                                )
                            }
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.text)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.border, lineWidth: 1))
                            )
                            .buttonStyle(.plain)

                            Button("Delete") {
                                if let id = cat.id {
                                    CategoryStore.shared.delete(id: id)
                                    loadData()
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 4).fill(AppColors.danger))
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Edit / Add form
                if let editing = editingCat {
                    HStack(spacing: 8) {
                        TextField("Name", text: Binding(
                            get: { editing.name },
                            set: { editingCat?.name = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.text)
                        .frame(width: 140)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.border, lineWidth: 1))
                        )

                        ColorPicker("", selection: Binding(
                            get: { editing.color },
                            set: { editingCat?.color = $0 }
                        ))
                        .frame(width: 32)

                        Button("Save") {
                            saveCat()
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 4).fill(AppColors.accent))
                        .buttonStyle(.plain)

                        Button("Cancel") {
                            editingCat = nil
                        }
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.text)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.border, lineWidth: 1))
                        )
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("+ Add Category") {
                        editingCat = EditingCategory(name: "", color: Color(hex: "#3B82F6"))
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 4).fill(AppColors.accent))
                    .buttonStyle(.plain)
                }
                #if DEBUG
                // Debug info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.text)
                        .padding(.top, 8)

                    Text("Next prompt at: \(nextPromptLabel)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(AppColors.textDimmer)
                }
                #endif
            }
            .padding(20)
        }
        .background(AppColors.background)
        .onAppear { loadData() }
    }

    private var nextPromptLabel: String {
        guard let iso = SettingsStore.shared.getNextPromptAt() else { return "—" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: iso)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: iso)
        }
        guard let d = date else { return iso }
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: d)
    }

    private func loadData() {
        let s = SettingsStore.shared.getAll()
        settings = s
        intervalText = "\(s.intervalMinutes)"
        categories = CategoryStore.shared.listCategories()
    }

    private func saveInterval() {
        guard let num = Int(intervalText), num >= 1 else { return }
        SettingsStore.shared.set(key: "interval_minutes", value: String(num))
        TimerService.shared.restart()
    }

    private func saveCat() {
        guard let editing = editingCat, !editing.name.isEmpty else { return }
        let cat = Category(
            id: editing.id,
            name: editing.name,
            color: editing.hexColor,
            sortOrder: 0,
            isActive: true
        )
        _ = CategoryStore.shared.upsert(cat)
        editingCat = nil
        loadData()
    }
}
