import SwiftUI

enum DragContainerlayout {
    case grid, verticalList, horizontalList
}

class DragManager<T: Equatable>: ObservableObject {
    @Published private var _dragPosition: CGPoint = .zero
    var dragPosition: CGPoint {
        set {
            _dragPosition = calculateDragPosition(with: newValue)
        }
        get { _dragPosition }
    }
    @Published var globalDragPosition: CGPoint = .zero {
        didSet {
            
        }
    }
    @Published var draggedItem: T?
    @Published var draggedItemRect: CGRect = CGRect(origin: .zero, size: .zero)
    var draggedItemSize: CGSize {
        draggedItemRect.size
    }
    @Published var enableHapticFeedback: Bool = true
    @Published var layout: DragContainerlayout = .grid
    
    init(enableHapticFeedback: Bool, layout: DragContainerlayout) {
        self.enableHapticFeedback = enableHapticFeedback
        self.layout = layout
    }
    
    var isDragging: Bool {
        draggedItem != nil
    }
    
    private func calculateDragPosition(with position: CGPoint) -> CGPoint {
        return switch layout {
        case .grid: position
        case .verticalList: CGPoint(x: draggedItemRect.origin.x + draggedItemRect.width / 2, y: position.y)
        case .horizontalList: CGPoint(x: position.x, y: draggedItemRect.origin.y + draggedItemRect.height / 2)
        }
    }
}

struct DragContainerConstant {
    static let coordinateSpaceID: UUID = UUID()
}

final class ScrollViewFinderUIView: UIView {
    var onFound: ((UIScrollView) -> Void)?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            var responder: UIView? = self
            while let r = responder {
                if let sv = r as? UIScrollView {
                    self?.onFound?(sv)
                    return
                }
                responder = r.superview
            }
        }
    }
}

struct UIScrollViewFinder: UIViewRepresentable {
    var onFound: (UIScrollView) -> Void
    func makeUIView(context: Context) -> ScrollViewFinderUIView {
        let v = ScrollViewFinderUIView()
        v.onFound = onFound
        return v
    }
    func updateUIView(_ uiView: ScrollViewFinderUIView, context: Context) {}
}

final class AutoScrollController: ObservableObject {
    private weak var scrollView: UIScrollView?
    private var timer: Timer?
    private var currentSpeed: CGFloat = 0
    var scrollViewWindowFrame: CGRect = .zero
    var edgeZone: CGFloat = 80
    var maxSpeed: CGFloat = 14
    
    func attach(_ sv: UIScrollView) { scrollView = sv }
    
    func update(windowY: CGFloat, isDragging: Bool) {
        guard isDragging, !scrollViewWindowFrame.isEmpty else { stop(); return }
        
        let frame = scrollViewWindowFrame
        let distTop    = windowY - frame.minY
        let distBottom = frame.maxY - windowY
        if distTop < edgeZone {
            currentSpeed = -ramp(distTop)
        } else if distBottom < edgeZone {
            currentSpeed = ramp(distBottom)
        } else {
            stop()
            return
        }
        
        guard timer == nil else { return }
        //auto scroll (change contentoffset with 60fps)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self, let sv = self.scrollView else { return }
            let maxY = max(0, sv.contentSize.height - sv.bounds.height + sv.contentInset.bottom)
            let newY = (sv.contentOffset.y + self.currentSpeed).clamped(to: 0...maxY)
            sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: newY), animated: false)
        }
    }
    
    func stop() {
        timer?.invalidate(); timer = nil; currentSpeed = 0
    }
    
    private func ramp(_ distance: CGFloat) -> CGFloat {
        (1 - distance / edgeZone) * maxSpeed
    }
}

extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { Swift.min(Swift.max(self, r.lowerBound), r.upperBound) }
}


struct DraggableScrollView<Content: View, T: Equatable>: View {
    @EnvironmentObject var dragManager: DragManager<T>
    let scrollViewThreshold: CGFloat = 100
    let content: () -> Content
    @State var size: CGSize = .zero
    @StateObject var autoScrollController: AutoScrollController = .init()
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content()
                    .background(
                        UIScrollViewFinder { sv in
                            autoScrollController.attach(sv)
                        }
                            .frame(width: 0, height: 0)
                    )
                    .onChange(of: dragManager.globalDragPosition.y) { newValue in
                        autoScrollController.update(windowY: newValue, isDragging: dragManager.isDragging)
                    }
            }
            .onChangeInitial(of: geo.frame(in: .global)) { newValue in
                autoScrollController.scrollViewWindowFrame = newValue
            }
        }
    }
}

struct DragContainer<T: Equatable, Preview: View>: ViewModifier {
    @StateObject var dragManager: DragManager<T>
    
    let preview: (T) -> Preview
    let onDragPositionChanged: ((CGPoint) -> Void)?
    
    init(
        layout: DragContainerlayout = .grid,
        onDragPositionChanged: ((CGPoint) -> Void)? = nil,
        preview: @escaping (T) -> Preview
    ) {
        self.preview = preview
        self.onDragPositionChanged = onDragPositionChanged
        self._dragManager = .init(wrappedValue: DragManager<T>(enableHapticFeedback: true, layout: layout))
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .coordinateSpace(name: DragContainerConstant.coordinateSpaceID)
                .environmentObject(dragManager)
            
            if let item = dragManager.draggedItem {
                preview(item)
                    .frame(width: dragManager.draggedItemSize.width, height: dragManager.draggedItemSize.height)
                    .position(dragManager.dragPosition)
            }
            
            
        }
        .onChange(of: dragManager.dragPosition) { newPosition in
            onDragPositionChanged?(newPosition)
        }
    }
}
