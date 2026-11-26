import SwiftUI

/// 一つの展示。中の記録を一覧し、点数と送料目安の合計を見る。
struct ExhibitionDetailSheet: View {
    @ObservedObject var store: RecordStore
    let exhibitionID: UUID
    let onRestore: (CalculationConditions) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteRecord: CalculationRecord?
    @State private var deletingRecord: CalculationRecord?
    @State private var isRenaming = false
    @State private var renameName = ""

    private var exhibition: Exhibition? {
        store.exhibition(exhibitionID)
    }

    private var items: [CalculationRecord] {
        store.items(in: exhibitionID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(RecordSummary.summary(items))
                        .font(Theme.mono(10))
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 6)
                        .padding(.bottom, 4)

                    if items.isEmpty {
                        Text("記録の「展示へ」から、この展示に入れられます。")
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    } else {
                        ForEach(items) { record in
                            RecordRow(record: record,
                                      exhibitions: store.exhibitions,
                                      onRestore: {
                                          dismiss()
                                          onRestore(record.conditions)
                                      },
                                      onAssign: { store.assign(record.id, to: $0) },
                                      onNote: { noteRecord = record },
                                      onDelete: { deletingRecord = record })

                            if record.id != items.last?.id {
                                Hairline()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .background(Theme.paper)
            .navigationTitle(exhibition?.name ?? "展示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("名前") {
                        renameName = exhibition?.name ?? ""
                        isRenaming = true
                    }
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkSoft)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .alert("名前を変える", isPresented: $isRenaming) {
                TextField("展示名", text: $renameName)
                Button("変える") {
                    store.renameExhibition(exhibitionID, to: renameName)
                }
                Button("やめる", role: .cancel) { }
            }
            .confirmationDialog("記録を消す", isPresented: deleteBinding, titleVisibility: .visible) {
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
            .sheet(item: $noteRecord) { record in
                RecordNoteSheet(record: record) { text in
                    store.setNote(text, for: record.id)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { deletingRecord != nil },
                set: { if !$0 { deletingRecord = nil } })
    }
}
