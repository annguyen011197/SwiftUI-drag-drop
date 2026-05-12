import SwiftUI

struct DragDropDemoView: View {
    @State private var viewModel = DemoViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GridSection(
                    title: "Section A",
                    items: viewModel.itemsA,
                    section: .a,
                    columnCount: viewModel.columnCount,
                    triggerShake: viewModel.triggerShake,
                    onDrop: { viewModel.moveItems($0, to: .a) }
                )
                GridSection(
                    title: "Section B",
                    items: viewModel.itemsB,
                    section: .b,
                    columnCount: viewModel.columnCount,
                    triggerShake: viewModel.triggerShake,
                    onDrop: { viewModel.moveItems($0, to: .b) }
                )
            }
            .padding()
        }
        .navigationTitle("Workspace")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Stepper("Columns: \(viewModel.columnCount)", value: $viewModel.columnCount, in: 2 ... 6)
            }
        }
        .onAppear {
            viewModel.triggerShake = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                viewModel.triggerShake = false
            }
        }
    }
}
