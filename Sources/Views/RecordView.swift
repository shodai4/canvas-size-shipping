import SwiftUI

/// 記録のタブ。展示ごとのまとめと、未整理の計算履歴。
struct RecordView: View {
    @ObservedObject var store: RecordStore
    let onRestore: (CalculationConditions) -> Void

    @State private var isCreatePresented = false
    @State private var newName = ""
    @State private var renameTarget: Exhibition?
    @State private var renameName = ""
    @State private var openedExhibition: Exhibition?
    @State private var deletingExhibition: Exhibition?
    @State private var deletingRecord: CalculationRecord?
    @State private var noteRecord: CalculationRecord?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if store.exhibitions.isEmpty && store.history.isEmpty {
                        Text("計算すると、ここに履歴が残ります。")
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.top, 10)
                    }

                    exhibitionsSection
                    historySection

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }

            AdStrip()
        }
        .background(Theme.paper)
        .sheet(item: $openedExhibition) { exhibition in
            ExhibitionDetailSheet(store: store,
                                  exhibitionID: exhibition.id,
                                  onRestore: onRestore)
        }
        .sheet(item: $noteRecord) { record in
            RecordNoteSheet(record: record) { text in
                store.setNote(text, for: record.id)
            }
        }
        .alert("展示を追加", isPresented: $isCreatePresented) {
            TextField("展示名", text: $newName)
            Button("追加") {
                store.createExhibition(named: newName)
                newName = ""
            }
            Button("やめる", role: .cancel) {
                newName = ""
            }
        }
        .alert("名前を変える", isPresented: renameBinding) {
            TextField("展示名", text: $renameName)
            Button("変える") {
                if let target = renameTarget {
                    store.renameExhibition(target.id, to: renameName)
                }
                renameTarget = nil
            }
            Button("やめる", role: .cancel) {
                renameTarget = nil
            }
        }
        .confirmationDialog("展示を消す", isPresented: deleteExhibitionBinding, titleVisibility: .visible) {
            Button("消す", role: .destructive) {
                if let target = deletingExhibition {
                    store.deleteExhibition(target.id)
                }
                deletingExhibition = nil
            }
            Button("やめる", role: .cancel) {
                deletingExhibition = nil
            }
        } message: {
            Text("中の記録は未整理に戻ります。")
        }
        .confirmationDialog("記録を消す", isPresented: deleteRecordBinding, titleVisibility: .visible) {
            Button("消す", role: .destructive) {
                if let target = deletingRecord {
                    store.delete(target.id)
                }
                deletingRecord = nil
            }
            Button("やめる", role: .cancel) {
                deletingRecord = nil
            }
        }
    }

    // MARK: - 画面

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("記録")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.inkSoft)
                .tracking(0.5)

            Spacer(minLength: 8)

            Button {
                newName = ""
                isCreatePresented = true
            } label: {
                Text("展示を追加")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder private var exhibitionsSection: some View {
        if !store.exhibitions.isEmpty {
            SectionMark(text: "展示")
                .padding(.top, 16)
                .padding(.bottom, 2)

            ForEach(store.exhibitions) { exhibition in
                exhibitionRow(exhibition)
                if exhibition.id != store.exhibitions.last?.id {
                    Hairline()
                }
            }
        }
    }

    @ViewBuilder private var historySection: some View {
        if !store.history.isEmpty {
            SectionMark(text: "履歴")
                .padding(.top, 24)
                .padding(.bottom, 2)

            ForEach(store.history) { record in
                RecordRow(record: record,
                          exhibitions: store.exhibitions,
                          onRestore: { onRestore(record.conditions) },
                          onAssign: { store.assign(record.id, to: $0) },
                          onNote: { noteRecord = record },
                          onDelete: { deletingRecord = record })
                if record.id != store.history.last?.id {
                    Hairline()
                }
            }
        }
    }

    private func exhibitionRow(_ exhibition: Exhibition) -> some View {
        let items = store.items(in: exhibition.id)
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button {
                openedExhibition = exhibition
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(exhibition.name)
                        .font(Theme.label(13))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(RecordSummary.summary(items))
                        .font(Theme.mono(9))
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkFaint)
                        .lineLimit(1)
                }
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("名前を変える") {
                    renameName = exhibition.name
                    renameTarget = exhibition
                }
                Button("展示を消す", role: .destructive) {
                    deletingExhibition = exhibition
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(width: 26, height: 26)
            }
        }
    }

    // MARK: - 合図

    private var renameBinding: Binding<Bool> {
        Binding(get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })
    }

    private var deleteExhibitionBinding: Binding<Bool> {
        Binding(get: { deletingExhibition != nil },
                set: { if !$0 { deletingExhibition = nil } })
    }

    private var deleteRecordBinding: Binding<Bool> {
        Binding(get: { deletingRecord != nil },
                set: { if !$0 { deletingRecord = nil } })
    }
}

// MARK: - 記録の一行

/// 記録の一行。押すと計算タブへ条件を戻す。
struct RecordRow: View {
    let record: CalculationRecord
    let exhibitions: [Exhibition]
    let onRestore: () -> Void
    let onAssign: (UUID?) -> Void
    let onNote: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Button(action: onRestore) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(record.conditions.size.name)
                            .font(Theme.mono(12, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        if !record.note.isEmpty {
                            Text(record.note)
                                .font(Theme.label(11.5))
                                .foregroundStyle(Theme.inkSoft)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Text(record.fareText ?? "不可")
                            .font(Theme.mono(11))
                            .monospacedDigit()
                            .foregroundStyle(record.fare != nil ? Theme.ink : Theme.warning)
                    }

                    HStack(spacing: 6) {
                        Text(subtitle)
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.inkFaint)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text(RecordSummary.dateText(record.createdAt))
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Menu("展示へ") {
                    ForEach(exhibitions) { exhibition in
                        Button(exhibition.name) {
                            onAssign(exhibition.id)
                        }
                    }
                    if exhibitions.isEmpty {
                        Text("展示がありません")
                    }
                    if record.exhibitionID != nil {
                        Divider()
                        Button("未整理に戻す") {
                            onAssign(nil)
                        }
                    }
                }
                Button(record.note.isEmpty ? "メモを書く" : "メモを直す", action: onNote)
                Divider()
                Button("削除", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(width: 26, height: 30)
            }
        }
    }

    private var subtitle: String {
        var text = "\(record.size.dimensions) ・ \(record.packed.totalCm)cm ・ \(record.routeText)"
        if record.conditions.framed {
            text += " ・ 額装"
        }
        return text
    }
}
