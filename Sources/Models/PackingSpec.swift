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

    /// 号数から、梱包後の寸法を出す。
    func packed(for size: CanvasSize) -> PackedSize {
        let frameExtra = framed ? Self.frameExtraMm : 0
        let frameDepth = framed ? Self.frameDepthMm : 0
        return PackedSize(longMm: Double(size.longMm) + marginMm + frameExtra,
                          shortMm: Double(size.shortMm) + marginMm + frameExtra,
                          thicknessMm: thicknessMm + frameDepth)
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
