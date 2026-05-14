class DragManager<T: Equatable>: ObservableObject {
    @Published var dragOffset: CGPoint = .zero
    @Published var isDragging: Bool = false
    @Published var draggingItem: T? = nil
}

struct DragContainer<T: Equatable, Preview: View>: ViewModifier {
    @ViewBuilder let preview: (T) -> Preview
    @StateObject var manager: DragManager<T> = .init()
    func body(content: Content) -> some View {
        ZStack {
            content

            if let item = manager.draggingItem {
                preview(item)
                // modifier to config offset with manager.dragOffset
            }
        }
    }
}

struct ItemValue: Equatable {
    var id: UUID
}

struct MainView: View {
    var body: some View {
        VStack {
            //ContentView
        }
        .modifier(DragContainer(preview: { (item: ItemValue) in
            //PreviewView
        }))
    }
}

struct Item: View {
    @EnvironmentObject var vm: DragManager<ItemValue>
    let item; ItemValue
    var body: some View {
        VStack {

        }
        .gesture(
            DragGesture()
                .onChanged({ value in
                    vm.draggingItem = item
                    vm.dragOffset = value.location
                })
        )
    }
}
