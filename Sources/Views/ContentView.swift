import SwiftUI

/// 計算のタブ。上に入力、中に号数、下に梱包と送料。最下部に広告の帯。
@MainActor
struct ContentView: View {
    @EnvironmentObject private var pro: ProStore
    @ObservedObject var library: LibraryStore
    @ObservedObject var store: RecordStore
    /// 記録から戻す条件。
    @Binding var restore: RestoreRequest?

    @AppStorage("packingMarginMm") private var marginMm: Double = 50
    @AppStorage("packingThicknessMm") private var thicknessMm: Double = 30
    @AppStorage("framed") private var framed: Bool = false
    @AppStorage("shippingOrigin") private var originRaw: String = Prefecture.defaultPlace.rawValue
    @AppStorage("shippingDestination") private var destinationRaw: String = Prefecture.defaultPlace.rawValue

    @State private var longText = ""
    @State private var shortText = ""
    @State private var selected: CanvasSize = CanvasCatalog.size(named: "F6") ?? CanvasCatalog.samHall
    @State private var isLibraryPresented = false
    @State private var isPackingPresented = false
    @State private var isMemoPresented = false
    @State private var isNotesPresented = false
    @State private var pendingRecord: Task<Void, Never>?
    @State private var hasEdited = false
    @State private var lastRestored: CalculationConditions?
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

    private var origin: Prefecture { Prefecture(rawValue: originRaw) ?? Prefecture.defaultPlace }
    private var destination: Prefecture { Prefecture(rawValue: destinationRaw) ?? Prefecture.defaultPlace }

    private var originBinding: Binding<Prefecture> {
        Binding(get: { origin }, set: { originRaw = $0.rawValue })
    }

    private var destinationBinding: Binding<Prefecture> {
        Binding(get: { destination }, set: { destinationRaw = $0.rawValue })
    }

    private var matches: [CanvasMatch] {
        guard let values = ReverseLookup.normalized(longText: longText, shortText: shortText) else {
            return []
        }
        return ReverseLookup.matches(longMm: values.long, shortMm: values.short)
    }

    private var conditions: CalculationConditions {
        CalculationConditions(sizeName: selected.name,
                              marginMm: marginMm,
                              thicknessMm: thicknessMm,
                              framed: framed,
                              origin: originRaw,
                              destination: destinationRaw)
    }

    /// 条件の指紋。どれかが変わったら履歴に残す。
    private var conditionsKey: String {
        "\(selected.name)|\(marginMm)|\(thicknessMm)|\(framed)|\(originRaw)|\(destinationRaw)"
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

                    Hairline()
                        .padding(.top, 18)

                    SizeDetailView(size: $selected,
                                   thicknessMm: packed.thicknessMm,
                                   framed: framed,
                                   isFavorite: library.isFavorite(selected),
                                   memo: library.memo(for: selected),
                                   onToggleFavorite: { library.toggleFavorite(selected) },
                                   onEditMemo: { isMemoPresented = true })
                        .padding(.top, 14)

                    Hairline()
                        .padding(.top, 20)

                    ShippingPanel(packed: packed,
                                  packingSummary: spec.summary,
                                  yacco: spec.yaccoSheet(for: packed),
                                  framed: $framed,
                                  origin: originBinding,
                                  destination: destinationBinding,
                                  onEditPacking: { isPackingPresented = true })
                        .padding(.top, 14)

                    Spacer(minLength: 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .scrollDismissesKeyboard(.interactively)

            AdStrip()
        }
        .background(Theme.paper)
        .onChange(of: longText) { _, _ in adoptBestMatch() }
        .onChange(of: shortText) { _, _ in adoptBestMatch() }
        .onChange(of: conditionsKey) { _, _ in scheduleRecord() }
        .onChange(of: restore?.id) { _, _ in applyRestore() }
        .onDisappear {
            pendingRecord?.cancel()
            if hasEdited {
                store.add(conditions)
            }
        }
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
        .sheet(isPresented: $isNotesPresented) {
            ShippingNotesSheet()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("号数と送料")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.inkSoft)
                .tracking(0.5)

            Spacer(minLength: 8)

            Button {
                isLibraryPresented = true
            } label: {
                Text("一覧")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
            }
            .buttonStyle(.plain)

            Button {
                isNotesPresented = true
            } label: {
                Text("?")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.inkSoft)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("注記")
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("逆引き")
                .font(Theme.mono(9))
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
                .font(Theme.mono(9))
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

    // MARK: - 記録

    /// 条件が落ち着いてから履歴に残す。操作の途中で山ほど残らないようにする。
    private func scheduleRecord() {
        let current = conditions
        if current == lastRestored { return }
        hasEdited = true
        pendingRecord?.cancel()
        pendingRecord = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            store.add(current)
        }
    }

    private func applyRestore() {
        guard let request = restore else { return }
        let conditions = request.conditions
        lastRestored = conditions
        hasEdited = false
        pendingRecord?.cancel()

        longText = ""
        shortText = ""
        focus = nil
        selected = conditions.size
        marginMm = conditions.marginMm
        thicknessMm = conditions.thicknessMm
        framed = conditions.framed
        originRaw = conditions.origin
        destinationRaw = conditions.destination

        restore = nil
    }

    private func adoptBestMatch() {
        if let best = matches.first {
            selected = best.size
        }
    }
}
