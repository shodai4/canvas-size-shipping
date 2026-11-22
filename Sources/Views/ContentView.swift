import SwiftUI

/// 上に入力、中に号数、下に梱包と送料。最下部に広告の帯。
@MainActor
struct ContentView: View {
    @EnvironmentObject private var pro: ProStore
    @StateObject private var library = LibraryStore()

    @AppStorage("packingMarginMm") private var marginMm: Double = 50
    @AppStorage("packingThicknessMm") private var thicknessMm: Double = 30
    @AppStorage("framed") private var framed: Bool = false

    @State private var longText = ""
    @State private var shortText = ""
    @State private var selected: CanvasSize = CanvasCatalog.size(named: "F6") ?? CanvasCatalog.samHall
    @State private var zone: ShippingZone = .kansai
    @State private var isLibraryPresented = false
    @State private var isPackingPresented = false
    @State private var isMemoPresented = false
    @FocusState private var focus: Field?

    private enum Field {
        case long
        case short
    }

    // MARK: - 計算

    private var spec: PackingSpec {
        PackingSpec(marginMm: marginMm, thicknessMm: thicknessMm, framed: framed)
    }

    private var packed: PackedSize {
        spec.packed(for: selected)
    }

    private var matches: [CanvasMatch] {
        guard let values = ReverseLookup.normalized(longText: longText, shortText: shortText) else {
            return []
        }
        return ReverseLookup.matches(longMm: values.long, shortMm: values.short)
    }

    // MARK: - 画面

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    inputArea

                    if !matches.isEmpty {
                        matchList
                    }

                    SectionMark(text: "選択中の号数")
                        .padding(.top, 18)
                        .padding(.bottom, 8)

                    SizeDetailView(size: selected,
                                   isFavorite: library.isFavorite(selected),
                                   memo: library.memo(for: selected),
                                   onToggleFavorite: { library.toggleFavorite(selected) },
                                   onEditMemo: { isMemoPresented = true })

                    SectionMark(text: "梱包と送料")
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                    ShippingPanel(packed: packed,
                                  packingSummary: spec.summary,
                                  framed: $framed,
                                  zone: $zone,
                                  onEditPacking: { isPackingPresented = true })

                    Spacer(minLength: 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .scrollDismissesKeyboard(.interactively)

            adArea
        }
        .background(Theme.paper)
        .onChange(of: longText) { _, _ in adoptBestMatch() }
        .onChange(of: shortText) { _, _ in adoptBestMatch() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") { focus = nil }
            }
        }
        .sheet(isPresented: $isLibraryPresented) {
            SizeLibrarySheet(selected: $selected, library: library)
        }
        .sheet(isPresented: $isPackingPresented) {
            PackingSheet(marginMm: $marginMm, thicknessMm: $thicknessMm, framed: $framed)
                .environmentObject(pro)
        }
        .sheet(isPresented: $isMemoPresented) {
            MemoSheet(size: selected,
                      initialText: library.memo(for: selected),
                      onSave: { text in library.setMemo(text, for: selected) })
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("号数と送料")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.inkSoft)
                .tracking(0.5)
            Spacer(minLength: 8)
            Button {
                isLibraryPresented = true
            } label: {
                Text("号数の一覧")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
            }
            .buttonStyle(.plain)

            Button {
                isPackingPresented = true
            } label: {
                Text("梱包の設定")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("寸法から号数を引く")
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.inkFaint)

            HStack(alignment: .bottom, spacing: 20) {
                sizeField(title: "長辺", text: $longText, field: .long)
                sizeField(title: "短辺", text: $shortText, field: .short)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Theme.paperDeep)
    }

    private func sizeField(title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.inkFaint)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                TextField("0", text: text)
                    .font(Theme.mono(24))
                    .foregroundStyle(Theme.ink)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($focus, equals: field)
                Text("ミリ")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)
            }
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var matchList: some View {
        VStack(spacing: 0) {
            ForEach(matches) { match in
                Button {
                    selected = match.size
                    focus = nil
                } label: {
                    HStack(spacing: 8) {
                        Text(match.size.name)
                            .font(Theme.mono(11, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text(match.size.dimensions)
                            .font(Theme.mono(9.5))
                            .foregroundStyle(Theme.inkFaint)
                        Spacer(minLength: 8)
                        Text(match.distanceText)
                            .font(Theme.mono(9.5))
                            .foregroundStyle(match.size.id == selected.id ? Theme.accent : Theme.inkFaint)
                    }
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if match.id != matches.last?.id {
                    Hairline()
                }
            }
        }
        .padding(.top, 10)
    }

    @ViewBuilder private var adArea: some View {
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

    private func adoptBestMatch() {
        if let best = matches.first {
            selected = best.size
        }
    }
}
