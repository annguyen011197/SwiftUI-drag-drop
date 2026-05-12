import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct GridItem: Identifiable, Codable, Hashable, Transferable {
    let id: UUID
    let label: String
    let hue: Double

    init(id: UUID = UUID(), label: String, hue: Double) {
        self.id = id
        self.label = label
        self.hue = hue
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
