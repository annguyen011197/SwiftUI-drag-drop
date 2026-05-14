import SwiftUI

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
                Stepper("Columns: \(viewModel.columnCount)", value: $viewModel.columnCount, in: 2...6)
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

    private var itemSize: CGFloat {
        (availableWidth - CGFloat(viewModel.columnCount - 1) * viewModel.spacing) / CGFloat(viewModel.columnCount)
    }

    private var totalHeight: CGFloat {
        let visibleCount = items.filter { $0.id != viewModel.draggingItem?.id }.count
        guard visibleCount > 0 else { return itemSize }
        let rows = CGFloat((visibleCount + viewModel.columnCount - 1) / viewModel.columnCount)
        return rows * itemSize + (rows - 1) * viewModel.spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section == .a ? "Section A" : "Section B")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: totalHeight)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let visibleIndex = items.prefix(index).filter {
                        $0.id != viewModel.draggingItem?.id
                    }.count

                    let offset = CGPoint(
                        x: CGFloat(visibleIndex % viewModel.columnCount) * (itemSize + viewModel.spacing),
                        y: CGFloat(visibleIndex / viewModel.columnCount) * (itemSize + viewModel.spacing)
                    )
                    let isDragging = viewModel.draggingItem?.id == item.id

                    CellView(item: item, section: section, itemSize: itemSize)
                        .frame(width: itemSize, height: itemSize)
                        .opacity(isDragging ? 0 : 1)
                        .allowsHitTesting(!isDragging)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.draggingItem?.id)
                        .offset(x: offset.x, y: offset.y)
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

    var body: some View {
        CellPreview(item: item)
            .modifier(ShakeEffect(trigger: viewModel.triggerShake))
            .dragableObject(item,
                onDragStarted: { _ in
                    viewModel.startDragging(item: item, section: section)
                },
                onDrop: { item, position in
                    return viewModel.endDragging(droppedAt: position)
                }
            )
    }
}