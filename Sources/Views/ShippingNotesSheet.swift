import SwiftUI

/// 計算の画面から逃がした注記。運賃・補償・アート便の条件と公式ページ。
struct ShippingNotesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    group("運賃", lines: [
                        "2026年11月時点の各社公表値（税込）。ヤマトは現金決済、ゆうパックは持込割引後。",
                        "同じ都道府県どうしは県内運賃。北海道・沖縄・離島は中継料や別条件がかかる場合がある。",
                        ShippingRates.sourceNote
                    ])

                    group("補償", lines: [
                        "ヤマトと佐川は、1梱包30万円まで。",
                        "ゆうパックは、セキュリティサービス420円で50万円まで。",
                        "30万円を超える荷物は、ヤマトと佐川では引き受けられない。"
                    ])

                    group("アート便", lines: [
                        "ヤマト 美術便：絵画・彫刻・屏風など。美術品専門のスタッフが梱包から運ぶ。事前予約制で、混載は最短1週間ほど、国内は数万円から。",
                        "佐川 美術品輸送：美術品専用車。学芸員資格を持つスタッフが搬入・展示・撤去まで対応する。",
                        "家財おまかせ便：3辺450cm・最長辺250cm・150kgまで。美術品・骨董品・代替のきかない物は扱わない。",
                        "ヤマトの宅急便は、15号以下の絵画ならアートボックスで送れる。"
                    ])

                    SectionMark(text: "公式ページ")
                        .padding(.top, 24)
                        .padding(.bottom, 4)

                    ForEach(OfficialLinks.pages) { page in
                        Link(destination: page.url) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(page.name)
                                    .font(Theme.label(12))
                                    .foregroundStyle(Theme.ink)
                                Spacer(minLength: 8)
                                Text("↗")
                                    .font(Theme.mono(9))
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if page.id != OfficialLinks.pages.last?.id {
                            Hairline()
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("閉じる")
                            .font(Theme.mono(11))
                            .foregroundStyle(Theme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Theme.ink)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 26)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.paper)
            .navigationTitle("注記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }

    private func group(_ title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionMark(text: title)
                .padding(.top, 18)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(Theme.mono(9.5))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        }
    }
}
