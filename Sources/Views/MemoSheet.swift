import SwiftUI

/// 号数ごとの作品メモ。端末の中だけに残す。
struct MemoSheet: View {
    let size: CanvasSize
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(size: CanvasSize, initialText: String, onSave: @escaping (String) -> Void) {
        self.size = size
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(size.name)　\(size.dimensions) ミリ")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkFaint)

                TextEditor(text: $text)
                    .font(Theme.label(13))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Theme.paperDeep)
                    .frame(minHeight: 170)

                Text("展示の予定、額の有無、発送先など。")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkFaint)

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
            .navigationTitle("作品メモ")
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
