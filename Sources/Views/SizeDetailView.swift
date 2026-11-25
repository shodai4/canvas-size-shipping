import SwiftUI

/// 選択中の号数。型と数字をそれぞれプルダウンで選び、寸法と比率、お気に入り、メモを出す。
struct SizeDetailView: View {
    @Binding var size: CanvasSize
    let isFavorite: Bool
    let memo: String
    let onToggleFavorite: () -> Void
    let onEditMemo: () -> Void

    /// 型をサムホールから戻したときに使う号数。
    @State private var lastNumber: Int = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                typeMenu
                if size.type != .sm {
                    numberMenu
                }
                Spacer(minLength: 8)
                Text(size.type.meaning)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.inkFaint)
            }

            RatioCanvas(aspect: size.aspect,
                        longMm: size.longMm,
                        shortMm: size.shortMm)
                .frame(height: 130)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )

            HStack(spacing: 8) {
                Text("比率")
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.inkFaint)
                Text(String(format: "1 : %.2f", size.aspect))
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }

            HStack(spacing: 16) {
                Button(action: onToggleFavorite) {
                    Text(isFavorite ? "お気に入りから外す" : "お気に入りに入れる")
                        .font(Theme.mono(10))
                        .foregroundStyle(isFavorite ? Theme.accent : Theme.inkSoft)
                }
                .buttonStyle(.plain)

                Button(action: onEditMemo) {
                    Text(memo.isEmpty ? "作品メモを書く" : "作品メモを直す")
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
