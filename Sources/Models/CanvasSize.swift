import Foundation

// MARK: - 号数の種別

/// 呼び寸法の種別。F は人物、P は風景、M は海景、S は正方形、SM はサムホール。
enum CanvasType: String, CaseIterable, Identifiable {
    case f
    case p
    case m
    case s
    case sm

    var id: String { rawValue }

    /// 表記。
    var code: String {
        switch self {
        case .f: return "F"
        case .p: return "P"
        case .m: return "M"
        case .s: return "S"
        case .sm: return "SM"
        }
    }

    /// 由来の呼び名。
    var meaning: String {
        switch self {
        case .f: return "人物"
        case .p: return "風景"
        case .m: return "海景"
        case .s: return "正方形"
        case .sm: return "サムホール"
        }
    }
}

// MARK: - 一号分の寸法

/// 一号分の呼び寸法。長辺が縦、短辺が横にあたる（画材店の一覧と同じ向き）。
struct CanvasSize: Identifiable, Hashable {
    let type: CanvasType
    /// 号数。サムホールは nil。
    let number: Int?
    /// 長辺（ミリ）。
    let longMm: Int
    /// 短辺（ミリ）。
    let shortMm: Int

    var id: String { name }

    /// 「F6」「SM」などの表記。
    var name: String { type.code + (number.map { String($0) } ?? "") }

    /// 長辺 ÷ 短辺。
    var aspect: Double { Double(longMm) / Double(shortMm) }

    /// 「410 × 318」。
    var dimensions: String { "\(longMm) × \(shortMm)" }

    /// 面積（平方メートル）。目安の重さを出すのに使う。
    var areaSquareMeters: Double {
        Double(longMm) * Double(shortMm) / 1_000_000
    }
}

// MARK: - 全号数の一覧

/// 日本サイズ（国内で最も一般的な呼び寸法）の 0〜100 号とサムホール。
///
/// 数値は全日本画材協議会の支持体サイズ表、笹部洋画材料店、ゆめ画材、世界堂の
/// 一覧で突き合わせた。P0 と M0 は一部の一覧に載らないが、画材店の呼び寸法として
/// 存在するため収録した。S は号数に関わらず正方形。
enum CanvasCatalog {
    static let samHall = CanvasSize(type: .sm, number: nil, longMm: 227, shortMm: 158)

    static let fSizes: [CanvasSize] = rows(.f, [
        (0, 180, 140),
        (1, 220, 160),
        (2, 240, 190),
        (3, 273, 220),
        (4, 333, 242),
        (5, 350, 270),
        (6, 410, 318),
        (8, 455, 380),
        (10, 530, 455),
        (12, 606, 500),
        (15, 652, 530),
        (20, 727, 606),
        (25, 803, 652),
        (30, 910, 727),
        (40, 1000, 803),
        (50, 1167, 910),
        (60, 1303, 970),
        (80, 1455, 1120),
        (100, 1620, 1303)
    ])

    static let pSizes: [CanvasSize] = rows(.p, [
        (0, 180, 120),
        (1, 220, 140),
        (2, 240, 160),
        (3, 273, 190),
        (4, 333, 220),
        (5, 350, 240),
        (6, 410, 273),
        (8, 455, 333),
        (10, 530, 410),
        (12, 606, 455),
        (15, 652, 500),
        (20, 727, 530),
        (25, 803, 606),
        (30, 910, 652),
        (40, 1000, 727),
        (50, 1167, 803),
        (60, 1303, 894),
        (80, 1455, 970),
        (100, 1620, 1120)
    ])

    static let mSizes: [CanvasSize] = rows(.m, [
        (0, 180, 100),
        (1, 220, 120),
        (2, 240, 140),
        (3, 273, 160),
        (4, 333, 190),
        (5, 350, 220),
        (6, 410, 242),
        (8, 455, 273),
        (10, 530, 333),
        (12, 606, 410),
        (15, 652, 455),
        (20, 727, 500),
        (25, 803, 530),
        (30, 910, 606),
        (40, 1000, 652),
        (50, 1167, 727),
        (60, 1303, 803),
        (80, 1455, 894),
        (100, 1620, 970)
    ])

    static let sSizes: [CanvasSize] = rows(.s, [
        (0, 180, 180),
        (1, 220, 220),
        (2, 240, 240),
        (3, 273, 273),
        (4, 333, 333),
        (5, 350, 350),
        (6, 410, 410),
        (8, 455, 455),
        (10, 530, 530),
        (12, 606, 606),
        (15, 652, 652),
        (20, 727, 727),
        (25, 803, 803),
        (30, 910, 910),
        (40, 1000, 1000),
        (50, 1167, 1167),
        (60, 1303, 1303),
        (80, 1455, 1455),
        (100, 1620, 1620)
    ])

    /// 表示順（サムホール、F、P、M、S）。
    static let all: [CanvasSize] = [samHall] + fSizes + pSizes + mSizes + sSizes

    static func sizes(of type: CanvasType) -> [CanvasSize] {
        switch type {
        case .sm: return [samHall]
        case .f: return fSizes
        case .p: return pSizes
        case .m: return mSizes
        case .s: return sSizes
        }
    }

    static func size(named name: String) -> CanvasSize? {
        all.first { $0.name == name }
    }

    private static func rows(_ type: CanvasType, _ values: [(Int, Int, Int)]) -> [CanvasSize] {
        values.map { CanvasSize(type: type, number: $0.0, longMm: $0.1, shortMm: $0.2) }
    }
}
