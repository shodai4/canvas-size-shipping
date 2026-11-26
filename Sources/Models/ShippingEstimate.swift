import Foundation

/// 一社分の見積もり。
struct ShippingQuote: Identifiable {
    let carrier: Carrier
    /// 当てはまったサイズ区分（センチ）。送れないときは nil。
    let sizeCm: Int?
    /// 佐川のラージサイズなど、大型の区分か。
    let isLarge: Bool
    /// 運賃（円、税込）。送れないときは nil。
    let fare: Int?
    /// 送れない理由。
    let reason: String?

    var id: String { carrier.rawValue }

    var isAvailable: Bool { fare != nil }

    /// 「160サイズ」「ラージ200」「上限200cm超」などの一行。
    var detail: String {
        if let reason { return reason }
        guard let sizeCm else { return "区分なし" }
        return isLarge ? "ラージ\(sizeCm)" : "\(sizeCm)サイズ"
    }

    /// 「2,630円」。送れないときは nil。
    var fareText: String? {
        guard let fare else { return nil }
        return "\(Self.grouped(fare))円"
    }

    /// 3桁ごとの区切り。端末の言語設定に左右されないよう、ここで決める。
    static func grouped(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

/// 3辺合計と発地・着地から、三社の区分と運賃を出す。
enum ShippingCalculator {
    static func quotes(totalCm: Int,
                       longSideCm: Int,
                       weightKg: Double = 0,
                       origin: Prefecture,
                       destination: Prefecture) -> [ShippingQuote] {
        Carrier.allCases.map { carrier in
            quote(carrier: carrier,
                  totalCm: totalCm,
                  longSideCm: longSideCm,
                  weightKg: weightKg,
                  origin: origin,
                  destination: destination)
        }
    }

    private static func quote(carrier: Carrier,
                              totalCm: Int,
                              longSideCm: Int,
                              weightKg: Double,
                              origin: Prefecture,
                              destination: Prefecture) -> ShippingQuote {
        if totalCm > carrier.maxCm {
            return unavailable(carrier, reason: "上限\(carrier.maxCm)cm超")
        }
        if let limit = carrier.maxSideCm, longSideCm > limit {
            return unavailable(carrier, reason: "1辺\(limit)cm超")
        }
        if weightKg > carrier.maxKg {
            return unavailable(carrier, reason: "重さ\(Int(carrier.maxKg))kg超")
        }
        guard let sizeCm = ShippingRates.sizeCm(carrier: carrier, totalCm: totalCm) else {
            return unavailable(carrier, reason: "上限を超えます")
        }
        guard let fare = ShippingRates.fare(carrier: carrier,
                                            origin: origin,
                                            destination: destination,
                                            totalCm: totalCm,
                                            weightKg: weightKg) else {
            return unavailable(carrier, reason: "未収録")
        }
        return ShippingQuote(carrier: carrier,
                             sizeCm: sizeCm,
                             isLarge: ShippingRates.isLarge(carrier: carrier, sizeCm: sizeCm),
                             fare: fare,
                             reason: nil)
    }

    private static func unavailable(_ carrier: Carrier, reason: String) -> ShippingQuote {
        ShippingQuote(carrier: carrier, sizeCm: nil, isLarge: false, fare: nil, reason: reason)
    }
}

// MARK: - アート便

/// 美術品・大型作品の輸送。金額は公表されていないので、見積もりか対象外だけを示す。
struct ArtOption: Identifiable {
    let name: String
    /// 公式ページ。
    let url: URL?
    /// 見積もりを受けられる便か。
    let isAvailable: Bool

    var id: String { name }

    /// 「見積もり ↗」「対象外」。
    var label: String {
        isAvailable ? "見積もり ↗" : "対象外"
    }
}

enum ArtDelivery {
    /// 三社のほかに並べる便。説明は注記シートに置く。
    static func options() -> [ArtOption] {
        [
            ArtOption(name: "ヤマト 美術便", url: OfficialLinks.yamatoArt, isAvailable: true),
            ArtOption(name: "佐川 美術品輸送", url: OfficialLinks.sagawaArt, isAvailable: true),
            ArtOption(name: "家財おまかせ便", url: OfficialLinks.artSetting, isAvailable: false)
        ]
    }

    /// 大きさに応じた一行。小さければ何も出さない。
    static func summary(totalCm: Int, longSideCm: Int) -> String? {
        if longSideCm > 250 || totalCm > 450 {
            return "美術便かチャーターで見積もり。"
        }
        if totalCm > 260 {
            return "通常便では送れません。美術便へ。"
        }
        if totalCm > 200 {
            return "宅急便は不可。佐川ラージか美術便。"
        }
        if totalCm > 170 {
            return "ゆうパックは不可。ヤマト180・200か佐川ラージ。"
        }
        if longSideCm > 170 {
            return "宅急便は不可。佐川ラージか美術便。"
        }
        return nil
    }
}
