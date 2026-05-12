import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Drag & Drop\nDemo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            NavigationLink("Start Demo") {
                DragDropDemoView()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .navigationTitle("Home")
    }
}
