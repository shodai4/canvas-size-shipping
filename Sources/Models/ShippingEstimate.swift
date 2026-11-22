import Foundation

/// 三社それぞれの見積もり。
struct ShippingEstimate: Identifiable {
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

    /// 「160サイズ」「ラージ 200サイズ」「不可」などの一行。
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

/// 3辺合計と着地から、三社の区分と運賃を出す。
enum ShippingCalculator {
    static func estimates(totalCm: Int,
                          longSideCm: Int,
                          weightKg: Double = 0,
                          zone: ShippingZone,
                          tables: [CarrierTable] = ShippingRates.tables) -> [ShippingEstimate] {
        tables.map { table in
            estimate(table: table,
                     totalCm: totalCm,
                     longSideCm: longSideCm,
                     weightKg: weightKg,
                     zone: zone)
        }
    }

    private static func estimate(table: CarrierTable,
                                 totalCm: Int,
                                 longSideCm: Int,
                                 weightKg: Double,
                                 zone: ShippingZone) -> ShippingEstimate {
        if totalCm > table.maxCm {
            return unavailable(table.carrier, reason: "上限\(table.maxCm)cmを超えます")
        }
        if let limit = table.maxLongSideCm, longSideCm > limit {
            return unavailable(table.carrier, reason: "1辺\(limit)cmを超えます")
        }
        if weightKg > table.maxKg {
            return unavailable(table.carrier, reason: "重さ\(Int(table.maxKg))キロを超えます")
        }
        guard let row = table.row(forTotalCm: totalCm) else {
            return unavailable(table.carrier, reason: "上限を超えます")
        }
        guard let fare = row.fare(for: zone) else {
            return unavailable(table.carrier, reason: "この着地の運賃は未収録です")
        }
        return ShippingEstimate(carrier: table.carrier,
                                sizeCm: row.sizeCm,
                                isLarge: row.isLarge,
                                fare: fare,
                                reason: nil)
    }

    private static func unavailable(_ carrier: Carrier, reason: String) -> ShippingEstimate {
        ShippingEstimate(carrier: carrier, sizeCm: nil, isLarge: false, fare: nil, reason: reason)
    }
}

/// 大型便の案内。上限を超えたときに、次の手を示す。
enum ShippingAdvisory {
    static func messages(totalCm: Int, longSideCm: Int) -> [String] {
        var messages: [String] = []
        if totalCm > 260 {
            messages.append("3辺合計が260cmを超えます。三社の通常便では送れないため、チャーター便か大型家具・家電の設置便での手配になり、運賃は見積もりになります。")
        } else if totalCm > 200 {
            messages.append("3辺合計が200cmを超えます。宅急便は使えません。ヤマト便か、佐川のラージサイズでの手配になります。")
        } else if totalCm > 170 {
            messages.append("3辺合計が170cmを超えます。ゆうパックは使えません。ヤマトの180・200サイズか、佐川のラージサイズになります。")
        }
        if longSideCm > 170, totalCm <= 200 {
            messages.append("1辺が170cmを超えます。宅急便では送れません。ヤマト便などでの手配になります。")
        }
        return messages
    }
}
