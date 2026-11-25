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

    /// 「160サイズ」「ラージ 200サイズ」「上限200cmを超えます」などの一行。
    var detail: String {
        if let reason { return reason }
        guard let sizeCm else { return "区分なし" }
        return isLarge ? "ラージ \(sizeCm)サイズ" : "\(sizeCm)サイズ"
    }

    /// 「2,630円」。送れないときは nil。
    var fareText: String? {
        guard let fare else { return nil }
        return "\(Self.grouped(fare))円"
    }

    /// 補償の一行。
    var compensationText: String { carrier.compensation }

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
            return unavailable(carrier, reason: "上限\(carrier.maxCm)cmを超えます")
        }
        if let limit = carrier.maxSideCm, longSideCm > limit {
            return unavailable(carrier, reason: "1辺\(limit)cmを超えます")
        }
        if weightKg > carrier.maxKg {
            return unavailable(carrier, reason: "重さ\(Int(carrier.maxKg))キロを超えます")
        }
        guard let sizeCm = ShippingRates.sizeCm(carrier: carrier, totalCm: totalCm) else {
            return unavailable(carrier, reason: "上限を超えます")
        }
        guard let fare = ShippingRates.fare(carrier: carrier,
                                            origin: origin,
                                            destination: destination,
                                            totalCm: totalCm,
                                            weightKg: weightKg) else {
            return unavailable(carrier, reason: "この区間の運賃は未収録です")
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
    let detail: String
    /// 「見積もり」「対象外」。
    let price: String

    var id: String { name }
}

enum ArtDelivery {
    /// 一点物の扱い。図の下に一行だけ添える。
    static let note = "ヤマトの宅急便は15号以下の絵画ならアートボックスで送れる。一点物・額装・大型は美術便へ。"

    /// 三社のほかに並べる便。
    static func options() -> [ArtOption] {
        [
            ArtOption(name: "ヤマト 美術便",
                      detail: "絵画・彫刻・屏風など。美術品専門のスタッフが梱包から運ぶ。事前予約制で、混載は最短1週間ほど、国内は数万円から。",
                      price: "見積もり"),
            ArtOption(name: "佐川 美術品輸送",
                      detail: "美術品専用車。学芸員資格を持つスタッフが搬入・展示・撤去まで対応する。",
                      price: "見積もり"),
            ArtOption(name: "家財おまかせ便",
                      detail: "3辺450cm・最長辺250cm・150kgまで（A〜Gランク）。美術品・骨董品・代替のきかない物は扱わない。",
                      price: "美術品は不可")
        ]
    }

    /// 大きさに応じた一行。小さければ何も出さない。
    static func summary(totalCm: Int, longSideCm: Int) -> String? {
        if longSideCm > 250 || totalCm > 450 {
            return "この大きさは家財おまかせ便でも扱えません。美術便かチャーターでの手配になり、運賃は見積もりです。"
        }
        if totalCm > 260 {
            return "3辺合計が260cmを超えます。三社の通常便では送れません。美術品は家財おまかせ便の対象外なので、美術便で見積もりになります。"
        }
        if totalCm > 200 {
            return "3辺合計が200cmを超えます。宅急便は使えません。佐川のラージサイズか、美術品なら美術便になります。"
        }
        if totalCm > 170 {
            return "3辺合計が170cmを超えます。ゆうパックは使えません。ヤマトの180・200サイズか、佐川のラージサイズになります。"
        }
        if longSideCm > 170 {
            return "1辺が170cmを超えます。宅急便では送れません。佐川のラージサイズか、美術品なら美術便になります。"
        }
        return nil
    }
}
