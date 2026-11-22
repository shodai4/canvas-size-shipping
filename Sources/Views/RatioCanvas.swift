import SwiftUI

/// 号数の比率と黄金比を重ねて見せる。線は細く、色は二つだけ。
struct RatioCanvas: View {
    /// 長辺 ÷ 短辺。
    let aspect: Double

    /// 黄金比。
    static let goldenRatio = 1.618

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 14
            let available = CGSize(width: max(1, size.width - inset * 2),
                                   height: max(1, size.height - inset * 2))

            func frame(for ratio: Double) -> CGRect {
                var width = available.width
                var height = width / CGFloat(max(0.05, ratio))
                if height > available.height {
                    height = available.height
                    width = height * CGFloat(max(0.05, ratio))
                }
                return CGRect(x: (size.width - width) / 2,
                              y: (size.height - height) / 2,
                              width: width,
                              height: height)
            }

            let actual = frame(for: aspect)
            let golden = frame(for: Self.goldenRatio)

            var actualPath = Path()
            actualPath.addRect(actual)
            var goldenPath = Path()
            goldenPath.addRect(golden)

            context.fill(actualPath, with: .color(Theme.paperDeep))
            context.stroke(goldenPath,
                           with: .color(Theme.accent.opacity(0.55)),
                           style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
            context.stroke(actualPath, with: .color(Theme.ink), lineWidth: 1)
        }
        .background(Theme.paper)
    }
}
