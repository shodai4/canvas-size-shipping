import SwiftUI

/// 号数の比率を見せる図。枠に沿って長辺と短辺の実寸を細字で書き込む。
struct RatioCanvas: View {
    /// 長辺 ÷ 短辺。
    let aspect: Double
    /// 長辺（ミリ）。
    let longMm: Int
    /// 短辺（ミリ）。
    let shortMm: Int

    /// 寸法の文字が入る余白。
    private let inset: CGFloat = 26
    /// 寸法線と枠の間。
    private let gap: CGFloat = 5

    var body: some View {
        Canvas { context, size in
            let available = CGSize(width: max(1, size.width - inset * 2),
                                   height: max(1, size.height - inset * 2))
            let box = frame(for: available, in: size)

            context.fill(Path(box), with: .color(Theme.paperDeep))
            context.stroke(Path(box), with: .color(Theme.ink), lineWidth: 1)

            drawDimensions(context: context, box: box, canvas: size)
        }
        .background(Theme.paper)
    }

    /// 比率を保ったまま、余白の内側に収まる枠を出す。
    private func frame(for available: CGSize, in size: CGSize) -> CGRect {
        var width = available.width
        var height = width / CGFloat(max(0.05, aspect))
        if height > available.height {
            height = available.height
            width = height * CGFloat(max(0.05, aspect))
        }
        return CGRect(x: (size.width - width) / 2,
                      y: (size.height - height) / 2,
                      width: width,
                      height: height)
    }

    private func drawDimensions(context: GraphicsContext, box: CGRect, canvas: CGSize) {
        let tick: CGFloat = 3

        // 長辺は下辺に沿って。
        let longY = min(box.maxY + gap, canvas.height - 2)
        var bottom = Path()
        bottom.move(to: CGPoint(x: box.minX, y: longY))
        bottom.addLine(to: CGPoint(x: box.maxX, y: longY))
        bottom.move(to: CGPoint(x: box.minX, y: longY - tick))
        bottom.addLine(to: CGPoint(x: box.minX, y: longY + tick))
        bottom.move(to: CGPoint(x: box.maxX, y: longY - tick))
        bottom.addLine(to: CGPoint(x: box.maxX, y: longY + tick))
        context.stroke(bottom, with: .color(Theme.hairline), lineWidth: 0.6)

        let longText = Text("\(longMm) mm")
            .font(.system(size: 8, design: .monospaced))
            .foregroundStyle(Theme.inkSoft)
        context.draw(longText,
                     at: CGPoint(x: box.midX, y: longY + 10),
                     anchor: .center)

        // 短辺は左辺に沿って、縦に。
        let shortX = max(box.minX - gap, 2)
        var left = Path()
        left.move(to: CGPoint(x: shortX, y: box.minY))
        left.addLine(to: CGPoint(x: shortX, y: box.maxY))
        left.move(to: CGPoint(x: shortX - tick, y: box.minY))
        left.addLine(to: CGPoint(x: shortX + tick, y: box.minY))
        left.move(to: CGPoint(x: shortX - tick, y: box.maxY))
        left.addLine(to: CGPoint(x: shortX + tick, y: box.maxY))
        context.stroke(left, with: .color(Theme.hairline), lineWidth: 0.6)

        var rotated = context
        rotated.translateBy(x: shortX - 10, y: box.midY)
        rotated.rotate(by: .degrees(-90))
        let shortText = Text("\(shortMm) mm")
            .font(.system(size: 8, design: .monospaced))
            .foregroundStyle(Theme.inkSoft)
        rotated.draw(shortText, at: .zero, anchor: .center)
    }
}
