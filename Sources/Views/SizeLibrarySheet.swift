import SwiftUI

/// 全号数の一覧。お気に入りを上に置き、種別ごとに並べる。
struct SizeLibrarySheet: View {
    @Binding var selected: CanvasSize
    @ObservedObject var library: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !library.favoriteSizes.isEmpty {
                        group(title: "お気に入り", sizes: library.favoriteSizes)
                    }
                    ForEach(CanvasType.allCases) { type in
                        group(title: "\(type.code)　\(type.meaning)",
                              sizes: CanvasCatalog.sizes(of: type))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(Theme.paper)
            .navigationTitle("号数の一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private func group(title: String, sizes: [CanvasSize]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionMark(text: title)
                .padding(.top, 18)
                .padding(.bottom, 2)

            ForEach(sizes) { size in
                row(size)
                if size.id != sizes.last?.id {
                    Hairline()
                }
            }
        }
    }

    private func row(_ size: CanvasSize) -> some View {
        let isCurrent = size.id == selected.id
        return Button {
            selected = size
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Text(size.name)
                    .font(Theme.mono(12, weight: isCurrent ? .medium : .regular))
                Text(size.dimensions)
                    .font(Theme.mono(9.5))
                Spacer(minLength: 8)
                Text(String(format: "1 : %.2f", size.aspect))
                    .font(Theme.mono(9))
                if library.isFavorite(size) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 4, height: 4)
                }
            }
            .foregroundStyle(isCurrent ? Theme.ink : Theme.inkSoft)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
