import SwiftUI

struct GridItem: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
}

struct ZStackGridView: View {
    let items: [GridItem] = (1...12).map {
        GridItem(title: "Item \($0)", color: [.blue, .green, .orange, .purple].randomElement()!)
    }

    let columns: Int = 3
    let itemWidth: CGFloat = 100
    let itemHeight: CGFloat = 120
    let spacing: CGFloat = 12

    // Tổng chiều cao của ZStack container
    private var totalHeight: CGFloat {
        let rows = CGFloat((items.count + columns - 1) / columns)
        return rows * itemHeight + (rows - 1) * spacing
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Invisible spacer để ZStack có đúng kích thước
                Color.clear
                    .frame(
                        width: CGFloat(columns) * itemWidth + CGFloat(columns - 1) * spacing,
                        height: totalHeight
                    )

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let col = index % columns
                    let row = index / columns

                    let offsetX = CGFloat(col) * (itemWidth + spacing)
                    let offsetY = CGFloat(row) * (itemHeight + spacing)

                    CardView(item: item)
                        .frame(width: itemWidth, height: itemHeight)
                        .offset(x: offsetX, y: offsetY)
                }
            }
            .padding()
        }
    }
}

struct CardView: View {
    let item: GridItem

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(item.color.opacity(0.2))
            .overlay(
                VStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(item.color)
                    Text(item.title)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(item.color.opacity(0.4), lineWidth: 0.5)
            )
    }
}
