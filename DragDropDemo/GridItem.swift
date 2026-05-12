import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct GridItem: Identifiable, Codable, Hashable, Transferable {
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

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
