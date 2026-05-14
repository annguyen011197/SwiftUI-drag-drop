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

    private var placeholderIndex: Int? {
        section == .a ? viewModel.placeholderIndex : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section == .a ? "Section A" : "Section B")
                .font(.headline)

            DraggableGridView(
                items: items,
                columns: viewModel.columnCount,
                spacing: viewModel.spacing,
                availableWidth: availableWidth,
                draggingItemId: viewModel.draggingItem?.id,
                placeholderIndex: placeholderIndex,
                content: { item, itemSize in
                    CellView(item: item, section: section, itemSize: itemSize)
                },
                placeholder: { itemSize in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: itemSize, height: itemSize)
                }
            )
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