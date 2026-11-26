import SwiftUI

/// 選択中の号数。型と数字をそれぞれプルダウンで選び、2Dの寸法図か3Dの厚みを見る。
struct SizeDetailView: View {
    @Binding var size: CanvasSize
    /// 梱包後の厚み（ミリ）。3Dの側面に使う。
    let thicknessMm: Double
    /// 額装の有無。3Dの額縁に使う。
    let framed: Bool
    let isFavorite: Bool
    let memo: String
    let onToggleFavorite: () -> Void
    let onEditMemo: () -> Void

    /// 型をサムホールから戻したときに使う号数。
    @State private var lastNumber: Int = 6
    /// 2Dの寸法図か、3Dの厚みか。
    @AppStorage("showsCanvas3D") private var shows3D: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                typeMenu
                if size.type != .sm {
                    numberMenu
                }
                Spacer(minLength: 8)
                Text(String(format: "1 : %.2f", size.aspect))
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkFaint)
            }

            figure

            HStack(spacing: 18) {
                Button(action: onToggleFavorite) {
                    Text("お気に入り")
                        .font(Theme.mono(10, weight: isFavorite ? .medium : .regular))
                        .foregroundStyle(isFavorite ? Theme.accent : Theme.inkSoft)
                }
                .buttonStyle(.plain)

                Button(action: onEditMemo) {
                    Text("メモ")
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            if !memo.isEmpty {
                Text(memo)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { updateLastNumber() }
    }

    // MARK: - 図

    private var figure: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if shows3D {
                    Canvas3DView(longMm: size.longMm,
                                 shortMm: size.shortMm,
                                 thicknessMm: thicknessMm,
                                 framed: framed)
                } else {
                    RatioCanvas(aspect: size.aspect,
                                longMm: size.longMm,
                                shortMm: size.shortMm)
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(Theme.paper)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )

            HStack(spacing: 10) {
                modeButton("2D", selected: !shows3D) { shows3D = false }
                modeButton("3D", selected: shows3D) { shows3D = true }
            }
            .padding(8)
        }
    }

    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.mono(9, weight: selected ? .medium : .regular))
                .foregroundStyle(selected ? Theme.ink : Theme.inkFaint)
        }
        .buttonStyle(.plain)
    }

    // MARK: - プルダウン

    private var typeMenu: some View {
        Menu {
            ForEach(CanvasType.allCases) { type in
                Button {
                    select(type: type)
                } label: {
                    Text("\(type.code)　\(type.meaning)")
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(size.type.code)
                    .font(Theme.serif(40))
                    .foregroundStyle(Theme.ink)
                Text("▾")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .tint(Theme.ink)
    }

    private var numberMenu: some View {
        Menu {
            ForEach(CanvasCatalog.numbers(of: size.type), id: \.self) { number in
                Button {
                    select(number: number)
                } label: {
                    Text("\(number)")
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(size.number.map { String($0) } ?? "")
                    .font(Theme.serif(40))
                    .foregroundStyle(Theme.ink)
                Text("▾")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .tint(Theme.ink)
    }

    // MARK: - 選択

    private func select(type: CanvasType) {
        size = CanvasCatalog.size(for: type, near: lastNumber)
        updateLastNumber()
    }

    private func select(number: Int) {
        lastNumber = number
        if let picked = CanvasCatalog.size(named: size.type.code + "\(number)") {
            size = picked
        }
    }

    private func updateLastNumber() {
        if let number = size.number {
            lastNumber = number
        }
    }
}
