import Foundation

/// 梱包のしかた。余裕と厚みを足して、送る荷物の大きさを出す。
struct PackingSpec: Equatable {
    /// 梱包の余裕。長辺・短辺それぞれに足す合計（ミリ）。既定は 50（各辺 25）。
    var marginMm: Double = 50
    /// 厚み（ミリ）。既定は 30。
    var thicknessMm: Double = 30
    /// 額装の有無。額縁の分だけ大きく、厚くなる。
    var framed: Bool = false

    /// 額装で長辺・短辺に足す分（ミリ）。
    static let frameExtraMm: Double = 30
    /// 額装で厚みに足す分（ミリ）。
    static let frameDepthMm: Double = 20
    /// ヤッコ包みで、折り返した先を中央で重ねる分（ミリ）。
    static let foldMm: Double = 15

    /// 号数から、梱包後の寸法を出す。
    func packed(for size: CanvasSize) -> PackedSize {
        let frameExtra = framed ? Self.frameExtraMm : 0
        let frameDepth = framed ? Self.frameDepthMm : 0
        return PackedSize(longMm: Double(size.longMm) + marginMm + frameExtra,
                          shortMm: Double(size.shortMm) + marginMm + frameExtra,
                          thicknessMm: thicknessMm + frameDepth)
    }

    /// ヤッコ包みに使う段ボール1枚の寸法。
    func yaccoSheet(for packed: PackedSize) -> YaccoSheet {
        YaccoSheet(widthMm: 2 * packed.shortMm + 2 * packed.thicknessMm + 2 * Self.foldMm,
                   heightMm: 2 * packed.longMm + 2 * packed.thicknessMm + 2 * Self.foldMm)
    }

    /// 余裕と厚みの一行表示。
    var summary: String {
        "余裕 \(Int(marginMm)) ・ 厚み \(Int(thicknessMm))"
    }
}

/// 梱包後の寸法。3辺合計はセンチに切り上げる。
struct PackedSize: Equatable {
    let longMm: Double
    let shortMm: Double
    let thicknessMm: Double

    /// 3辺合計（ミリ）。
    var totalMm: Double { longMm + shortMm + thicknessMm }

    /// 3辺合計（センチ、切り上げ）。
    var totalCm: Int { Int((totalMm / 10).rounded(.up)) }

    /// 長辺（センチ、切り上げ）。1辺の上限を見るのに使う。
    var longSideCm: Int { Int((longMm / 10).rounded(.up)) }

    /// 「460 × 368 × 50」。
    var dimensions: String {
        "\(Int(longMm.rounded())) × \(Int(shortMm.rounded())) × \(Int(thicknessMm.rounded()))"
    }
}

/// 平べったい段ボール1枚からヤッコ包み（たとう包み）で作るときの、必要な1枚の寸法。
///
/// 短辺方向は「短辺 × 2 ＋ 厚み × 2 ＋ 折り返し代 × 2」。前と後ろを1枚で覆い、
/// 左右の縁で厚みの分だけ折れ、折り返した先が中央で重なる長さを見る。
/// 長辺方向も同じ考えで「長辺 × 2 ＋ 厚み × 2 ＋ 折り返し代 × 2」。
/// 切り出しやすいよう、10ミリ単位に切り上げる。
struct YaccoSheet: Equatable {
    /// 短辺方向の長さ（ミリ）。
    let widthMm: Int
    /// 長辺方向の長さ（ミリ）。
    let heightMm: Int

    init(widthMm: Double, heightMm: Double) {
        self.widthMm = Self.roundUp(widthMm)
        self.heightMm = Self.roundUp(heightMm)
    }

    /// 10ミリ単位に切り上げる。
    static func roundUp(_ value: Double) -> Int {
        Int((value / 10).rounded(.up)) * 10
    }

    /// 「830 × 1010」。単位は別に書く。
    var text: String { "\(widthMm) × \(heightMm)" }
}
