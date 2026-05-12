import Foundation

struct GridItem: Identifiable, Codable, Hashable {
    let id: UUID
    let label: String
    let hue: Double
    let index: Int

    init(id: UUID = UUID(), label: String, hue: Double, index: Int) {
        self.id = id
        self.label = label
        self.hue = hue
        self.index = index
    }
}
