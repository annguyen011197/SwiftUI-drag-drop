import SwiftUI

struct ShakeEffect: ViewModifier {
    let trigger: Bool
    @State private var isShaking = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isShaking ? 3 : 0))
            .onChange(of: trigger) { newValue in
                guard newValue else { return }
                withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                    isShaking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isShaking = false
                    }
                }
            }
    }
}
