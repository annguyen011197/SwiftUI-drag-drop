import Combine
import SwiftUI

class DragManager<T: Equatable>: ObservableObject {
    @Published var dragPosition: CGPoint = .zero
    @Published var draggedItem: T?
    
    var isDragging: Bool {
        draggedItem != nil
    }
}
