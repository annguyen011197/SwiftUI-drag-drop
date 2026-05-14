import SwiftUI

public enum DragState {
    case none
    case unknown
    case accepted
    case rejected
}

public protocol Dragable { }

private enum DragObjectConstants {
    static let shadowRadius: CGFloat = 10
    static let dragStateChangedDuration: Double = 0.25
    static let dragStateEndedDuration: Double = 0.3
    static let dragColorNone = Color.clear
    static let dragColorUnknown = Color.blue
    static let dragColorAccepted = Color.green
    static let dragColorRejected = Color.red
}

struct DragableObject<T: Equatable>: ViewModifier {
    @EnvironmentObject private var dragManager: DragManager<T>
    @State private var dragState: DragState = .none

    let object: T
    var onDragStarted: ((T) -> Void)?
    var onDragChanged: ((T, CGPoint) -> DragState)?
    var onDrop: ((T, CGPoint) -> Bool)?

    func body(content: Content) -> some View {
        content
            .shadow(color: dragColor, radius: DragObjectConstants.shadowRadius)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .named(DragContainerConstant.coordinateSpaceID))
                    .onChanged { value in
                        if !dragManager.isDragging {
                            dragManager.draggedItem = object
                            onDragStarted?(object)
                        }
                        dragManager.dragPosition = value.location
                        if let onDragChanged {
                            withAnimation(.linear(duration: DragObjectConstants.dragStateChangedDuration)) {
                                dragState = onDragChanged(object, value.location)
                            }
                        }
                    }
                    .onEnded { value in
                        let _ = onDrop?(object, value.location) ?? false
                        withAnimation(.linear(duration: DragObjectConstants.dragStateEndedDuration)) {
                            dragState = .none
                        }
                        dragManager.draggedItem = nil
                        dragManager.dragPosition = .zero
                    }
            )
    }

    private var dragColor: Color {
        switch dragState {
        case .none: return DragObjectConstants.dragColorNone
        case .unknown: return DragObjectConstants.dragColorUnknown
        case .accepted: return DragObjectConstants.dragColorAccepted
        case .rejected: return DragObjectConstants.dragColorRejected
        }
    }
}

extension View {
    public func dragableObject<T: Equatable>(_ object: T,
                                              onDragStarted: @escaping (T) -> Void,
                                              onDrop: @escaping (T, CGPoint) -> Bool) -> some View {
        modifier(DragableObject(object: object, onDragStarted: onDragStarted, onDrop: onDrop))
    }

    public func dragableObject<T: Equatable>(_ object: T,
                                              onDragStarted: @escaping (T) -> Void,
                                              onDragChanged: @escaping (T, CGPoint) -> DragState,
                                              onDrop: @escaping (T, CGPoint) -> Bool) -> some View {
        modifier(DragableObject(object: object, onDragStarted: onDragStarted, onDragChanged: onDragChanged, onDrop: onDrop))
    }
}