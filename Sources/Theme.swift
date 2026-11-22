import SwiftUI

// MARK: - 色と書体

/// 画集の奥付のような静けさ。アイボリーの紙、墨の文字、錆青の合図。
enum Theme {
    /// アイボリー #F9F8F5
    static let paper = Color(hex: 0xF9F8F5)
    /// 一段沈んだ紙 #F2F0EA（プレビューの下地、入力欄の下地）
    static let paperDeep = Color(hex: 0xF2F0EA)
    /// 墨色 #1A1A1B
    static let ink = Color(hex: 0x1A1A1B)
    /// 補助の文字。墨の 55%。
    static let inkSoft = Color(hex: 0x1A1A1B).opacity(0.55)
    /// さらに薄い文字。墨の 40%。
    static let inkFaint = Color(hex: 0x1A1A1B).opacity(0.40)
    /// 錆青 #4A6A7A（合図にだけ使う）
    static let accent = Color(hex: 0x4A6A7A)
    /// 罫線。墨の 10%。
    static let hairline = Color(hex: 0x1A1A1B).opacity(0.10)
    /// 大型便の注意。静かな赤。
    static let warning = Color(hex: 0x8C3A32)

    /// 説明の文字。
    static func label(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// 寸法・金額の文字。等幅で、実寸表のように。
    static func mono(_ size: CGFloat = 11, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// 号数の見出し。明朝の細い字。
    static func serif(_ size: CGFloat = 44) -> Font {
        .system(size: size, weight: .light, design: .serif)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - 細い線

/// 高さ 1pt の罫線。
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }
}

/// 節の見出し。小さな等幅の文字と罫線。
struct SectionMark: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.inkFaint)
                .tracking(0.6)
            Hairline()
        }
    }
}
