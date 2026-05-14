import SwiftUI

struct DraggableGridView<T: Identifiable, ItemContent: View, PlaceholderContent: View>: View {
    let items: [T]
    let columns: Int
    let spacing: CGFloat
    let availableWidth: CGFloat
    let draggingItemId: T.ID?
    let placeholderIndex: Int?
    let content: (T, CGFloat) -> ItemContent
    let placeholder: (CGFloat) -> PlaceholderContent

    private var itemSize: CGFloat {
        (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
    }

    private var totalHeight: CGFloat {
        let realVisible = items.filter { $0.id != draggingItemId }.count
        let placeholderExtra = placeholderIndex != nil ? 1 : 0
        let count = realVisible + placeholderExtra
        guard count > 0 else { return itemSize }
        let rows = CGFloat((count + columns - 1) / columns)
        return rows * itemSize + (rows - 1) * spacing
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(height: totalHeight)

            if let pIdx = placeholderIndex {
                let col = pIdx % columns
                let row = pIdx / columns
                placeholder(itemSize)
                    .frame(width: itemSize, height: itemSize)
                    .offset(
                        x: CGFloat(col) * (itemSize + spacing),
                        y: CGFloat(row) * (itemSize + spacing)
                    )
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isDragging = item.id == draggingItemId

                let visibleIndex = items.prefix(index).filter {
                    $0.id != draggingItemId
                }.count

                let slotIndex: Int = {
                    guard let pIdx = placeholderIndex, !isDragging else {
                        return visibleIndex
                    }
                    return visibleIndex >= pIdx ? visibleIndex + 1 : visibleIndex
                }()

                let offset = CGPoint(
                    x: CGFloat(slotIndex % columns) * (itemSize + spacing),
                    y: CGFloat(slotIndex / columns) * (itemSize + spacing)
                )

                content(item, itemSize)
                    .frame(width: itemSize, height: itemSize)
                    .opacity(isDragging ? 0 : 1)
                    .allowsHitTesting(!isDragging)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: String(describing: draggingItemId))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: placeholderIndex)
                    .offset(x: offset.x, y: offset.y)
            }
        }
    }
}

extension DraggableGridView where PlaceholderContent == EmptyView {
    init(items: [T],
         columns: Int,
         spacing: CGFloat,
         availableWidth: CGFloat,
         draggingItemId: T.ID?,
         @ViewBuilder content: @escaping (T, CGFloat) -> ItemContent) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.availableWidth = availableWidth
        self.draggingItemId = draggingItemId
        self.placeholderIndex = nil
        self.content = content
        self.placeholder = { _ in EmptyView() }
    }
}