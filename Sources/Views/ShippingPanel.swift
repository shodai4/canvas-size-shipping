import SwiftUI

/// 梱包後の3辺合計、ヤッコ包みの段ボール、発地と着地、三社の区分と運賃、アート便。
struct ShippingPanel: View {
    let packed: PackedSize
    let packingSummary: String
    let yacco: YaccoSheet
    @Binding var framed: Bool
    @Binding var origin: Prefecture
    @Binding var destination: Prefecture
    let onEditPacking: () -> Void

    private var quotes: [ShippingQuote] {
        ShippingCalculator.quotes(totalCm: packed.totalCm,
                                  longSideCm: packed.longSideCm,
                                  origin: origin,
                                  destination: destination)
    }

    private var artSummary: String? {
        ArtDelivery.summary(totalCm: packed.totalCm, longSideCm: packed.longSideCm)
    }

    private var artOptions: [ArtOption] {
        ArtDelivery.options()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("梱包後 3辺合計")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 8)
                Text("\(packed.totalCm)")
                    .font(Theme.mono(30, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text("cm")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.inkSoft)
            }

            Text("\(packed.dimensions) ミリ")
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.inkFaint)

            HStack(spacing: 12) {
                Button(action: onEditPacking) {
                    Text(packingSummary)
                        .font(Theme.mono(9.5))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Toggle("額装あり", isOn: $framed)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
                    .tint(Theme.accent)
                    .controlSize(.small)
                    .fixedSize()
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("段ボール1枚")
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.inkFaint)
                Text(yacco.text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                Text("ミリ")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 6)
                Text("ヤッコ包み")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
            }

            Hairline()

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                placeMenu(title: "発地", selection: $origin)
                Text("→")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkFaint)
                placeMenu(title: "着地", selection: $destination)
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                ForEach(quotes) { quote in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(quote.carrier.name)
                                .font(Theme.label(11.5))
                                .foregroundStyle(Theme.ink)
                            Text(quote.detail)
                                .font(Theme.mono(9))
                                .foregroundStyle(Theme.inkFaint)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            if let fare = quote.fareText {
                                Text(fare)
                                    .font(Theme.mono(13, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                            } else {
                                Text("不可")
                                    .font(Theme.mono(10))
                                    .foregroundStyle(Theme.warning)
                            }
                        }
                        Text(quote.compensationText)
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.vertical, 9)

                    if quote.carrier != quotes.last?.carrier {
                        Hairline()
                    }
                }
            }

            if let artSummary {
                Text(artSummary)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Hairline()

            Text("アート便")
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.inkFaint)
                .tracking(0.6)

            VStack(spacing: 0) {
                ForEach(artOptions) { option in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(option.name)
                                .font(Theme.label(11.5))
                                .foregroundStyle(Theme.ink)
                            Spacer(minLength: 8)
                            Text(option.price)
                                .font(Theme.mono(10))
                                .foregroundStyle(option.price == "対象外" ? Theme.inkFaint : Theme.inkSoft)
                        }
                        Text(option.detail)
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)

                    if option.id != artOptions.last?.id {
                        Hairline()
                    }
                }
            }

            Text(ArtDelivery.note)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(ShippingRates.updatedLabel)時点の基本運賃。ヤマトは現金決済、ゆうパックは持込割引後。")
                Text(ShippingRates.sourceNote)
                Text("北海道・沖縄・離島は中継料や別条件がかかる場合がある。")
                Text("号数のキャンバスは数キロ程度で、重さの上限には通常届かない。")
                Text("各社の料金検索で実運賃を確かめられる。")
            }
            .font(Theme.mono(9))
            .foregroundStyle(Theme.inkFaint)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 発地・着地

    private var areas: [String] {
        var seen: [String] = []
        for prefecture in Prefecture.allCases where !seen.contains(prefecture.area) {
            seen.append(prefecture.area)
        }
        return seen
    }

    private func prefectures(in area: String) -> [Prefecture] {
        Prefecture.allCases.filter { $0.area == area }
    }

    private func placeMenu(title: String, selection: Binding<Prefecture>) -> some View {
        Menu {
            ForEach(areas, id: \.self) { area in
                Section(area) {
                    ForEach(prefectures(in: area)) { prefecture in
                        Button {
                            selection.wrappedValue = prefecture
                        } label: {
                            Text(prefecture.name)
                        }
                    }
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.inkFaint)
                Text(selection.wrappedValue.name)
                    .font(Theme.mono(12, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text("▾")
                    .font(Theme.mono(8))
                    .foregroundStyle(Theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .tint(Theme.ink)
    }
}
