import SwiftUI

/// 3辺合計、ヤッコ包みの段ボール、発地と着地、三社の運賃、アート便。
/// 文字は最小限にして、数字と罫線で読ませる。
struct ShippingPanel: View {
    let packed: PackedSize
    let packingSummary: String
    let yacco: YaccoSheet
    @Binding var framed: Bool
    @Binding var origin: Prefecture
    @Binding var destination: Prefecture
    let onEditPacking: () -> Void

    /// サイズ・補償の列の幅。行の縦位置を揃える。
    private let sizeColumn: CGFloat = 62
    private let compensationColumn: CGFloat = 70

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

    /// 送れる便のうち、いちばん安い運賃。
    private var lowestFare: Int? {
        quotes.compactMap(\.fare).min()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            totalRow
            Text("\(packed.dimensions) ミリ")
                .font(Theme.mono(9))
                .foregroundStyle(Theme.inkFaint)

            HStack(spacing: 12) {
                Button(action: onEditPacking) {
                    Text(packingSummary)
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Toggle("額装", isOn: $framed)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
                    .tint(Theme.accent)
                    .controlSize(.small)
                    .fixedSize()
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("ヤッコ包み")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
                Text(yacco.text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                Text("ミリ")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 0)
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

            quoteTable

            if let artSummary {
                Text(artSummary)
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Hairline()

            artTable
        }
    }

    // MARK: - 3辺合計

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("3辺合計")
                .font(Theme.mono(9))
                .foregroundStyle(Theme.inkFaint)
            Spacer(minLength: 8)
            Text("\(packed.totalCm)")
                .font(Theme.mono(30, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            Text("cm")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - 三社の一覧

    private var quoteTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("配送")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("サイズ")
                    .frame(width: sizeColumn, alignment: .leading)
                Text("補償")
                    .frame(width: compensationColumn, alignment: .leading)
                Text("運賃")
                    .frame(minWidth: 64, alignment: .trailing)
            }
            .font(Theme.mono(8.5))
            .foregroundStyle(Theme.inkFaint)
            .padding(.bottom, 2)

            ForEach(quotes) { quote in
                quoteRow(quote)
                if quote.carrier != quotes.last?.carrier {
                    Hairline()
                }
            }
        }
    }

    private func quoteRow(_ quote: ShippingQuote) -> some View {
        let isLowest = quote.fare != nil && quote.fare == lowestFare
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Link(destination: quote.carrier.officialURL) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(quote.carrier.name)
                        .font(Theme.label(11.5, weight: isLowest ? .semibold : .regular))
                        .foregroundStyle(isLowest ? Theme.ink : Theme.inkSoft)
                    Text("↗")
                        .font(Theme.mono(8))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(quote.detail)
                .font(Theme.mono(9.5, weight: isLowest ? .medium : .regular))
                .foregroundStyle(isLowest ? Theme.ink : Theme.inkFaint)
                .lineLimit(1)
                .frame(width: sizeColumn, alignment: .leading)

            Text(quote.carrier.compensation)
                .font(Theme.mono(9))
                .foregroundStyle(isLowest ? Theme.inkSoft : Theme.inkFaint)
                .lineLimit(1)
                .frame(width: compensationColumn, alignment: .leading)

            if let fare = quote.fareText {
                Text(fare)
                    .font(Theme.mono(13, weight: isLowest ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isLowest ? Theme.ink : Theme.inkSoft)
                    .frame(minWidth: 64, alignment: .trailing)
            } else {
                Text("不可")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.warning)
                    .frame(minWidth: 64, alignment: .trailing)
            }
        }
        .padding(.vertical, 9)
    }

    // MARK: - アート便

    private var artTable: some View {
        VStack(spacing: 0) {
            ForEach(artOptions) { option in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(option.name)
                        .font(Theme.label(11.5))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                    if let url = option.url {
                        Link(destination: url) {
                            Text(option.label)
                                .font(Theme.mono(10))
                                .foregroundStyle(option.isAvailable ? Theme.accent : Theme.inkFaint)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(option.label)
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                .padding(.vertical, 9)

                if option.id != artOptions.last?.id {
                    Hairline()
                }
            }
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
                    .font(Theme.mono(9))
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
