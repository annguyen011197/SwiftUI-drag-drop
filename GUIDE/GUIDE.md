# Integrating Drag and Drop in SwiftUI (iOS 14+)

A step-by-step guide for adding drag-and-drop between grid sections with positional insert, based on the patterns proven in this project.

---

## 1. Data Model

Your model needs `Identifiable`, `Codable`, and `Hashable`. It does **not** need `Transferable` (that's iOS 16+).

```swift
struct GridItem: Identifiable, Codable, Hashable {
    let id: UUID
    let label: String
    let index: Int  // fixed sort key (used by sorted sections)

    init(id: UUID = UUID(), label: String, index: Int) {
        self.id = id
        self.label = label
        self.index = index
    }
}
```

**Why `id` is a `let` UUID:** The UUID is encoded into `NSItemProvider` on drag and decoded on drop. It must be stable — the drop side looks up the item by UUID in the ViewModel.

---

## 2. ViewModel

Use `ObservableObject` + `@Published` (iOS 14 compatible). The ViewModel owns both arrays and the move logic.

```swift
class DemoViewModel: ObservableObject {
    @Published var itemsA: [GridItem] = []
    @Published var itemsB: [GridItem] = []

    enum Section { case a, b }

    func moveItem(id: UUID, to destination: Section, at index: Int) {
        withAnimation(.spring()) {
            var adjustedIndex = index

            // Find and remove from source
            if let srcIndex = itemsA.firstIndex(where: { $0.id == id }) {
                let item = itemsA.remove(at: srcIndex)
                // Same-section reorder: adjust index for removal shift
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
            // Free reorder: insert at computed position
            let clamped = min(index, itemsA.count)
            itemsA.insert(item, at: clamped)
        case .b:
            // Fixed order: append then sort by index property
            itemsB.append(item)
            itemsB.sort { $0.index < $1.index }
        }
    }
}
```

**Key point:** When reordering within the same section, removing an item shifts all indices after it down by 1. If the source index is less than the target index, decrement the target by 1.

---

## 3. Drag Source (GridCell)

Encode the item's UUID into an `NSItemProvider` as plain text. This is the data that flows through the system pasteboard.

```swift
struct GridCell: View {
    let item: GridItem

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue)
            .overlay(Text(item.label).foregroundColor(.white))
            .onDrag {
                NSItemProvider(object: item.id.uuidString as NSString)
            }
    }
}
```

**Why `NSString`:** `NSString` registers as `public.plain-text` (`UTType.plainText`), which the drop side can read on iOS 14+.

---

## 4. Drop Destination (GridSection)

### 4a. Track grid layout dimensions

You need the grid's size and the title's height to compute which cell the drop point lands on. Use `GeometryReader` + `PreferenceKey`:

```swift
private struct GridSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Use separate PreferenceKey types for each measurement to avoid
// the shared-key overwrite bug (see NOTE.md).

struct GridSection: View {
    @State private var gridSize: CGSize = .zero
    @State private var titleHeight: CGFloat = 0

    // ... in body:
    Text(title)
        .background(GeometryReader { geo in
            Color.clear.preference(key: TitleHeightPreferenceKey.self, value: geo.size.height)
        })
        .onPreferenceChange(TitleHeightPreferenceKey.self) { titleHeight = $0 }

    VStack { /* grid rows */ }
        .background(GeometryReader { geo in
            Color.clear.preference(key: GridSizePreferenceKey.self, value: geo.size)
        })
        .onPreferenceChange(GridSizePreferenceKey.self) { gridSize = $0 }
```

> **Warning:** Do not use `.frame(in: .named(...))` — it returns `.zero` on iOS 14. Use `geo.size` instead.

### 4b. Compute insertion index from drop point

```swift
private func insertionIndex(at point: CGPoint) -> Int {
    guard gridSize.width > 0 else { return items.count }
    let spacing: CGFloat = 8
    let gridTop = titleHeight + spacing
    let cellWidth = (gridSize.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
    let cellHeight = cellWidth  // 1:1 aspect ratio

    let row = max(0, Int((point.y - gridTop) / (cellHeight + spacing)))
    let col = max(0, min(Int(ceil((point.x) / (cellWidth + spacing))), columnCount - 1))
    return min(row * columnCount + col, items.count)
}
```

**`ceil()` for column:** The drop point between two cells should snap to the cell on the right (round up).

### 4c. Handle the drop

```swift
.contentShape(Rectangle())  // makes empty space droppable
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
```

**Key details:**
- `UTType.plainText` matches the `NSString` registered by `.onDrag`
- `loadItem` is **asynchronous** — dispatch mutations back to main thread
- `data` can arrive as `String` or `Data` — handle both
- `.contentShape(Rectangle())` makes the entire section area a valid drop target, including empty grid spaces

---

## 5. Wire It Together (Parent View)

```swift
struct DragDropDemoView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        GridSection(
            title: "Section A",
            items: viewModel.itemsA,
            onDrop: { uuid, index in viewModel.moveItem(id: uuid, to: .a, at: index) }
        )
        GridSection(
            title: "Section B",
            items: viewModel.itemsB,
            onDrop: { uuid, index in viewModel.moveItem(id: uuid, to: .b, at: index) }
        )
    }
}
```

No shared `@State draggedItem` needed — data flows through `NSItemProvider`.

---

## 6. Section B: Always Sorted by Index

If a section must maintain a fixed order regardless of where the user drops:

```swift
case .b:
    itemsB.append(item)
    itemsB.sort { $0.index < $1.index }
```

The `index` property on `GridItem` is an immutable sort key. After any drop into Section B, the array re-sorts. The insertion index parameter is ignored.

---

## Checklist

- [ ] Model: `Identifiable`, `Codable`, `Hashable`, stable `UUID` id
- [ ] ViewModel: `ObservableObject`, owns arrays, has `moveItem(id:to:at:)`
- [ ] Drag: `.onDrag { NSItemProvider(object: item.id.uuidString as NSString) }`
- [ ] Drop: `.onDrop(of: [UTType.plainText])` + `loadItem` + `DispatchQueue.main.async`
- [ ] Layout: `GeometryReader` + `PreferenceKey` for sizes (not `.frame(in: .named(...))`)
- [ ] Index: compute from drop point, use `ceil()` for column
- [ ] Hit area: `.contentShape(Rectangle())` on the section container
- [ ] Same-section reorder: adjust target index when source index < target index
- [ ] Fixed-order section: append + sort by `index` property
