import SwiftUI

/// 梱包後の3辺合計と、三社のサイズ区分・運賃。
struct ShippingPanel: View {
    let packed: PackedSize
    let packingSummary: String
    @Binding var framed: Bool
    @Binding var zone: ShippingZone
    let onEditPacking: () -> Void

    private var estimates: [ShippingEstimate] {
        ShippingCalculator.estimates(totalCm: packed.totalCm,
                                     longSideCm: packed.longSideCm,
                                     zone: zone)
    }

    private var advisories: [String] {
        ShippingAdvisory.messages(totalCm: packed.totalCm, longSideCm: packed.longSideCm)
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

            Hairline()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(ShippingZone.allCases) { item in
                        zoneButton(item)
                    }
                }
                .padding(.vertical, 2)
            }

            Text(zone.detail)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(estimates) { estimate in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(estimate.carrier.name)
                            .font(Theme.label(11.5))
                            .foregroundStyle(Theme.ink)
                        Text(estimate.detail)
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.inkFaint)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if let fare = estimate.fareText {
                            Text(fare)
                                .font(Theme.mono(13, weight: .medium))
                                .foregroundStyle(Theme.ink)
                        } else {
                            Text("不可")
                                .font(Theme.mono(10))
                                .foregroundStyle(Theme.warning)
                        }
                    }
                    .padding(.vertical, 10)

                    if estimate.carrier != estimates.last?.carrier {
                        Hairline()
                    }
                }
            }

            ForEach(advisories, id: \.self) { message in
                Text(message)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(ShippingRates.originLabel)・\(ShippingRates.updatedLabel)時点の目安")
                Text(ShippingRates.sourceNote)
                Text("大阪府内あては、ゆうパックで近畿の区分より120円安い。")
                Text("北陸・南九州などは、同じ区分の中でも数十円差が出る。")
                Text("号数のキャンバスは数キロ程度で、重さの上限には通常届かない。")
                Text("各社の料金検索で実運賃を確かめられる。")
            }
            .font(Theme.mono(9))
            .foregroundStyle(Theme.inkFaint)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func zoneButton(_ item: ShippingZone) -> some View {
        Button {
            zone = item
        } label: {
            VStack(spacing: 3) {
                Text(item.label)
                    .font(Theme.mono(10, weight: item == zone ? .medium : .regular))
                    .foregroundStyle(item == zone ? Theme.ink : Theme.inkFaint)
                Rectangle()
                    .fill(item == zone ? Theme.ink : Color.clear)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
