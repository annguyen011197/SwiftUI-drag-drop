import SwiftUI

struct GridSection: View {
    let title: String
    let items: [GridItem]
    let section: DemoViewModel.Section
    let columnCount: Int
    let triggerShake: Bool
    let onDrop: ([GridItem]) -> Void

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
                                PlaceholderCell()
                            }
                        }
                    }
                }
            }
        }
        .dropDestination(for: GridItem.self) { droppedItems, _ in
            onDrop(droppedItems)
            return true
        }
    }
}

struct PlaceholderCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .fill(Color.gray.opacity(0.1))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
    }
}
