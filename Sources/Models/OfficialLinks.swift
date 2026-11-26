import Foundation

/// 各社の公式ページ。計算画面の行や注記から開く。
enum OfficialLinks {
    /// ヤマト運輸 宅急便 料金検索。
    static let yamatoRate = URL(string: "https://date.kuronekoyamato.co.jp/date/Main")!
    /// ヤマト運輸 美術便。
    static let yamatoArt = URL(string: "https://business.kuronekoyamato.co.jp/promotion/art/bijutsubin.html")!
    /// 日本郵便 ゆうパック 運賃計算。
    static let japanPostRate = URL(string: "https://www.post.japanpost.jp/cgi-simulator/youpack.php/")!
    /// 佐川急便 飛脚宅配便。
    static let sagawaRate = URL(string: "https://www.sagawa-exp.co.jp/customer/send/service/takuhai/")!
    /// 佐川急便 美術品輸送。
    static let sagawaArt = URL(string: "https://www.sagawa-exp.co.jp/business/send/service/art/")!
    /// アートセッティングデリバリー（家財おまかせ便）。
    static let artSetting = URL(string: "https://www.008008.jp/transport/")!

    /// 注記に並べる一覧。
    static let pages: [OfficialPage] = [
        OfficialPage(name: "ヤマト 料金検索", url: yamatoRate),
        OfficialPage(name: "ヤマト 美術便", url: yamatoArt),
        OfficialPage(name: "ゆうパック 運賃", url: japanPostRate),
        OfficialPage(name: "佐川 飛脚宅配便", url: sagawaRate),
        OfficialPage(name: "佐川 美術品輸送", url: sagawaArt),
        OfficialPage(name: "家財おまかせ便", url: artSetting)
    ]
}

/// 公式ページの一行。
struct OfficialPage: Identifiable {
    let name: String
    let url: URL

    var id: String { name }
}

extension Carrier {
    /// 運賃を調べる公式ページ。
    var officialURL: URL {
        switch self {
        case .yamato: return OfficialLinks.yamatoRate
        case .japanPost: return OfficialLinks.japanPostRate
        case .sagawa: return OfficialLinks.sagawaRate
        }
    }
}
