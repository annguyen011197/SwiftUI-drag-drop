import SwiftUI

fileprivate
struct RectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

public enum DragState {
    case none
    case unknown
    case accepted
    case rejected
}

//public protocol Dragable { }

private enum DragObjectConstants {
    static let shadowRadius: CGFloat = 10
    static let dragStateChangedDuration: Double = 0.25
    static let dragStateEndedDuration: Double = 0.3
    static let dragColorNone = Color.clear
    static let dragColorUnknown = Color.blue
    static let dragColorAccepted = Color.green
    static let dragColorRejected = Color.red
}

fileprivate class DragObject: ObservableObject {
    @Published var isDraggable: Bool = false
}

fileprivate struct DragHandle: ViewModifier {
    @Environment(\.isDraggableBinding) private var isDraggableBinding
    
    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare() // Optional: reduces latency
        generator.impactOccurred()
    }
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                isDraggableBinding?.wrappedValue = true
                triggerHaptic()
            }
        
    }
}

struct DraggableObject<T: Equatable>: ViewModifier {
    @EnvironmentObject private var dragManager: DragManager<T>
    @State private var dragState: DragState = .none
    @State private var itemRect: CGRect = .zero
    @State private var isDraggable: Bool = false
    
    let object: T
    var onDragStarted: ((T) -> Void)?
    var onDragChanged: ((T, CGPoint) -> DragState)?
    var onDrop: ((T, CGPoint) -> Bool)?
    
    
    
    func body(content: Content) -> some View {
        let longPress = LongPressGesture(minimumDuration: 0.4)
        let dragGlobal = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isDraggable { return }
                dragManager.globalDragPosition = value.location
            }
            .onEnded { value in
                dragManager.globalDragPosition = .zero
            }
        let dragLocal = DragGesture(minimumDistance: 0, coordinateSpace: .named(DragContainerConstant.coordinateSpaceID))
            .onChanged { value in
                if !isDraggable { return }
                if !dragManager.isDragging {
                    dragManager.draggedItem = object
                    onDragStarted?(object)
                }
                dragManager.dragPosition = value.location
                dragManager.draggedItemRect = itemRect
                if let onDragChanged {
                    withAnimation(.linear(duration: DragObjectConstants.dragStateChangedDuration)) {
                        dragState = onDragChanged(object, value.location)
                    }
                }
            }
            .onEnded { value in
                if !isDraggable { return }
                let _ = onDrop?(object, value.location) ?? false
                withAnimation(.linear(duration: DragObjectConstants.dragStateEndedDuration)) {
                    dragState = .none
                }
                isDraggable = false
                dragManager.draggedItem = nil
                dragManager.dragPosition = .zero
                dragManager.draggedItemRect = .zero
            }
        let drag = dragLocal.simultaneously(with: dragGlobal)
        let combined = longPress.sequenced(before: drag)
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: RectPreferenceKey.self, value: geometry.frame(in: .named(DragContainerConstant.coordinateSpaceID)))
                }
                    .onPreferenceChange(RectPreferenceKey.self) { value in
                        DispatchQueue.main.async {
                            self.itemRect = value
                        }
                    }
            )
            .gesture(
                combined
            )
            .environment(\.isDraggableBinding, $isDraggable)
    }
}

private struct IsDraggableKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    var isDraggableBinding: Binding<Bool>? {
        get { self[IsDraggableKey.self] }
        set { self[IsDraggableKey.self] = newValue }
    }
}

extension View {
    public func dragHandle() -> some View {
        modifier(DragHandle())
    }
    
    public func dragHandle<T: Equatable>(_ object: T,
                                         onDragStarted: @escaping (T) -> Void,
                                         onDrop: @escaping (T, CGPoint) -> Bool) -> some View {
        self.dragHandle()
            .modifier(DraggableObject(object: object, onDragStarted: onDragStarted, onDrop: onDrop))
    }
    
    public func draggableObject<T: Equatable>(_ object: T,
                                              onDragStarted: @escaping (T) -> Void,
                                              onDrop: @escaping (T, CGPoint) -> Bool) -> some View {
        modifier(DraggableObject(object: object, onDragStarted: onDragStarted, onDrop: onDrop))
    }
    
    public func draggableObject<T: Equatable>(_ object: T,
                                              onDragStarted: @escaping (T) -> Void,
                                              onDragChanged: @escaping (T, CGPoint) -> DragState,
                                              onDrop: @escaping (T, CGPoint) -> Bool) -> some View {
        modifier(DraggableObject(object: object, onDragStarted: onDragStarted, onDragChanged: onDragChanged, onDrop: onDrop))
    }
}
