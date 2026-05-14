import SwiftUI

struct DragDropDemoView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    SectionView(section: .a, availableWidth: geo.size.width - 32)
                    SectionView(section: .b, availableWidth: geo.size.width - 32)
                }
                .padding()
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
                    CellView(item: item, triggerShake: viewModel.triggerShake)
                        .frame(width: itemSize, height: itemSize)
                        .offset(x: offset.x, y: offset.y)
                }
            }
        }
        .onAppear {
            viewModel.updateOffsets(for: section, items: items, availableWidth: availableWidth)
        }
        .onChange(of: items) { _ in
            viewModel.updateOffsets(for: section, items: items, availableWidth: availableWidth)
        }
        .onChange(of: viewModel.columnCount) { _ in
            viewModel.updateOffsets(for: section, items: items, availableWidth: availableWidth)
        }
    }
}

private struct CellView: View {
    let item: GridItem
    let triggerShake: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hue: item.hue, saturation: 0.4, brightness: 0.9))
            .overlay(
                Text(item.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
            .modifier(ShakeEffect(trigger: triggerShake))
    }
}