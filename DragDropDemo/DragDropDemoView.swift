import SwiftUI

struct DragContainerConstant {
    static let coordinateSpaceID: UUID = UUID()
}

struct DragContainer<T: Equatable, Preview: View>: ViewModifier {
    @StateObject var dragManager: DragManager<T> = .init()
    
    @ViewBuilder var preview: (T) -> Preview
    
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
    }
}

struct DragDropDemoView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width - 32
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(spacing: 24) {
                        SectionView(section: .a, availableWidth: width)
                            .dropReceiver(for: viewModel.dropReceiver, model: viewModel)
                        SectionView(section: .b, availableWidth: width)
                        
                    }
                    .padding()
                    .modifier(DragContainer(preview: { (item: GridItem) in
                        CellPreview(item: item)
                            .frame(width: viewModel.itemSize, height: viewModel.itemSize)
                    }))
                }


            }
            .onAppear {
                viewModel.availableWidth = width
            }
            .onChange(of: geo.size.width) { newWidth in
                viewModel.availableWidth = newWidth - 32
            }
        }
        .environmentObject(viewModel)
        .navigationTitle("Workspace")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Stepper("Columns: \(viewModel.columnCount)", value: $viewModel.columnCount, in: 2 ... 6)
            }
        }
        .onAppear {
            viewModel.triggerShake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.triggerShake = false
            }
        }
    }
}



private struct SectionView: View {
    let section: DemoViewModel.Section
    let availableWidth: CGFloat

    @EnvironmentObject private var viewModel: DemoViewModel

    private var items: [GridItem] {
        switch section {
        case .a: return viewModel.itemsA
        case .b: return viewModel.itemsB
        }
    }

    private var offsets: [String: CGPoint] {
        switch section {
        case .a: return viewModel.offsetsA
        case .b: return viewModel.offsetsB
        }
    }

    private var itemSize: CGFloat {
        (availableWidth - CGFloat(viewModel.columnCount - 1) * viewModel.spacing) / CGFloat(viewModel.columnCount)
    }

    private var totalHeight: CGFloat {
        guard !items.isEmpty else { return itemSize }
        let rows = CGFloat((items.count + viewModel.columnCount - 1) / viewModel.columnCount)
        return rows * itemSize + (rows - 1) * viewModel.spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section == .a ? "Section A" : "Section B")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(height: totalHeight)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let offset = offsets[item.id] ?? CGPoint(
                        x: CGFloat(index % viewModel.columnCount) * (itemSize + viewModel.spacing),
                        y: CGFloat(index / viewModel.columnCount) * (itemSize + viewModel.spacing)
                    )
                    CellView(item: item, section: section, itemSize: itemSize)
                        .frame(width: itemSize, height: itemSize)
                        .offset(x: offset.x, y: offset.y)
                        .opacity(viewModel.draggingItemId == item.id ? 0.3 : 1.0)
                }
            }
        }
    }
}

private struct CellPreview: View {
    let item: GridItem

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hue: item.hue, saturation: 0.4, brightness: 0.9))
            .overlay(
                Text(item.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
}

private struct CellView: View {
    let item: GridItem
    let section: DemoViewModel.Section
    let itemSize: CGFloat

    @EnvironmentObject private var viewModel: DemoViewModel
    @EnvironmentObject private var dragManager: DragManager<GridItem>

    var body: some View {
        CellPreview(item: item)
            .modifier(ShakeEffect(trigger: viewModel.triggerShake))
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .named(DragContainerConstant.coordinateSpaceID))
                    .onChanged { value in
                        if !dragManager.isDragging {
                            viewModel.startDragging(item: item, section: section)
                            dragManager.draggedItem = item
                        }
                        dragManager.dragPosition = value.location
                    }
                    .onEnded { value in
                        viewModel.onDropItem(for: item, at: value.location)
                        viewModel.endDragging()
                        dragManager.draggedItem = nil
                        dragManager.dragPosition = .zero
                    }
            )
    }
}
