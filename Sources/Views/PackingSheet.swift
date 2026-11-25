import SwiftUI

/// 梱包の余裕・厚み・額装と、広告を消す買い切り。
struct PackingSheet: View {
    @Binding var marginMm: Double
    @Binding var thicknessMm: Double
    @Binding var framed: Bool
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionMark(text: "梱包の余裕")
                        .padding(.top, 18)
                    Text("長辺と短辺に足す合計。各辺で半分ずつ緩衝材を入れる想定。")
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    stepperRow(value: $marginMm, range: 0...200, step: 10, unit: "ミリ")

                    SectionMark(text: "厚み")
                        .padding(.top, 22)
                    Text("木枠の厚みと緩衝材を足した、荷物の高さ。")
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    stepperRow(value: $thicknessMm, range: 10...200, step: 10, unit: "ミリ")

                    SectionMark(text: "額装")
                        .padding(.top, 22)
                    HStack {
                        Text("額装ありのときの加算")
                            .font(Theme.label(13))
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 8)
                        Text("長辺・短辺 +30 ／ 厚み +20")
                            .font(Theme.mono(9.5))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.top, 14)

                    HStack {
                        Toggle("額装あり", isOn: $framed)
                            .font(Theme.label(13))
                            .tint(Theme.accent)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 10)

                    SectionMark(text: "広告")
                        .padding(.top, 26)

                    proSection
                        .padding(.top, 12)

                    SectionMark(text: "数値の出どころ")
                        .padding(.top, 26)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("号数の寸法は、全日本画材協議会の支持体サイズ表と画材店各社の一覧で確認した日本サイズ。")
                        Text("運賃は\(ShippingRates.updatedLabel)時点の各社公表値。")
                        Text(ShippingRates.sourceNote)
                    }
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)

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
            .navigationTitle("梱包の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder private var proSection: some View {
        if pro.isPro {
            Text("広告は表示されません。")
                .font(Theme.mono(10))
                .foregroundStyle(Theme.accent)
        } else if pro.canPurchase {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    Task { await pro.purchase() }
                } label: {
                    Text(purchaseLabel)
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Rectangle().stroke(Theme.ink, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task { await pro.restore() }
                } label: {
                    Text("購入を復元する")
                        .font(Theme.mono(9.5))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)

                if let message = pro.message {
                    Text(message)
                        .font(Theme.mono(9.5))
                        .foregroundStyle(Theme.warning)
                }
            }
        }
    }

    private var purchaseLabel: String {
        if let price = pro.displayPrice {
            return "広告を消す　\(price)"
        }
        return "広告を消す"
    }

    private func stepperRow(value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        HStack(spacing: 10) {
            Text("\(Int(value.wrappedValue)) \(unit)")
                .font(Theme.mono(16))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
        .padding(.top, 6)
    }
}
