import Foundation

// MARK: - 計算の条件

/// 一つの計算の条件。記録として残し、あとから計算タブへ戻す。
struct CalculationConditions: Codable, Hashable {
    /// 号数（「F6」「SM」など）。
    var sizeName: String
    /// 梱包の余裕（ミリ）。
    var marginMm: Double
    /// 厚み（ミリ）。
    var thicknessMm: Double
    /// 額装の有無。
    var framed: Bool
    /// 発地の都道府県（rawValue）。
    var origin: String
    /// 着地の都道府県（rawValue）。
    var destination: String

    var size: CanvasSize {
        CanvasCatalog.size(named: sizeName) ?? CanvasCatalog.samHall
    }

    var spec: PackingSpec {
        PackingSpec(marginMm: marginMm, thicknessMm: thicknessMm, framed: framed)
    }

    var packed: PackedSize {
        spec.packed(for: size)
    }

    var originPrefecture: Prefecture {
        Prefecture(rawValue: origin) ?? Prefecture.defaultPlace
    }

    var destinationPrefecture: Prefecture {
        Prefecture(rawValue: destination) ?? Prefecture.defaultPlace
    }

    /// 三社の見積もり。
    var quotes: [ShippingQuote] {
        ShippingCalculator.quotes(totalCm: packed.totalCm,
                                  longSideCm: packed.longSideCm,
                                  origin: originPrefecture,
                                  destination: destinationPrefecture)
    }

    /// 三社でいちばん安い運賃。送れる便がないときは nil。
    var lowestFare: Int? {
        quotes.compactMap(\.fare).min()
    }
}

// MARK: - 展示

/// 展示のまとまり。計算の記録をここに入れて、点数と送料目安を見る。
struct Exhibition: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
}

// MARK: - 記録の一件

/// 残した計算の一件。
struct CalculationRecord: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var conditions: CalculationConditions
    /// 入れている展示。未整理なら nil。
    var exhibitionID: UUID? = nil
    /// 作品名などの一言メモ。
    var note: String = ""

    var size: CanvasSize { conditions.size }
    var packed: PackedSize { conditions.packed }
    var fare: Int? { conditions.lowestFare }

    /// 「1,650円」。送れる便がないときは nil。
    var fareText: String? {
        guard let fare else { return nil }
        return "\(ShippingQuote.grouped(fare))円"
    }

    /// 「大阪→東京」。
    var routeText: String {
        "\(conditions.originPrefecture.shortName)→\(conditions.destinationPrefecture.shortName)"
    }
}

// MARK: - 展示ごとのまとめ

enum RecordSummary {
    /// 「3点 ・ 5,280円」。運賃が出る記録がないときは点数だけ。
    static func summary(_ records: [CalculationRecord]) -> String {
        let count = "\(records.count)点"
        guard let total = totalFare(records) else { return count }
        return "\(count) ・ \(ShippingQuote.grouped(total))円"
    }

    /// 送れる便のいちばん安い運賃の合計。
    static func totalFare(_ records: [CalculationRecord]) -> Int? {
        let fares = records.compactMap(\.fare)
        guard !fares.isEmpty else { return nil }
        return fares.reduce(0, +)
    }

    /// 「11月26日」。
    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 都道府県の短いいい方

extension Prefecture {
    /// 「大阪府」→「大阪」、「北海道」はそのまま。並んだ行を短くするのに使う。
    var shortName: String {
        var text = name
        if ["都", "府", "県"].contains(where: { text.hasSuffix($0) }) {
            text.removeLast()
        }
        return text
    }
}
