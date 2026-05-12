import SwiftUI

struct GridCell: View {
    let item: GridItem
    let triggerShake: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hue: item.hue, saturation: 0.4, brightness: 0.9))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Text(item.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .draggable(item)
            .modifier(ShakeEffect(trigger: triggerShake))
    }
}
