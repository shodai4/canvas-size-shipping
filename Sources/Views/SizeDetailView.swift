import SwiftUI

/// 選択中の号数。寸法、比率、お気に入り、メモ。
struct SizeDetailView: View {
    let size: CanvasSize
    let isFavorite: Bool
    let memo: String
    let onToggleFavorite: () -> Void
    let onEditMemo: () -> Void

    private var goldenDelta: String {
        String(format: "%+.2f", size.aspect - RatioCanvas.goldenRatio)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(size.name)
                    .font(Theme.serif(44))
                    .foregroundStyle(Theme.ink)
                Text(size.type.meaning)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 8)
                Text("\(size.dimensions) ミリ")
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.ink)
            }

            RatioCanvas(aspect: size.aspect)
                .frame(height: 118)
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
                Spacer(minLength: 8)
                Text("黄金比 1 : 1.62")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
                Text(goldenDelta)
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.accent)
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
    }
}
