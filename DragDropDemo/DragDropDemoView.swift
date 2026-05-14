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
                    .modifier(DragContainer(
                        preview: { (item: GridItem) in
                            CellPreview(item: item)
                                .frame(width: viewModel.itemSize, height: viewModel.itemSize)
                        },
                        onDragPositionChanged: { position in
                            viewModel.updateDragPosition(position)
                        }
                    ))
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
        let realVisible = items.filter { $0.id != viewModel.draggingItem?.id }.count
        let placeholderExtra = (section == .a && viewModel.placeholderIndex != nil) ? 1 : 0
        let count = realVisible + placeholderExtra
        guard count > 0 else { return itemSize }
        let rows = CGFloat((count + viewModel.columnCount - 1) / viewModel.columnCount)
        return rows * itemSize + (rows - 1) * viewModel.spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section == .a ? "Section A" : "Section B")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: totalHeight)

                if section == .a, let pIdx = viewModel.placeholderIndex {
                    let col = pIdx % viewModel.columnCount
                    let row = pIdx / viewModel.columnCount
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: itemSize, height: itemSize)
                        .offset(
                            x: CGFloat(col) * (itemSize + viewModel.spacing),
                            y: CGFloat(row) * (itemSize + viewModel.spacing)
                        )
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let isDragging = viewModel.draggingItem?.id == item.id

                    let visibleIndex = items.prefix(index).filter {
                        $0.id != viewModel.draggingItem?.id
                    }.count

                    let slotIndex: Int = {
                        guard section == .a, let pIdx = viewModel.placeholderIndex, !isDragging else {
                            return visibleIndex
                        }
                        return visibleIndex >= pIdx ? visibleIndex + 1 : visibleIndex
                    }()

                    let offset = CGPoint(
                        x: CGFloat(slotIndex % viewModel.columnCount) * (itemSize + viewModel.spacing),
                        y: CGFloat(slotIndex / viewModel.columnCount) * (itemSize + viewModel.spacing)
                    )

                    CellView(item: item, section: section, itemSize: itemSize)
                        .frame(width: itemSize, height: itemSize)
                        .opacity(isDragging ? 0 : 1)
                        .allowsHitTesting(!isDragging)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.draggingItem?.id)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.placeholderIndex)
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