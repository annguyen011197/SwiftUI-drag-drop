import SwiftUI

struct ShakeEffect: ViewModifier {
    let trigger: Bool
    @State private var isShaking = false
    @State private var shakeTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isShaking ? 3 : 0))
            .onChange(of: trigger) {
                guard trigger else { return }
                shakeTask?.cancel()
                withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                    isShaking = true
                }
                shakeTask = Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeOut(duration: 0.15)) {
                        isShaking = false
                    }
                }
            }
    }
}
