import SwiftUI

/// 記録の一件に添える一言メモ。作品名や額の有無など。
struct RecordNoteSheet: View {
    let record: CalculationRecord
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(record: CalculationRecord, onSave: @escaping (String) -> Void) {
        self.record = record
        self.onSave = onSave
        _text = State(initialValue: record.note)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(record.size.name)　\(record.size.dimensions) ミリ ・ \(record.routeText)")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkFaint)

                TextEditor(text: $text)
                    .font(Theme.label(13))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Theme.paperDeep)
                    .frame(minHeight: 150)

                Button {
                    onSave(text)
                    dismiss()
                } label: {
                    Text("保存する")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.ink)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(Theme.paper)
            .navigationTitle("メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
