import Foundation

/// 計算の履歴と、展示ごとのまとめ。端末の中だけに置く。
///
/// お気に入りと作品メモは `LibraryStore` が持ち、こちらは計算の記録だけを持つ。
/// 保存の形は同じ（UserDefaults に Codable の JSON）で、鍵だけ分けている。
final class RecordStore: ObservableObject {
    private struct Snapshot: Codable {
        var exhibitions: [Exhibition]
        var records: [CalculationRecord]
    }

    private static let defaultsKey = "canvasRecords"

    /// 未整理の履歴として残す上限。展示に入れた記録は数えない。
    static let historyLimit = 80

    @Published private(set) var exhibitions: [Exhibition] = []
    @Published private(set) var records: [CalculationRecord] = []

    init() {
        load()
    }

    // MARK: - 展示

    func exhibition(_ id: UUID?) -> Exhibition? {
        guard let id else { return nil }
        return exhibitions.first { $0.id == id }
    }

    /// 名前で展示を作る。同じ名前があればそれを返す。
    @discardableResult
    func createExhibition(named name: String) -> Exhibition? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = exhibitions.first(where: { $0.name == trimmed }) {
            return existing
        }
        let exhibition = Exhibition(name: trimmed)
        exhibitions.append(exhibition)
        save()
        return exhibition
    }

    func renameExhibition(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = exhibitions.firstIndex(where: { $0.id == id }) else {
            return
        }
        exhibitions[index].name = trimmed
        save()
    }

    /// 展示を消す。中の記録は消さず、未整理の履歴へ戻す。
    func deleteExhibition(_ id: UUID) {
        exhibitions.removeAll { $0.id == id }
        for index in records.indices where records[index].exhibitionID == id {
            records[index].exhibitionID = nil
        }
        save()
    }

    // MARK: - 記録

    /// 新しい順の未整理の履歴。
    var history: [CalculationRecord] {
        records
            .filter { $0.exhibitionID == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 展示に入っている記録。新しい順。
    func items(in exhibitionID: UUID) -> [CalculationRecord] {
        records
            .filter { $0.exhibitionID == exhibitionID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 条件を履歴に残す。同じ条件が未整理にあれば、日時だけ新しくする。
    func add(_ conditions: CalculationConditions) {
        if let index = records.firstIndex(where: { $0.exhibitionID == nil && $0.conditions == conditions }) {
            var record = records.remove(at: index)
            record.createdAt = Date()
            records.insert(record, at: 0)
        } else {
            records.insert(CalculationRecord(conditions: conditions), at: 0)
            trimHistory()
        }
        save()
    }

    func assign(_ recordID: UUID, to exhibitionID: UUID?) {
        guard let index = records.firstIndex(where: { $0.id == recordID }) else { return }
        records[index].exhibitionID = exhibitionID
        save()
    }

    func setNote(_ text: String, for recordID: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = records.firstIndex(where: { $0.id == recordID }) else { return }
        records[index].note = trimmed
        save()
    }

    func delete(_ recordID: UUID) {
        records.removeAll { $0.id == recordID }
        save()
    }

    // MARK: - 保存

    /// 未整理の履歴が上限を超えたら、古いものから落とす。
    private func trimHistory() {
        let unassigned = records
            .filter { $0.exhibitionID == nil }
            .sorted { $0.createdAt > $1.createdAt }
        let overflow = unassigned.dropFirst(Self.historyLimit)
        guard !overflow.isEmpty else { return }
        let dropped = Set(overflow.map(\.id))
        records.removeAll { dropped.contains($0.id) }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        exhibitions = snapshot.exhibitions
        records = snapshot.records
    }

    private func save() {
        let snapshot = Snapshot(exhibitions: exhibitions, records: records)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
