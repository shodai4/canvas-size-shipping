import Foundation

/// お気に入りの号数と、作品ごとのメモ。端末の中だけに置く。
final class LibraryStore: ObservableObject {
    private struct Snapshot: Codable {
        var favorites: [String]
        var memos: [String: String]
    }

    private static let defaultsKey = "canvasLibrary"

    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var memos: [String: String] = [:]

    init() {
        load()
    }

    // MARK: - お気に入り

    func isFavorite(_ size: CanvasSize) -> Bool {
        favoriteIDs.contains(size.id)
    }

    func toggleFavorite(_ size: CanvasSize) {
        if favoriteIDs.contains(size.id) {
            favoriteIDs.remove(size.id)
        } else {
            favoriteIDs.insert(size.id)
        }
        save()
    }

    /// 一覧の順で並べたお気に入り。
    var favoriteSizes: [CanvasSize] {
        CanvasCatalog.all.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - メモ

    func memo(for size: CanvasSize) -> String {
        memos[size.id] ?? ""
    }

    func setMemo(_ text: String, for size: CanvasSize) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            memos.removeValue(forKey: size.id)
        } else {
            memos[size.id] = trimmed
        }
        save()
    }

    // MARK: - 保存

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        favoriteIDs = Set(snapshot.favorites)
        memos = snapshot.memos
    }

    private func save() {
        let snapshot = Snapshot(favorites: favoriteIDs.sorted(), memos: memos)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
