import SwiftUI

struct GridSection: View {
    let title: String
    let items: [GridItem]
    let section: DemoViewModel.Section
    let columnCount: Int
    let triggerShake: Bool
    let fillsRemainingSpace: Bool
    let onDrop: ([GridItem], Int) -> Void

    @State private var gridFrame: CGRect = .zero

    private var rows: [[GridItem?]] {
        var result: [[GridItem?]] = []
        let fullRows = items.count / columnCount
        for rowIdx in 0 ..< fullRows {
            result.append(items[rowIdx * columnCount ..< (rowIdx + 1) * columnCount].map { $0 })
        }
        let remainder = items.count % columnCount
        if remainder > 0 {
            var lastRow: [GridItem?] = items[fullRows * columnCount ..< items.count].map { $0 }
            lastRow.append(contentsOf: Array(repeating: nil, count: columnCount - remainder))
            result.append(lastRow)
        }
        if items.isEmpty {
            result.append(Array(repeating: nil, count: columnCount))
        }
        return result
    }

    private func insertionIndex(at point: CGPoint) -> Int {
        guard gridFrame.width > 0 else { return items.count }
        let spacing: CGFloat = 8
        let cellWidth = (gridFrame.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        let cellHeight = cellWidth
        let row = max(0, Int((point.y - gridFrame.minY) / (cellHeight + spacing)))
        let col = max(0, min(Int((point.x - gridFrame.minX) / (cellWidth + spacing)), columnCount - 1))
        return min(row * columnCount + col, items.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 8) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            if let item = cell {
                                GridCell(item: item, triggerShake: triggerShake)
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("grid"))
            } action: { newFrame in
                gridFrame = newFrame
            }
            .padding(fillsRemainingSpace ? 12 : 0)
        }
        .coordinateSpace(name: "grid")
        .contentShape(Rectangle())
        .dropDestination(for: GridItem.self) { droppedItems, session in
            let idx = insertionIndex(at: session.location)
            onDrop(droppedItems, idx)
        }
    }
}
