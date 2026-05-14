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
    @Published var offsetsA: [String: CGPoint] = [:]
    @Published var offsetsB: [String: CGPoint] = [:]
    @Published var draggingItemId: String? = nil
    @Published var draggingSection: Section? = nil
    @Published var sectionOriginA: CGPoint? = nil
    @Published var sectionOriginB: CGPoint? = nil
    @Published var availableWidth: CGFloat = 0

    let spacing: CGFloat = 8

    enum Section: String { case a, b }

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

    var itemSize: CGFloat {
        (availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
    }
    
    var dropReceiver: DropReceiverArea = DropReceiverArea()
    
    func setDropArea(_ dropArea: CGRect, on dropReceiverArea: DropReceiverArea) {
        dropReceiver.updateDropArea(with: dropArea)
    }

    func updateOffsets(for section: Section, items: [GridItem], availableWidth: CGFloat) {
        let itemSize = (availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        var newOffsets: [String: CGPoint] = [:]
        for (index, item) in items.enumerated() {
            let col = index % columnCount
            let row = index / columnCount
            newOffsets[item.id] = CGPoint(
                x: CGFloat(col) * (itemSize + spacing),
                y: CGFloat(row) * (itemSize + spacing)
            )
        }
        withAnimation(.spring()) {
            switch section {
            case .a: offsetsA = newOffsets
            case .b: offsetsB = newOffsets
            }
        }
    }

    func offset(for item: GridItem, in section: Section) -> CGPoint? {
        switch section {
        case .a: return offsetsA[item.id]
        case .b: return offsetsB[item.id]
        }
    }

    func sectionOrigin(for section: Section) -> CGPoint? {
        switch section {
        case .a: return sectionOriginA
        case .b: return sectionOriginB
        }
    }

    func updateSectionOrigin(_ origin: CGPoint, for section: Section) {
        switch section {
        case .a: sectionOriginA = origin
        case .b: sectionOriginB = origin
        }
    }

    func startDragging(item: GridItem, section: Section) {
        draggingItemId = item.id
        draggingSection = section
    }

    func endDragging() {
        draggingItemId = nil
        draggingSection = nil
    }
    
    func onDropItem(for item: GridItem, at position: CGPoint) {
        if let dropReceiver = dropReceiver.getDropArea(), dropReceiver.contains(position) {
            itemsA.append(item)
            itemsB.removeAll {
                $0.id == item.id
            }
        }
    }

    func dropTarget(
        translation: CGSize,
        itemOffset: CGPoint,
        sourceSection: Section
    ) -> (Section, Int) {
        guard let sectionOrigin = sectionOrigin(for: sourceSection) else {
            return (sourceSection, itemsA.count)
        }

        let endX = itemOffset.x + translation.width
        let endY = itemOffset.y + translation.height
        let globalY = sectionOrigin.y + endY

        let rowsA = CGFloat((itemsA.count + columnCount - 1) / max(1, columnCount))
        let sectionAHeight = rowsA * itemSize + (rowsA - 1) * spacing
        let rowsB = CGFloat((itemsB.count + columnCount - 1) / max(1, columnCount))
        let sectionBHeight = rowsB * itemSize + (rowsB - 1) * spacing

        var targetSection = sourceSection
        if let originA = sectionOriginA, let originB = sectionOriginB {
            if globalY >= originB.y && globalY < originB.y + sectionBHeight + 200 {
                targetSection = .b
            } else if globalY >= originA.y && globalY < originA.y + sectionAHeight + 200 {
                targetSection = .a
            }
        }

        let col = max(0, min(Int(ceil(endX / (itemSize + spacing))), columnCount - 1))
        let row = max(0, Int(endY / (itemSize + spacing)))
        let maxIndex = targetSection == .a ? itemsA.count : itemsB.count
        let index = min(row * columnCount + col, maxIndex)

        return (targetSection, index)
    }

    func moveItem(id: String, to destination: Section, at index: Int) {
        withAnimation(.spring()) {
            var adjustedIndex = index

            if let srcIndex = itemsA.firstIndex(where: { $0.id == id }) {
                let item = itemsA.remove(at: srcIndex)
                if destination == .a && srcIndex < adjustedIndex {
                    adjustedIndex -= 1
                }
                insert(item, to: destination, at: adjustedIndex)
            } else if let srcIndex = itemsB.firstIndex(where: { $0.id == id }) {
                let item = itemsB.remove(at: srcIndex)
                insert(item, to: destination, at: adjustedIndex)
            }
        }
    }

    private func insert(_ item: GridItem, to destination: Section, at index: Int) {
        switch destination {
        case .a:
            let clamped = min(index, itemsA.count)
            itemsA.insert(item, at: clamped)
        case .b:
            itemsB.append(item)
            itemsB.sort { $0.index < $1.index }
        }
    }
}
