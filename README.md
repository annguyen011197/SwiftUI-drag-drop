# DragDrop Module

A reusable SwiftUI drag-and-drop module for iOS 14+. Copy the `DragDrop/` folder into your project and follow this guide.

## Files

| File | Description |
|------|-------------|
| `DragManager.swift` | Generic `ObservableObject` tracking drag position and dragged item |
| `DragContainer.swift` | `ViewModifier` that wraps content in a coordinate space, renders a floating drag preview, and forwards position changes |
| `DropReceiver.swift` | Protocol for defining drop target areas |
| `DropAreaOverlay.swift` | `ViewModifier` + `View` extension that reports a view's frame as a drop target |
| `DragableObject.swift` | `ViewModifier` + `View` extension to make any view draggable with `DragGesture` |

## Quick Start

### 1. Make your model `Dragable`

```swift
struct MyItem: Identifiable, Equatable, Dragable {
    let id: String
    let name: String
}
```

`Dragable` is an empty marker protocol. Your type must also conform to `Equatable` so `DragManager` can track it.

### 2. Create a ViewModel conforming to `DropReceivableObservableObject`

```swift
class MyViewModel: DropReceivableObservableObject {
    typealias DropReceivable = MyDropReceiver

    @Published var items: [MyItem] = []
    @Published var draggingItem: MyItem?

    var dropReceiver = MyDropReceiver()

    func setDropArea(_ dropArea: CGRect, on dropReceiver: MyDropReceiver) {
        // Update dropReceiver with the new frame
        var updated = dropReceiver
        updated.updateDropArea(with: dropArea)
        self.dropReceiver = updated
    }

    func startDragging(item: MyItem) {
        draggingItem = item
    }

    func endDragging(droppedAt position: CGPoint) -> Bool {
        let success = dropReceiver.getDropArea()?.contains(position) ?? false
        // Handle drop logic here
        draggingItem = nil
        return success
    }
}

struct MyDropReceiver: DropReceiver {
    var dropArea: CGRect? = nil
}
```

### 3. Wrap your content in `DragContainer`

```swift
@StateObject private var viewModel = MyViewModel()

var body: some View {
    GeometryReader { geo in
        ScrollView {
            // Your content
        }
        .modifier(DragContainer(
            preview: { (item: MyItem) in
                // Return a view to show as the floating drag preview
                MyItemPreview(item: item)
            },
            onDragPositionChanged: { position in
                // Optional: called continuously as the drag position changes
                // Use this for live drop-target tracking (e.g. placeholder index)
                viewModel.updateDragPosition(position)
            }
        ))
    }
    .environmentObject(viewModel)
}
```

### 4. Mark drop target areas with `.dropReceiver()`

```swift
ScrollView {
    VStack {
        DropTargetSection()
            .dropReceiver(for: viewModel.dropReceiver, model: viewModel)
    }
}
```

This reports the view's frame in the drag coordinate space so you can test `dropArea.contains(position)`.

### 5. Make items draggable with `.dragableObject()`

```swift
MyItemCell(item: item)
    .dragableObject(item,
        onDragStarted: { _ in viewModel.startDragging(item: item) },
        onDrop: { item, position in
            viewModel.endDragging(droppedAt: position)
        }
    )
```

Or with live drag-state feedback:

```swift
MyItemCell(item: item)
    .dragableObject(item,
        onDragStarted: { _ in viewModel.startDragging(item: item) },
        onDragChanged: { item, position in
            // Return a DragState to change the shadow color
            viewModel.isOverDropTarget(position) ? .accepted : .unknown
        },
        onDrop: { item, position in
            viewModel.endDragging(droppedAt: position)
        }
    )
```

## API Reference

### DragManager\<T\>

| Property | Type | Description |
|----------|------|-------------|
| `dragPosition` | `@Published CGPoint` | Current drag location in the named coordinate space |
| `draggedItem` | `@Published T?` | The item currently being dragged (nil when idle) |
| `isDragging` | `Bool` (computed) | `true` when `draggedItem` is non-nil |

### DragContainer\<T, Preview\>

`ViewModifier` that must wrap all draggable/droppable content.

| Parameter | Type | Description |
|-----------|------|-------------|
| `preview` | `(T) -> Preview` | Closure returning the floating drag preview view |
| `onDragPositionChanged` | `((CGPoint) -> Void)?` | Optional callback fired on every drag position change |

### DragState

```swift
public enum DragState {
    case none       // No drag active
    case unknown    // Dragging, not over a valid target
    case accepted   // Dragging over a valid drop target
    case rejected   // Dragging over an invalid target
}
```

Maps to shadow colors on the dragged view: `none` → clear, `unknown` → blue, `accepted` → green, `rejected` → red.

### .dragableObject()

```swift
// Minimal — just start and drop
func dragableObject<T: Equatable>(_ object: T,
    onDragStarted: @escaping (T) -> Void,
    onDrop: @escaping (T, CGPoint) -> Bool) -> some View

// With live drag-state feedback
func dragableObject<T: Equatable>(_ object: T,
    onDragStarted: @escaping (T) -> Void,
    onDragChanged: @escaping (T, CGPoint) -> DragState,
    onDrop: @escaping (T, CGPoint) -> Bool) -> some View
```

| Callback | When called | Return value |
|----------|-------------|--------------|
| `onDragStarted` | First `.onChanged` of the gesture | — |
| `onDragChanged` | Every `.onChanged` while dragging | `DragState` for shadow feedback |
| `onDrop` | On `.onEnded` | `Bool` — whether the drop was successful |

### DropReceiver / DropReceivableObservableObject

```swift
public protocol DropReceiver {
    var dropArea: CGRect? { get set }
    mutating func updateDropArea(with newDropArea: CGRect)
    func getDropArea() -> CGRect?
}

public protocol DropReceivableObservableObject: ObservableObject {
    associatedtype DropReceivable: DropReceiver
    func setDropArea(_ dropArea: CGRect, on dropReceiver: DropReceivable)
}
```

### .dropReceiver()

```swift
func dropReceiver<T: DropReceivableObservableObject>(
    for dropReceiver: T.DropReceivable,
    model: T
) -> some View
```

Attaches a `GeometryReader` overlay that reports the view's frame in the `DragContainer`'s coordinate space. On iOS, it also updates on device rotation.

## Architecture

```
┌─────────────────────────────────────────────┐
│              DragContainer                   │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐  │
│  │ View A  │  │ View B   │  │  Preview   │  │
│  │.draggable│  │.dropZone │  │  (floats)  │  │
│  └─────────┘  └──────────┘  └────────────┘  │
│         ↑            ↑            ↑         │
│    DragableObject  dropReceiver  position   │
│         │            │         from Manager  │
│         └────────────┼────────────┘          │
│                      │                       │
│              DragManager<T>                  │
│         (injected via EnvironmentObject)     │
└─────────────────────────────────────────────┘
```

- **DragContainer** creates a named coordinate space and injects `DragManager` into the environment
- **DragableObject** reads `DragManager` from the environment, sets `draggedItem` and `dragPosition` on drag
- **DragContainer** observes `dragPosition` changes and renders the floating preview
- **dropReceiver** views report their frame so the ViewModel can test `dropArea.contains(position)` for drop logic

## Minimum Requirements

- iOS 14.0+ / SwiftUI 2.0+
- No external dependencies