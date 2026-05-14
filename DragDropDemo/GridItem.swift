import Foundation

struct GridItem: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let hue: Double
    let index: Int

    init(id: String = UUID().uuidString, label: String, hue: Double, index: Int) {
        self.id = id
        self.label = label
        self.hue = hue
        self.index = index
    }
}