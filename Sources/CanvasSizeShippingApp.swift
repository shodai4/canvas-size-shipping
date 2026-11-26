import GoogleMobileAds
import SwiftUI

@main
struct CanvasSizeShippingApp: App {
    @StateObject private var pro = ProStore()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(pro)
                .task { await pro.load() }
                .preferredColorScheme(.light)
        }
    }
}
