import SwiftUI

@Observable
class DemoViewModel {
    var itemsA: [GridItem]
    var itemsB: [GridItem]
    var columnCount = 3
    var triggerShake = false

    enum Section { case a, b }

    init() {
        itemsA = [
            GridItem(label: "Red", hue: 0.00),
            GridItem(label: "Orange", hue: 0.08),
            GridItem(label: "Yellow", hue: 0.16),
            GridItem(label: "Green", hue: 0.33),
            GridItem(label: "Blue", hue: 0.58),
            GridItem(label: "Purple", hue: 0.75),
            GridItem(label: "Pink", hue: 0.92),
            GridItem(label: "Brown", hue: 0.07),
        ]
        itemsB = [
            GridItem(label: "Apple", hue: 0.00),
            GridItem(label: "Mango", hue: 0.08),
            GridItem(label: "Lemon", hue: 0.16),
            GridItem(label: "Clover", hue: 0.33),
            GridItem(label: "Gem", hue: 0.55),
            GridItem(label: "Grape", hue: 0.75),
            GridItem(label: "Berry", hue: 0.65),
            GridItem(label: "Cherry", hue: 0.98),
        ]
    }

    func moveItems(_ items: [GridItem], to destination: Section) {
        withAnimation(.spring()) {
            for item in items {
                if let index = itemsA.firstIndex(where: { $0.id == item.id }) {
                    itemsA.remove(at: index)
                } else if let index = itemsB.firstIndex(where: { $0.id == item.id }) {
                    itemsB.remove(at: index)
                }
                switch destination {
                case .a: itemsA.append(item)
                case .b: itemsB.append(item)
                }
            }
        }
    }
}
