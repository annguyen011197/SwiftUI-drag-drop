import Combine
import SwiftUI

struct DropReceiverArea: DropReceiver {
    var dropArea: CGRect? = nil
}

class DemoViewModel: DropReceivableObservableObject {
    typealias DropReceivable = DropReceiverArea

    @Published var itemsA: [GridItem]
    @Published var itemsB: [GridItem]
    @Published var columnCount = 3
    @Published var triggerShake = false
    @Published var draggingItem: GridItem? = nil
    @Published var placeholderIndex: Int? = nil
    @Published var availableWidth: CGFloat = 0

    private var draggingFromSection: Section? = nil
    private var draggingFromIndex: Int? = nil

    let spacing: CGFloat = 8

    enum Section: String { case a, b }

    init() {
        itemsA = [
            GridItem(label: "Red",    hue: 0.00, index: 0),
            GridItem(label: "Orange", hue: 0.08, index: 1),
            GridItem(label: "Yellow", hue: 0.16, index: 2),
            GridItem(label: "Green",  hue: 0.33, index: 3),
            GridItem(label: "Blue",   hue: 0.58, index: 4),
            GridItem(label: "Purple", hue: 0.75, index: 5),
            GridItem(label: "Pink",   hue: 0.92, index: 6),
            GridItem(label: "Brown",  hue: 0.07, index: 7),
        ]
        itemsB = [
            GridItem(label: "Apple",  hue: 0.00, index: 0),
            GridItem(label: "Mango",  hue: 0.08, index: 1),
            GridItem(label: "Lemon",  hue: 0.16, index: 2),
            GridItem(label: "Clover", hue: 0.33, index: 3),
            GridItem(label: "Gem",    hue: 0.55, index: 4),
            GridItem(label: "Grape",  hue: 0.75, index: 5),
            GridItem(label: "Berry",  hue: 0.65, index: 6),
            GridItem(label: "Cherry", hue: 0.98, index: 7),
        ]
    }

    var itemSize: CGFloat {
        (availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
    }

    var dropReceiver: DropReceiverArea = DropReceiverArea()

    func setDropArea(_ dropArea: CGRect, on dropReceiverArea: DropReceiverArea) {
        dropReceiver.updateDropArea(with: dropArea)
    }

    func startDragging(item: GridItem, section: Section) {
        draggingItem = item
        draggingFromSection = section
        switch section {
        case .a: draggingFromIndex = itemsA.firstIndex(where: { $0.id == item.id })
        case .b: draggingFromIndex = itemsB.firstIndex(where: { $0.id == item.id })
        }
    }

    func updateDragPosition(_ position: CGPoint) {
        guard draggingItem != nil,
              let dropArea = dropReceiver.getDropArea(),
              dropArea.contains(position) else {
            if placeholderIndex != nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    placeholderIndex = nil
                }
            }
            return
        }

        let localX = position.x - dropArea.minX
        let localY = position.y - dropArea.minY

        let col = max(0, min(columnCount - 1, Int(localX / (itemSize + spacing))))
        let row = max(0, Int(localY / (itemSize + spacing)))

        let baseCount = itemsA.filter { $0.id != draggingItem?.id }.count
        let maxIndex = baseCount

        let newIndex = min(row * columnCount + col, maxIndex)

        if newIndex != placeholderIndex {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                placeholderIndex = newIndex
            }
        }
    }

    func endDragging(droppedAt position: CGPoint) -> Bool {
        guard let item = draggingItem,
              let fromSection = draggingFromSection else { return false }

        let success = dropReceiver.getDropArea()?.contains(position) ?? false

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch fromSection {
            case .a: itemsA.removeAll { $0.id == item.id }
            case .b: itemsB.removeAll { $0.id == item.id }
            }

            if success {
                let insertAt = min(placeholderIndex ?? itemsA.count, itemsA.count)
                itemsA.insert(item, at: insertAt)
            } else {
                let fromIndex = draggingFromIndex ?? 0
                switch fromSection {
                case .a: itemsA.insert(item, at: min(fromIndex, itemsA.count))
                case .b: itemsB.insert(item, at: min(fromIndex, itemsB.count))
                }
            }

            placeholderIndex = nil
        }

        draggingItem = nil
        draggingFromSection = nil
        draggingFromIndex = nil
        return success
    }
}