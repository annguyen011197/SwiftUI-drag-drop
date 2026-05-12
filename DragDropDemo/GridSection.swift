import SwiftUI
import UniformTypeIdentifiers

private struct GridFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct GridSection: View {
    let title: String
    let items: [GridItem]
    let section: DemoViewModel.Section
    let columnCount: Int
    let triggerShake: Bool
    let fillsRemainingSpace: Bool
    @Binding var draggedItem: GridItem?
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
                                GridCell(item: item, triggerShake: triggerShake, draggedItem: $draggedItem)
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: GridFramePreferenceKey.self,
                        value: geo.frame(in: .named("grid"))
                    )
                }
            )
            .onPreferenceChange(GridFramePreferenceKey.self) { frame in
                gridFrame = frame
            }
            .padding(fillsRemainingSpace ? 12 : 0)
        }
        .coordinateSpace(name: "grid")
        .contentShape(Rectangle())
        .onDrop(of: [UTType.item], delegate: GridDropDelegate(
            draggedItem: $draggedItem,
            items: items,
            gridFrame: gridFrame,
            columnCount: columnCount,
            onDrop: onDrop
        ))
    }
}

struct GridDropDelegate: DropDelegate {
    @Binding var draggedItem: GridItem?
    let items: [GridItem]
    let gridFrame: CGRect
    let columnCount: Int
    let onDrop: ([GridItem], Int) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        draggedItem != nil
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let item = draggedItem else { return false }
        let point = info.location
        let idx = computeIndex(at: point)
        onDrop([item], idx)
        draggedItem = nil
        return true
    }

    private func computeIndex(at point: CGPoint) -> Int {
        guard gridFrame.width > 0 else { return items.count }
        let spacing: CGFloat = 8
        let cellWidth = (gridFrame.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        let cellHeight = cellWidth
        let row = max(0, Int((point.y - gridFrame.minY) / (cellHeight + spacing)))
        let col = max(0, min(Int((point.x - gridFrame.minX) / (cellWidth + spacing)), columnCount - 1))
        return min(row * columnCount + col, items.count)
    }
}
