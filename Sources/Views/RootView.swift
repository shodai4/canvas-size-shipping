import SwiftUI

/// 計算と記録の2つのタブ。記録から選ぶと、条件を計算へ戻す。
@MainActor
struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var store = RecordStore()

    @State private var tab: Tab = .calculate
    @State private var restore: RestoreRequest?

    private enum Tab: Hashable {
        case calculate
        case record
    }

    var body: some View {
        TabView(selection: $tab) {
            ContentView(library: library,
                        store: store,
                        restore: $restore)
                .tabItem {
                    Label("計算", systemImage: "ruler")
                }
                .tag(Tab.calculate)

            RecordView(store: store,
                       onRestore: { conditions in
                           restore = RestoreRequest(conditions: conditions)
                           tab = .calculate
                       })
                .tabItem {
                    Label("記録", systemImage: "rectangle.stack")
                }
                .tag(Tab.record)
        }
        .tint(Theme.accent)
    }
}

/// 記録から計算へ戻す合図。id で同じ条件の再指定も拾う。
struct RestoreRequest: Equatable {
    let id = UUID()
    let conditions: CalculationConditions
}
