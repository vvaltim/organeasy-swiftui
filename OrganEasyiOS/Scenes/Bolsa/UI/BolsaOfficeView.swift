import SwiftUI

struct BolsaOfficeView: View {
    private enum Layout {
        static let cell = CGSize(width: 60, height: 50)
        static let wall: CGFloat = 46
        static let maxScale: CGFloat = 3.5
        static let labelHeight: CGFloat = 22
        static let floorTile = CGSize(width: 32, height: 16)
    }

    let desks: [BolsaDesk]
    let onSelect: (BolsaDesk) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 0

    private var columns: Int { sizeClass == .regular ? 4 : 3 }
    private var rows: Int { max(1, Int((Double(desks.count) / Double(columns)).rounded(.up))) }
    private var cellWidth: CGFloat { width / CGFloat(columns) }
    private var scale: CGFloat { min(cellWidth / Layout.cell.width, Layout.maxScale) }
    private var rowHeight: CGFloat { Layout.cell.height * scale + Layout.labelHeight }
    private var height: CGFloat { Layout.wall * scale + CGFloat(rows) * rowHeight }

    var body: some View {
        ZStack(alignment: .topLeading) {
            floor
            decorations
            if width > 0 {
                TimelineView(.periodic(from: .now, by: 0.6)) { context in
                    let tick = reduceMotion ? false : Int(context.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 1
                    grid(tick: tick)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: max(height, 1))
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func grid(tick: Bool) -> some View {
        ForEach(Array(desks.enumerated()), id: \.element.id) { index, desk in
            let column = index % columns
            let row = index / columns
            Button { onSelect(desk) } label: {
                BolsaDeskView(desk: desk, scale: scale, tick: tick, maxLabelWidth: cellWidth - 4)
            }
            .buttonStyle(.plain)
            .frame(width: cellWidth, height: rowHeight)
            .position(
                x: cellWidth * (CGFloat(column) + 0.5),
                y: Layout.wall * scale + rowHeight * (CGFloat(row) + 0.5)
            )
        }
    }

    private var floor: some View {
        Canvas { context, size in
            let tile = context.resolve(Image("bolsaFloor").interpolation(.none))
            let tileSize = CGSize(width: Layout.floorTile.width * scale, height: (Layout.floorTile.height + 1) * scale)
            let stepX = Layout.floorTile.width * scale
            let stepY = Layout.floorTile.height / 2 * scale
            guard stepX > 0, stepY > 0 else { return }
            var row = 0
            var y = -stepY
            while y < size.height {
                var x = row.isMultiple(of: 2) ? -stepX / 2 : 0
                while x < size.width {
                    context.draw(tile, in: CGRect(origin: CGPoint(x: x, y: y), size: tileSize))
                    x += stepX
                }
                y += stepY
                row += 1
            }
        }
        .background(Color(red: 0.79, green: 0.78, blue: 0.91))
        .accessibilityHidden(true)
    }

    private var decorations: some View {
        HStack(alignment: .bottom) {
            BolsaSprite(name: "bolsaShelf", size: CGSize(width: 28, height: 44), scale: scale)
            Spacer()
            BolsaSprite(name: "bolsaPlant", size: CGSize(width: 20, height: 26), scale: scale)
        }
        .padding(.horizontal, 8 * scale)
        .frame(height: Layout.wall * scale, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

struct BolsaSprite: View {
    let name: String
    let size: CGSize
    let scale: CGFloat

    var body: some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: size.width * scale, height: size.height * scale)
    }
}
