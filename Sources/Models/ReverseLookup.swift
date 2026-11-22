import Foundation

/// 逆引きの一件。入力した寸法と号数のへだたりを持つ。
struct CanvasMatch: Identifiable {
    let size: CanvasSize
    /// 長辺・短辺それぞれの差の二乗和の平方根（ミリ）。
    let distanceMm: Double

    var id: String { size.id }

    /// 「一致」「差 12」などの表示。
    var distanceText: String {
        if distanceMm < 0.5 { return "一致" }
        return "差 \(Int(distanceMm.rounded()))"
    }

    var isExact: Bool { distanceMm < 0.5 }
}

/// 幅と高さから号数を逆引きする。
///
/// 長辺と短辺の入れ替えは気にしなくてよい。入力を長い順に直してから、
/// 各号数の長辺・短辺との差を比べる。
enum ReverseLookup {
    static func matches(longMm: Double,
                        shortMm: Double,
                        limit: Int = 4,
                        sizes: [CanvasSize] = CanvasCatalog.all) -> [CanvasMatch] {
        guard longMm > 0, shortMm > 0, limit > 0 else { return [] }
        let long = max(longMm, shortMm)
        let short = min(longMm, shortMm)

        // 同距離のときは一覧の順（サムホール、F、P、M、S の順）で並べる。
        var order: [String: Int] = [:]
        for (index, size) in sizes.enumerated() {
            order[size.id] = index
        }

        let all = sizes.map { size -> CanvasMatch in
            let deltaLong = Double(size.longMm) - long
            let deltaShort = Double(size.shortMm) - short
            let distance = (deltaLong * deltaLong + deltaShort * deltaShort).squareRoot()
            return CanvasMatch(size: size, distanceMm: distance)
        }

        let sorted = all.sorted { left, right in
            if abs(left.distanceMm - right.distanceMm) > 0.0001 {
                return left.distanceMm < right.distanceMm
            }
            return (order[left.size.id] ?? 0) < (order[right.size.id] ?? 0)
        }
        return Array(sorted.prefix(limit))
    }

    /// 入力値の長辺と短辺を整える。文字列が読めないときは nil。
    static func normalized(longText: String, shortText: String) -> (long: Double, short: Double)? {
        let first = Double(longText.trimmingCharacters(in: .whitespaces))
        let second = Double(shortText.trimmingCharacters(in: .whitespaces))
        guard let a = first, let b = second, a > 0, b > 0 else { return nil }
        return (max(a, b), min(a, b))
    }
}
