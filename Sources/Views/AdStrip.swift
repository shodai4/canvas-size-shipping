import SwiftUI

/// 画面の下に置く広告の帯。買い切り後は出さない。
struct AdStrip: View {
    @EnvironmentObject private var pro: ProStore

    var body: some View {
        if pro.isPro {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                Hairline()
                BannerAdView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Theme.paper)
            }
        }
    }
}
