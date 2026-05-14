import Combine
import SwiftUI

class DemoViewModel: ObservableObject {
    @Published var itemsA: [GridItem]
    @Published var itemsB: [GridItem]
    @Published var columnCount = 3
    @Published var triggerShake = false

    enum Section { case a, b }

    init() {
        itemsA = [
            GridItem(label: "Red", hue: 0.00, index: 0),
            GridItem(label: "Orange", hue: 0.08, index: 1),
            GridItem(label: "Yellow", hue: 0.16, index: 2),
            GridItem(label: "Green", hue: 0.33, index: 3),
            GridItem(label: "Blue", hue: 0.58, index: 4),
            GridItem(label: "Purple", hue: 0.75, index: 5),
            GridItem(label: "Pink", hue: 0.92, index: 6),
            GridItem(label: "Brown", hue: 0.07, index: 7),
        ]
        itemsB = [
            GridItem(label: "Apple", hue: 0.00, index: 0),
            GridItem(label: "Mango", hue: 0.08, index: 1),
            GridItem(label: "Lemon", hue: 0.16, index: 2),
            GridItem(label: "Clover", hue: 0.33, index: 3),
            GridItem(label: "Gem", hue: 0.55, index: 4),
            GridItem(label: "Grape", hue: 0.75, index: 5),
            GridItem(label: "Berry", hue: 0.65, index: 6),
            GridItem(label: "Cherry", hue: 0.98, index: 7),
        ]
    }
}