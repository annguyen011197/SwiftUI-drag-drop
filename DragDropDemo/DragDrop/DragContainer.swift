import SwiftUI

struct DragContainerConstant {
    static let coordinateSpaceID: UUID = UUID()
}

struct DragContainer<T: Equatable, Preview: View>: ViewModifier {
    @StateObject var dragManager: DragManager<T> = .init()

    let preview: (T) -> Preview
    let onDragPositionChanged: ((CGPoint) -> Void)?

    func body(content: Content) -> some View {
        ZStack {
            content
                .coordinateSpace(name: DragContainerConstant.coordinateSpaceID)
                .environmentObject(dragManager)

            if let item = dragManager.draggedItem {
                preview(item)
                    .position(dragManager.dragPosition)
            }
        }
        .onChange(of: dragManager.dragPosition) { newPosition in
            onDragPositionChanged?(newPosition)
        }
    }
}
