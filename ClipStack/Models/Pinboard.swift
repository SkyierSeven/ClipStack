import Foundation

struct Pinboard: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var itemIDs: [UUID]

    init(id: UUID = UUID(), name: String, itemIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.itemIDs = itemIDs
    }
}
