import SwiftUI
import UniformTypeIdentifiers

private struct GridSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
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
    let onDrop: (UUID, Int) -> Void

    @State private var gridSize: CGSize = .zero
    @State private var titleHeight: CGFloat = 0

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
        guard gridSize.width > 0 else { return items.count }
        
        let spacing: CGFloat = 8
        let padding: CGFloat = fillsRemainingSpace ? 12 : 0
        let gridTop = titleHeight + spacing + padding
        let cellWidth = (gridSize.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        let cellHeight = cellWidth
        let row = max(0, Int((point.y - gridTop) / (cellHeight + spacing)))
        let col = max(0, min(Int(ceil((point.x - padding) / (cellWidth + spacing))), columnCount - 1))
        print("Cell width = \(cellWidth)")
        print("Drop at \(point) \n row = \(Int((point.y - gridTop) / (cellHeight + spacing))) \n col = \((point.x - padding) / (cellWidth + spacing))")
        return min(row * columnCount + col, items.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: GridSizePreferenceKey.self, value: geo.size)
                    }
                )
                .onPreferenceChange(GridSizePreferenceKey.self) { size in
                    titleHeight = size.height
                }
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
            .background(
                GeometryReader { geo in
//                    Color.clear.preference(key: GridSizePreferenceKey.self, value: geo.size)
                    Color.clear.onAppear {
                        gridSize = geo.size
                    }
                }
            )
//            .onPreferenceChange(GridSizePreferenceKey.self) { size in
//                gridSize = size
//            }
            .padding(fillsRemainingSpace ? 12 : 0)
        }
        .contentShape(Rectangle())
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers, point in
            guard let provider = providers.first else { return false }
            let idx = insertionIndex(at: point)
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                let uuidString: String?
                if let str = data as? String {
                    uuidString = str
                } else if let data = data as? Data {
                    uuidString = String(data: data, encoding: .utf8)
                } else {
                    uuidString = nil
                }
                guard let uuidString, let uuid = UUID(uuidString: uuidString) else { return }
                DispatchQueue.main.async {
                    onDrop(uuid, idx)
                }
            }
            return true
        }
    }
}
