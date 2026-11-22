import Foundation

// MARK: - 運送会社

/// 料金を並べる3社。
enum Carrier: String, CaseIterable, Identifiable, Codable {
    case yamato
    case japanPost
    case sagawa

    var id: String { rawValue }

    /// 会社名。
    var name: String {
        switch self {
        case .yamato: return "ヤマト運輸"
        case .japanPost: return "ゆうパック"
        case .sagawa: return "佐川急便"
        }
    }

    /// 便の名前。
    var service: String {
        switch self {
        case .yamato: return "宅急便"
        case .japanPost: return "ゆうパック"
        case .sagawa: return "飛脚宅配便"
        }
    }
}

// MARK: - 着地

/// 着地の区分。関西（大阪）から出す前提で、実運賃の表を5つにまとめた。
enum ShippingZone: String, CaseIterable, Identifiable, Codable {
    case kansai
    case chubuHokuriku
    case kantoShinetsu
    case kyushu
    case hokkaido

    var id: String { rawValue }

    /// 短い表示。
    var label: String {
        switch self {
        case .kansai: return "関西"
        case .chubuHokuriku: return "中部・北陸"
        case .kantoShinetsu: return "関東・信越"
        case .kyushu: return "九州"
        case .hokkaido: return "北海道"
        }
    }

    /// 含まれる都道府県。
    var detail: String {
        switch self {
        case .kansai:
            return "大阪・京都・兵庫・奈良・滋賀・和歌山"
        case .chubuHokuriku:
            return "愛知・静岡・岐阜・三重・富山・石川・福井"
        case .kantoShinetsu:
            return "東京・神奈川・埼玉・千葉・茨城・栃木・群馬・山梨・新潟・長野"
        case .kyushu:
            return "福岡・佐賀・長崎・大分・熊本・宮崎・鹿児島"
        case .hokkaido:
            return "北海道"
        }
    }
}

// MARK: - 料金表

/// 一つのサイズ区分。fares は ShippingZone の rawValue を鍵にした運賃（円、税込）。
struct CarrierRow: Codable, Identifiable {
    /// 3辺合計の上限（センチ）。この値以下ならこの区分。
    let sizeCm: Int
    /// 佐川のラージサイズなど、大型の区分か。
    let isLarge: Bool
    /// 着地ごとの運賃。
    let fares: [String: Int]

    var id: Int { sizeCm }

    func fare(for zone: ShippingZone) -> Int? { fares[zone.rawValue] }
}

/// 一社分の表。
struct CarrierTable: Codable, Identifiable {
    let carrier: Carrier
    /// 3辺合計の上限（センチ）。
    let maxCm: Int
    /// 重さの上限（キロ）。
    let maxKg: Double
    /// 1辺の上限（センチ）。設けていない社は nil。
    let maxLongSideCm: Int?
    let rows: [CarrierRow]

    var id: String { carrier.rawValue }

    /// 3辺合計から区分を選ぶ。上限を超えていれば nil。
    func row(forTotalCm totalCm: Int) -> CarrierRow? {
        rows.first { totalCm <= $0.sizeCm }
    }
}

// MARK: - 表の中身

/// 2026年11月時点で各社が公表している基本運賃（関西発・税込・現金決済）。
///
/// - ヤマト運輸: 2025年10月1日改定の届出運賃。60〜200サイズ、1辺170センチまで。
/// - ゆうパック: 2026年10月1日改定の基本運賃。60〜170サイズ。
/// - 佐川急便: 関西発の料金表。60〜160が飛脚宅配便、170〜260が飛脚ラージサイズ宅配便。
///
/// fares の並びは ShippingZone.allCases（関西、中部・北陸、関東・信越、九州、北海道）と
/// 同じ順で書く。将来は同形式の JSON を読ませて、アプリを更新せずに差し替えられる。
enum ShippingRates {
    /// 表の時点。
    static let updatedLabel = "2026年11月"
    /// 発地。
    static let originLabel = "関西（大阪）発"
    /// 断り書き。
    static let sourceNote = "各社が公表する基本運賃（税込）。割引・契約運賃・離島の中継料は含みません。"

    static let tables: [CarrierTable] = [
        CarrierTable(carrier: .yamato,
                     maxCm: 200,
                     maxKg: 30,
                     maxLongSideCm: 170,
                     rows: [
                        row(60, [940, 940, 1060, 1060, 1920]),
                        row(80, [1230, 1230, 1350, 1350, 2200]),
                        row(100, [1530, 1530, 1650, 1650, 2510]),
                        row(120, [2040, 2040, 2170, 2170, 3120]),
                        row(140, [2630, 2630, 2780, 2780, 3810]),
                        row(160, [3020, 3020, 3160, 3160, 4180]),
                        row(180, [3680, 3680, 4480, 4480, 6820]),
                        row(200, [4470, 4470, 5410, 5410, 8410])
                     ]),
        CarrierTable(carrier: .japanPost,
                     maxCm: 170,
                     maxKg: 25,
                     maxLongSideCm: nil,
                     rows: [
                        row(60, [970, 970, 1090, 1090, 1910]),
                        row(80, [1320, 1320, 1440, 1440, 2240]),
                        row(100, [1650, 1650, 1780, 1780, 2590]),
                        row(120, [2010, 2010, 2130, 2130, 2920]),
                        row(140, [2600, 2600, 2760, 2760, 3610]),
                        row(160, [3000, 3000, 3130, 3130, 4000]),
                        row(170, [3680, 3680, 4500, 4500, 6040])
                     ]),
        CarrierTable(carrier: .sagawa,
                     maxCm: 260,
                     maxKg: 50,
                     maxLongSideCm: nil,
                     rows: [
                        row(60, [910, 910, 1040, 1040, 1820]),
                        row(80, [1220, 1220, 1340, 1340, 2100]),
                        row(100, [1520, 1520, 1630, 1630, 2350]),
                        row(140, [2180, 2180, 2310, 2310, 3090]),
                        row(160, [2440, 2440, 2570, 2570, 3340]),
                        row(170, [2600, 2770, 3360, 3130, 4890], large: true),
                        row(180, [2890, 2950, 3660, 3360, 5480], large: true),
                        row(200, [3480, 3480, 4480, 4070, 6900], large: true),
                        row(220, [4070, 4070, 5240, 4710, 8300], large: true),
                        row(240, [5240, 5240, 6830, 6130, 11070], large: true),
                        row(260, [6420, 6420, 8420, 7480, 13890], large: true)
                     ])
    ]

    static func table(for carrier: Carrier) -> CarrierTable? {
        tables.first { $0.carrier == carrier }
    }

    /// 差し替え用。同じ形の JSON を読む。
    static func decode(_ data: Data) throws -> [CarrierTable] {
        try JSONDecoder().decode([CarrierTable].self, from: data)
    }

    private static func row(_ sizeCm: Int, _ values: [Int], large: Bool = false) -> CarrierRow {
        var fares: [String: Int] = [:]
        for (index, zone) in ShippingZone.allCases.enumerated() where index < values.count {
            fares[zone.rawValue] = values[index]
        }
        return CarrierRow(sizeCm: sizeCm, isLarge: large, fares: fares)
    }
}
