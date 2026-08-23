import Foundation

final class ImageAssetStore {
    static let shared = ImageAssetStore()

    private let imagesDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipStack", isDirectory: true)
        imagesDirectory = base.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    func relativePath(for itemID: UUID) -> String {
        "images/\(itemID.uuidString).png"
    }

    func saveImage(data: Data, itemID: UUID) -> String? {
        let url = imagesDirectory.appendingPathComponent("\(itemID.uuidString).png")
        do {
            try data.write(to: url, options: .atomic)
            return relativePath(for: itemID)
        } catch {
            NSLog("ClipStack image save failed: \(error.localizedDescription)")
            return nil
        }
    }

    func loadImage(relativePath: String) -> Data? {
        let url = baseURL.appendingPathComponent(relativePath)
        return try? Data(contentsOf: url)
    }

    func loadImage(itemID: UUID) -> Data? {
        loadImage(relativePath: relativePath(for: itemID))
    }

    func deleteImage(relativePath: String) {
        let url = baseURL.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: url)
    }

    func deleteImage(itemID: UUID) {
        deleteImage(relativePath: relativePath(for: itemID))
    }

    private var baseURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipStack", isDirectory: true)
    }
}
