import Foundation

final class ClipboardStore {
    private let directoryURL: URL
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    private let saveDebounceNanoseconds: UInt64 = 1_500_000_000

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipStack", isDirectory: true)
        directoryURL = base
        fileURL = base.appendingPathComponent("clipboard-data.json")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func load() -> PersistedData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var persisted = try decoder.decode(PersistedData.self, from: data)
            persisted.items = migrateItems(persisted.items)
            return persisted
        } catch {
            NSLog("ClipStack load failed: \(error.localizedDescription)")
            return .default
        }
    }

    func scheduleSave(_ persisted: PersistedData) {
        saveTask?.cancel()
        let snapshot = prepareForPersistence(persisted)
        saveTask = Task {
            try? await Task.sleep(nanoseconds: saveDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            write(snapshot)
        }
    }

    func saveImmediately(_ persisted: PersistedData) {
        saveTask?.cancel()
        write(prepareForPersistence(persisted))
    }

    private func write(_ persisted: PersistedData) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(persisted)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("ClipStack save failed: \(error.localizedDescription)")
        }
    }

    private func migrateItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.map { item in
            var migrated = item
            migrated.migrateLegacyImageIfNeeded()
            return migrated.withPersistedImage()
        }
    }

    private func prepareForPersistence(_ persisted: PersistedData) -> PersistedData {
        var copy = persisted
        copy.items = persisted.items.map { $0.withPersistedImage() }
        return copy
    }
}
