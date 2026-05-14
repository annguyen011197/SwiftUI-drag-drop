import SwiftUI

struct DragDropDemoView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    SectionView(
                        title: "Section A",
                        items: viewModel.itemsA,
                        columnCount: viewModel.columnCount,
                        triggerShake: viewModel.triggerShake
                    )
                    SectionView(
                        title: "Section B",
                        items: viewModel.itemsB,
                        columnCount: viewModel.columnCount,
                        triggerShake: viewModel.triggerShake
                    )
                }
                .frame(minHeight: geo.size.height)
                .padding()
            }
        }
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
    let title: String
    let items: [GridItem]
    let columnCount: Int
    let triggerShake: Bool

    private var columns: [SwiftUI.GridItem] {
        Array(repeating: SwiftUI.GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items) { item in
                        CellView(item: item, triggerShake: triggerShake)
                    }
                }
            }
        }
    }
}

private struct CellView: View {
    let item: GridItem
    let triggerShake: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hue: item.hue, saturation: 0.4, brightness: 0.9))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Text(item.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
            .modifier(ShakeEffect(trigger: triggerShake))
    }
}