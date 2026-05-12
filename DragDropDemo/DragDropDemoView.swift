import SwiftUI

struct DragDropDemoView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    GridSection(
                        title: "Section A",
                        items: viewModel.itemsA,
                        section: .a,
                        columnCount: viewModel.columnCount,
                        triggerShake: viewModel.triggerShake,
                        fillsRemainingSpace: false,
                        onDrop: { viewModel.moveItem(id: $0, to: .a, at: $1) }
                    )
                    GridSection(
                        title: "Section B",
                        items: viewModel.itemsB,
                        section: .b,
                        columnCount: viewModel.columnCount,
                        triggerShake: viewModel.triggerShake,
                        fillsRemainingSpace: true,
                        onDrop: { viewModel.moveItem(id: $0, to: .b, at: $1) }
                    )
                    .frame(maxHeight: .infinity)
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
