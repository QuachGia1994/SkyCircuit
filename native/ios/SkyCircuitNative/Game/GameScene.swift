import SwiftUI

@MainActor
struct CircuitBoardView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            GeometryReader { proxy in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let frame = engine.renderFrame(at: now)
                    CircuitCanvasRenderer.draw(
                        context: &context,
                        size: size,
                        tiles: engine.tiles,
                        theme: engine.theme,
                        frame: frame,
                        now: now
                    )
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture().onEnded { value in
                        handleTap(value.location, size: proxy.size, now: timeline.date.timeIntervalSinceReferenceDate)
                    }
                )
                .onChange(of: timeline.date) { _, date in
                    engine.advanceFrame(at: date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .aspectRatio(768.0 / 720.0, contentMode: .fit)
        .accessibilityLabel("SkyCircuit circuit board")
        .accessibilityHint("Tap conduit tiles to rotate them")
    }

    private func handleTap(_ point: CGPoint, size: CGSize, now: TimeInterval) {
        guard size.width > 0, size.height > 0 else { return }
        let logicalX = point.x * 768 / size.width
        let logicalY = point.y * 720 / size.height
        let column = Int((logicalX - 96) / 72)
        let row = Int((logicalY - 72) / 72)
        guard row >= 0, row < 8, column >= 0, column < 8 else { return }
        engine.rotateTile(row: row, column: column, at: now)
    }

}

private enum CircuitCanvasRenderer {
    static let logicalSize = CGSize(width: 768, height: 720)
    static let boardOrigin = CGPoint(x: 96, y: 72)
    static let cell: CGFloat = 72

    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        tiles: [CircuitTile],
        theme: CircuitTheme,
        frame: CircuitRenderFrame,
        now: TimeInterval
    ) {
        guard size.width > 0, size.height > 0 else { return }
        context.scaleBy(x: size.width / logicalSize.width, y: size.height / logicalSize.height)
        let palette = CircuitPalette(theme: theme)
        drawBackdrop(context: &context, palette: palette)
        drawChassis(context: &context, palette: palette)
        drawTiles(context: &context, tiles: tiles, palette: palette, frame: frame, now: now)
        drawSources(context: &context, palette: palette, frame: frame, now: now)
        drawRockets(context: &context, palette: palette, frame: frame, now: now)
    }

    private static func drawBackdrop(context: inout GraphicsContext, palette: CircuitPalette) {
        let rect = CGRect(origin: .zero, size: logicalSize)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [palette.backgroundTop, Color(red: 0.025, green: 0.07, blue: 0.15), palette.backgroundBottom]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: logicalSize.height)
            )
        )
        drawNebula(context: &context, center: CGPoint(x: 155, y: 118), radius: 240, color: palette.nebulaA)
        drawNebula(context: &context, center: CGPoint(x: 625, y: 165), radius: 230, color: palette.nebulaB)
        drawStars(context: &context)
        drawSkyline(context: &context, palette: palette)
    }

    private static func drawNebula(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color, color.opacity(0.12), .clear]),
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    private static func drawStars(context: inout GraphicsContext) {
        for index in 0..<78 {
            let x = CGFloat((index * 137 + 29) % 768)
            let y = CGFloat((index * 83 + 17) % 720)
            let radius = 0.7 + CGFloat(index % 4) * 0.28
            let color = index % 7 == 0 ? Color.cyan.opacity(0.72) : Color.white.opacity(0.46)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(color))
            guard index % 13 == 0 else { continue }
            var sparkle = Path()
            sparkle.move(to: CGPoint(x: x - 5, y: y))
            sparkle.addLine(to: CGPoint(x: x + 5, y: y))
            sparkle.move(to: CGPoint(x: x, y: y - 5))
            sparkle.addLine(to: CGPoint(x: x, y: y + 5))
            context.stroke(sparkle, with: .color(.white.opacity(0.45)), lineWidth: 0.7)
        }
    }

    private static func drawSkyline(context: inout GraphicsContext, palette: CircuitPalette) {
        drawTower(context: &context, x: 10, base: 716, height: 170, width: 42, palette: palette)
        drawTower(context: &context, x: 60, base: 716, height: 112, width: 30, palette: palette)
        drawTower(context: &context, x: 704, base: 716, height: 184, width: 44, palette: palette)
        drawTower(context: &context, x: 662, base: 716, height: 120, width: 30, palette: palette)
    }

    private static func drawTower(context: inout GraphicsContext, x: CGFloat, base: CGFloat, height: CGFloat, width: CGFloat, palette: CircuitPalette) {
        var tower = Path()
        tower.move(to: CGPoint(x: x, y: base))
        tower.addLine(to: CGPoint(x: x, y: base - height + 22))
        tower.addLine(to: CGPoint(x: x + width * 0.35, y: base - height + 12))
        tower.addLine(to: CGPoint(x: x + width * 0.5, y: base - height))
        tower.addLine(to: CGPoint(x: x + width * 0.65, y: base - height + 12))
        tower.addLine(to: CGPoint(x: x + width, y: base - height + 22))
        tower.addLine(to: CGPoint(x: x + width, y: base))
        tower.closeSubpath()
        context.fill(tower, with: .color(palette.skyline.opacity(0.9)))
    }

    private static func drawChassis(context: inout GraphicsContext, palette: CircuitPalette) {
        let outer = roundedRect(CGRect(x: 24, y: 38, width: 720, height: 646), radius: 32)
        context.fill(
            outer,
            with: .linearGradient(
                Gradient(colors: [palette.tileEdge, Color(red: 0.065, green: 0.105, blue: 0.16), .black, Color(red: 0.08, green: 0.15, blue: 0.23), palette.tileEdge]),
                startPoint: CGPoint(x: 24, y: 38),
                endPoint: CGPoint(x: 744, y: 684)
            )
        )
        context.stroke(outer, with: .color(.black.opacity(0.92)), lineWidth: 5)
        context.stroke(roundedRect(CGRect(x: 34, y: 48, width: 700, height: 626), radius: 25), with: .color(.cyan.opacity(0.15)), lineWidth: 2)
        context.stroke(roundedRect(CGRect(x: 80, y: 58, width: 608, height: 604), radius: 19), with: .color(.black.opacity(0.72)), lineWidth: 8)
        for point in [CGPoint(x: 40, y: 54), CGPoint(x: 728, y: 54), CGPoint(x: 40, y: 668), CGPoint(x: 728, y: 668)] {
            drawBolt(context: &context, center: point, radius: 5, color: palette.bolt)
        }
    }

    private static func drawTiles(context: inout GraphicsContext, tiles: [CircuitTile], palette: CircuitPalette, frame: CircuitRenderFrame, now: TimeInterval) {
        guard tiles.count >= 64 else { return }
        for row in 0..<8 {
            for column in 0..<8 {
                let cellID = CircuitCell(row: row, column: column)
                drawTile(
                    context: &context,
                    row: row,
                    column: column,
                    tile: tiles[row * 8 + column],
                    palette: palette,
                    frame: frame,
                    hot: frame.powered.contains(cellID) || frame.burning.contains(cellID),
                    now: now
                )
            }
        }
    }

    private static func drawTile(
        context: inout GraphicsContext,
        row: Int,
        column: Int,
        tile: CircuitTile,
        palette: CircuitPalette,
        frame: CircuitRenderFrame,
        hot: Bool,
        now: TimeInterval
    ) {
        let x = boardOrigin.x + CGFloat(column) * cell
        let y = boardOrigin.y + CGFloat(row) * cell
        let rect = CGRect(x: x + 3, y: y + 3, width: cell - 6, height: cell - 6)
        drawPlate(context: &context, rect: rect, palette: palette, hot: hot)
        drawTileBolts(context: &context, x: x, y: y, palette: palette)
        drawConduit(context: &context, center: CGPoint(x: x + cell / 2, y: y + cell / 2), tile: tile, palette: palette, hot: hot, burning: frame.burning.contains(CircuitCell(row: row, column: column)))
        guard frame.burning.contains(CircuitCell(row: row, column: column)) else { return }
        drawBurnHeads(context: &context, row: row, column: column, tile: tile, palette: palette, frame: frame, now: now)
    }

    private static func drawPlate(context: inout GraphicsContext, rect: CGRect, palette: CircuitPalette, hot: Bool) {
        let plate = roundedRect(rect, radius: 9)
        context.fill(
            plate,
            with: .linearGradient(
                Gradient(colors: [palette.tileTop, palette.tile, palette.tileBottom, Color(red: 0.018, green: 0.028, blue: 0.045)]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )
        context.stroke(plate, with: .color(hot ? palette.powered.opacity(0.88) : .black.opacity(0.92)), lineWidth: hot ? 2.4 : 2.2)
        context.stroke(roundedRect(rect.insetBy(dx: 4, dy: 4), radius: 7), with: .color(hot ? palette.powered.opacity(0.35) : .white.opacity(0.10)), lineWidth: 1)
        var lowerEdge = Path()
        lowerEdge.move(to: CGPoint(x: rect.minX + 7, y: rect.maxY - 5))
        lowerEdge.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.maxY - 5))
        context.stroke(lowerEdge, with: .color(.black.opacity(0.58)), lineWidth: 1)
    }

    private static func drawTileBolts(context: inout GraphicsContext, x: CGFloat, y: CGFloat, palette: CircuitPalette) {
        let points = [
            CGPoint(x: x + 11, y: y + 11), CGPoint(x: x + cell - 11, y: y + 11),
            CGPoint(x: x + 11, y: y + cell - 11), CGPoint(x: x + cell - 11, y: y + cell - 11),
        ]
        for point in points { drawBolt(context: &context, center: point, radius: 2.2, color: palette.bolt) }
    }

    private static func drawConduit(context: inout GraphicsContext, center: CGPoint, tile: CircuitTile, palette: CircuitPalette, hot: Bool, burning: Bool) {
        let path = conduitPath(center: center, connections: tile.connections, reach: cell / 2 - 7)
        context.stroke(path, with: .color(.black.opacity(0.82)), style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round))
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [palette.pipeDark, palette.pipeMid, palette.pipeLight, palette.pipeMid, palette.pipeDark]),
                startPoint: CGPoint(x: center.x - 34, y: center.y - 34),
                endPoint: CGPoint(x: center.x + 34, y: center.y + 34)
            ),
            style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round)
        )
        context.stroke(path, with: .color(.white.opacity(0.33)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(palette.copper.opacity(0.5)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        drawCouplers(context: &context, center: center, connections: tile.connections, palette: palette)
        drawHub(context: &context, center: center, connections: tile.connections, palette: palette)
        guard hot else { return }
        let alpha = burning ? 0.72 : 1.0
        context.stroke(path, with: .color(palette.powered.opacity(0.16 * alpha)), style: StrokeStyle(lineWidth: 21, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(palette.powered.opacity(0.95 * alpha)), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(palette.poweredCore), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private static func drawCouplers(context: inout GraphicsContext, center: CGPoint, connections: CircuitDirection, palette: CircuitPalette) {
        for endpoint in endpoints(center: center, connections: connections, reach: cell / 2 - 10) {
            let outer = CGRect(x: endpoint.point.x - 6, y: endpoint.point.y - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: outer), with: .color(palette.copper))
            context.stroke(Path(ellipseIn: outer), with: .color(.black.opacity(0.82)), lineWidth: 1.2)
            context.fill(Path(ellipseIn: outer.insetBy(dx: 3, dy: 3)), with: .color(palette.pipeLight.opacity(0.6)))
        }
    }

    private static func drawHub(context: inout GraphicsContext, center: CGPoint, connections: CircuitDirection, palette: CircuitPalette) {
        guard endpoints(center: center, connections: connections, reach: 1).count >= 3 else { return }
        let rect = CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(Gradient(colors: [palette.pipeLight, palette.pipeMid, palette.pipeDark]), center: center, startRadius: 0, endRadius: 12)
        )
        context.stroke(Path(ellipseIn: rect), with: .color(palette.copper), lineWidth: 2)
        context.fill(Path(ellipseIn: rect.insetBy(dx: 7, dy: 7)), with: .color(Color(red: 0.055, green: 0.08, blue: 0.11)))
    }

    private static func drawSources(context: inout GraphicsContext, palette: CircuitPalette, frame: CircuitRenderFrame, now: TimeInterval) {
        for row in 0..<8 {
            let y = boardOrigin.y + CGFloat(row) * cell + cell / 2
            let hot = frame.powered.contains(CircuitCell(row: row, column: 0)) || frame.burning.contains(CircuitCell(row: row, column: 0))
            drawSourceConnector(context: &context, y: y, palette: palette)
            drawGenerator(context: &context, center: CGPoint(x: 57, y: y), palette: palette, hot: hot, now: now)
        }
    }

    private static func drawSourceConnector(context: inout GraphicsContext, y: CGFloat, palette: CircuitPalette) {
        var line = Path()
        line.move(to: CGPoint(x: 71, y: y))
        line.addLine(to: CGPoint(x: boardOrigin.x + 2, y: y))
        context.stroke(line, with: .color(.black.opacity(0.94)), style: StrokeStyle(lineWidth: 18, lineCap: .round))
        context.stroke(
            line,
            with: .linearGradient(Gradient(colors: [palette.pipeLight, palette.pipeMid, palette.pipeDark]), startPoint: CGPoint(x: 71, y: y - 8), endPoint: CGPoint(x: 71, y: y + 8)),
            style: StrokeStyle(lineWidth: 11, lineCap: .round)
        )
    }

    private static func drawGenerator(context: inout GraphicsContext, center: CGPoint, palette: CircuitPalette, hot: Bool, now: TimeInterval) {
        let housing = CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40)
        context.fill(
            Path(ellipseIn: housing),
            with: .radialGradient(Gradient(colors: [palette.pipeLight, palette.pipeMid, palette.pipeDark, .black]), center: CGPoint(x: center.x - 5, y: center.y - 5), startRadius: 1, endRadius: 22)
        )
        context.stroke(Path(ellipseIn: housing), with: .color(hot ? palette.powered : palette.copper), lineWidth: hot ? 2.8 : 1.8)
        for index in 0..<6 {
            let angle = Double(index) * .pi / 3
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * 16, y: center.y + CGFloat(sin(angle)) * 16)
            drawBolt(context: &context, center: point, radius: 1.8, color: palette.bolt)
        }
        let pulse = hot ? 12 + CGFloat(sin(now * 10)) * 1.5 : 9
        let core = CGRect(x: center.x - pulse, y: center.y - pulse, width: pulse * 2, height: pulse * 2)
        context.fill(Path(ellipseIn: core), with: .radialGradient(Gradient(colors: [.white, palette.poweredCore, hot ? palette.powered : palette.spark, .clear]), center: center, startRadius: 0, endRadius: pulse))
    }

    private static func drawRockets(context: inout GraphicsContext, palette: CircuitPalette, frame: CircuitRenderFrame, now: TimeInterval) {
        for row in 0..<8 {
            let y = boardOrigin.y + CGFloat(row) * cell + cell / 2
            let launching = frame.rocketRows.contains(row)
            let hot = launching || frame.powered.contains(CircuitCell(row: row, column: 7))
            drawRocketFeed(context: &context, y: y, palette: palette, hot: hot)
            drawRocket(context: &context, center: CGPoint(x: 718, y: y - CGFloat(frame.launchProgress) * 27), palette: palette, launching: launching, progress: frame.launchProgress, now: now)
        }
    }

    private static func drawRocketFeed(context: inout GraphicsContext, y: CGFloat, palette: CircuitPalette, hot: Bool) {
        var line = Path()
        line.move(to: CGPoint(x: boardOrigin.x + 8 * cell - 2, y: y))
        line.addLine(to: CGPoint(x: 694, y: y))
        context.stroke(line, with: .color(.black.opacity(0.94)), style: StrokeStyle(lineWidth: 19, lineCap: .round))
        context.stroke(line, with: .color(palette.pipeMid), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        let socket = CGRect(x: 674, y: y - 18, width: 36, height: 36)
        context.fill(Path(ellipseIn: socket), with: .radialGradient(Gradient(colors: [palette.pipeLight, palette.pipeMid, palette.pipeDark, .black]), center: CGPoint(x: 688, y: y - 5), startRadius: 1, endRadius: 19))
        context.stroke(Path(ellipseIn: socket), with: .color(hot ? palette.powered : palette.copper), lineWidth: hot ? 2.8 : 1.8)
        context.fill(Path(ellipseIn: socket.insetBy(dx: 11, dy: 11)), with: .color(hot ? palette.powered : Color(red: 0.055, green: 0.08, blue: 0.11)))
    }

    private static func drawRocket(context: inout GraphicsContext, center: CGPoint, palette: CircuitPalette, launching: Bool, progress: Double, now: TimeInterval) {
        if launching { drawRocketFlame(context: &context, center: center, palette: palette, progress: progress, now: now) }
        var hull = Path()
        hull.move(to: CGPoint(x: center.x, y: center.y - 30))
        hull.addCurve(to: CGPoint(x: center.x + 12, y: center.y + 9), control1: CGPoint(x: center.x + 10, y: center.y - 23), control2: CGPoint(x: center.x + 13, y: center.y - 7))
        hull.addLine(to: CGPoint(x: center.x + 8, y: center.y + 21))
        hull.addLine(to: CGPoint(x: center.x - 8, y: center.y + 21))
        hull.addLine(to: CGPoint(x: center.x - 12, y: center.y + 9))
        hull.addCurve(to: CGPoint(x: center.x, y: center.y - 30), control1: CGPoint(x: center.x - 13, y: center.y - 7), control2: CGPoint(x: center.x - 10, y: center.y - 23))
        context.fill(hull, with: .linearGradient(Gradient(colors: [palette.rocketDark, palette.rocket, palette.rocketLight, palette.rocket, palette.rocketDark]), startPoint: CGPoint(x: center.x - 14, y: center.y), endPoint: CGPoint(x: center.x + 14, y: center.y)))
        context.stroke(hull, with: .color(palette.rocketDark), lineWidth: 1.4)
        drawRocketFins(context: &context, center: center, color: palette.rocketDark)
        let window = CGRect(x: center.x - 6, y: center.y - 14, width: 12, height: 12)
        context.fill(Path(ellipseIn: window), with: .radialGradient(Gradient(colors: [.white, palette.glass, Color(red: 0.02, green: 0.31, blue: 0.55)]), center: CGPoint(x: center.x - 2, y: center.y - 10), startRadius: 0, endRadius: 7))
        context.stroke(Path(ellipseIn: window), with: .color(.white.opacity(0.8)), lineWidth: 1)
    }

    private static func drawRocketFins(context: inout GraphicsContext, center: CGPoint, color: Color) {
        var left = Path()
        left.move(to: CGPoint(x: center.x - 9, y: center.y + 9))
        left.addLine(to: CGPoint(x: center.x - 18, y: center.y + 22))
        left.addLine(to: CGPoint(x: center.x - 8, y: center.y + 18))
        left.closeSubpath()
        context.fill(left, with: .color(color))
        var right = Path()
        right.move(to: CGPoint(x: center.x + 9, y: center.y + 9))
        right.addLine(to: CGPoint(x: center.x + 18, y: center.y + 22))
        right.addLine(to: CGPoint(x: center.x + 8, y: center.y + 18))
        right.closeSubpath()
        context.fill(right, with: .color(color))
    }

    private static func drawRocketFlame(context: inout GraphicsContext, center: CGPoint, palette: CircuitPalette, progress: Double, now: TimeInterval) {
        let flutter = CGFloat(sin(now * 28)) * 4
        let launchStretch = CGFloat(progress) * 13
        var flame = Path()
        flame.move(to: CGPoint(x: center.x - 7, y: center.y + 22))
        flame.addQuadCurve(to: CGPoint(x: center.x, y: center.y + 52 + launchStretch + flutter), control: CGPoint(x: center.x - 11, y: center.y + 35))
        flame.addQuadCurve(to: CGPoint(x: center.x + 7, y: center.y + 22), control: CGPoint(x: center.x + 11, y: center.y + 35))
        flame.closeSubpath()
        context.fill(flame, with: .linearGradient(Gradient(colors: [.white, palette.powered, palette.spark, .clear]), startPoint: CGPoint(x: center.x, y: center.y + 20), endPoint: CGPoint(x: center.x, y: center.y + 66)))
    }

    private static func drawBurnHeads(context: inout GraphicsContext, row: Int, column: Int, tile: CircuitTile, palette: CircuitPalette, frame: CircuitRenderFrame, now: TimeInterval) {
        let center = CGPoint(x: boardOrigin.x + CGFloat(column) * cell + cell / 2, y: boardOrigin.y + CGFloat(row) * cell + cell / 2)
        for point in burnHeadPositions(row: row, column: column, tile: tile, frame: frame, center: center) {
            drawBurnOrb(context: &context, center: point, palette: palette, now: now)
        }
    }

    private static func burnHeadPositions(row: Int, column: Int, tile: CircuitTile, frame: CircuitRenderFrame, center: CGPoint) -> [CGPoint] {
        let points = endpoints(center: center, connections: tile.connections, reach: cell / 2 - 9)
        let incoming = points.filter { burnComesFrom(row: row, column: column, direction: $0.direction, frame: frame) }
        let outgoing = points.filter { burnGoesTo(row: row, column: column, direction: $0.direction, frame: frame) }
        let progress = CGFloat(min(1, max(0, frame.stageProgress)))
        guard !(incoming.isEmpty && outgoing.isEmpty) else { return [center] }
        if incoming.count == 1, outgoing.count == 1 {
            return [quadraticPoint(start: incoming[0].point, control: center, end: outgoing[0].point, t: progress)]
        }
        if progress < 0.5, !incoming.isEmpty { return incoming.map { lerp(start: $0.point, end: center, t: progress * 2) } }
        if !outgoing.isEmpty { return outgoing.map { lerp(start: center, end: $0.point, t: (progress - 0.5) * 2) } }
        return incoming.map { lerp(start: $0.point, end: center, t: progress) }
    }

    private static func burnComesFrom(row: Int, column: Int, direction: CircuitDirection, frame: CircuitRenderFrame) -> Bool {
        if direction == .west, column == 0 { return true }
        guard let neighbor = neighbor(row: row, column: column, direction: direction) else { return false }
        return frame.powered.contains(neighbor)
    }

    private static func burnGoesTo(row: Int, column: Int, direction: CircuitDirection, frame: CircuitRenderFrame) -> Bool {
        if direction == .east, column == 7, frame.rocketRows.contains(row) { return true }
        guard let neighbor = neighbor(row: row, column: column, direction: direction) else { return false }
        return frame.nextStage.contains(neighbor)
    }

    private static func drawBurnOrb(context: inout GraphicsContext, center: CGPoint, palette: CircuitPalette, now: TimeInterval) {
        let pulse = 1 + CGFloat(sin(now * 20)) * 0.1
        let radius = 17 * pulse
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [.white, palette.poweredCore, palette.powered, .clear]), center: center, startRadius: 0, endRadius: radius))
        for index in 0..<5 {
            let angle = now * 5 + Double(index) * .pi * 0.4
            let cosine = CGFloat(cos(angle))
            let sine = CGFloat(sin(angle))
            var ray = Path()
            ray.move(to: CGPoint(x: center.x + cosine * 7, y: center.y + sine * 7))
            ray.addLine(to: CGPoint(x: center.x + cosine * 14, y: center.y + sine * 14))
            context.stroke(ray, with: .color(palette.poweredCore.opacity(0.8)), lineWidth: 1.7)
        }
    }

    private static func drawBolt(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.82)), lineWidth: 0.8)
        var slot = Path()
        slot.move(to: CGPoint(x: center.x - radius * 0.5, y: center.y))
        slot.addLine(to: CGPoint(x: center.x + radius * 0.5, y: center.y))
        context.stroke(slot, with: .color(.black.opacity(0.72)), lineWidth: 0.7)
    }

    private static func conduitPath(center: CGPoint, connections: CircuitDirection, reach: CGFloat) -> Path {
        let points = endpoints(center: center, connections: connections, reach: reach)
        var path = Path()
        guard !points.isEmpty else { return path }
        if points.count == 1 {
            path.move(to: center)
            path.addLine(to: points[0].point)
        } else if points.count == 2, areOpposite(points[0].direction, points[1].direction) {
            path.move(to: points[0].point)
            path.addLine(to: points[1].point)
        } else if points.count == 2 {
            path.move(to: points[0].point)
            path.addQuadCurve(to: points[1].point, control: center)
        } else {
            for endpoint in points {
                path.move(to: center)
                path.addLine(to: endpoint.point)
            }
        }
        return path
    }

    private static func endpoints(center: CGPoint, connections: CircuitDirection, reach: CGFloat) -> [(direction: CircuitDirection, point: CGPoint)] {
        var result: [(CircuitDirection, CGPoint)] = []
        if connections.contains(.north) { result.append((.north, CGPoint(x: center.x, y: center.y - reach))) }
        if connections.contains(.east) { result.append((.east, CGPoint(x: center.x + reach, y: center.y))) }
        if connections.contains(.south) { result.append((.south, CGPoint(x: center.x, y: center.y + reach))) }
        if connections.contains(.west) { result.append((.west, CGPoint(x: center.x - reach, y: center.y))) }
        return result
    }

    private static func neighbor(row: Int, column: Int, direction: CircuitDirection) -> CircuitCell? {
        let cell: CircuitCell
        switch direction {
        case .north: cell = CircuitCell(row: row - 1, column: column)
        case .east: cell = CircuitCell(row: row, column: column + 1)
        case .south: cell = CircuitCell(row: row + 1, column: column)
        default: cell = CircuitCell(row: row, column: column - 1)
        }
        guard cell.row >= 0, cell.row < 8, cell.column >= 0, cell.column < 8 else { return nil }
        return cell
    }

    private static func areOpposite(_ first: CircuitDirection, _ second: CircuitDirection) -> Bool {
        first.opposite == second
    }

    private static func quadraticPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y
        )
    }

    private static func lerp(start: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
    }

    private static func roundedRect(_ rect: CGRect, radius: CGFloat) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
        return path
    }
}

private struct CircuitPalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let nebulaA: Color
    let nebulaB: Color
    let skyline: Color
    let tile: Color
    let tileTop: Color
    let tileBottom: Color
    let tileEdge: Color
    let pipeDark: Color
    let pipeMid: Color
    let pipeLight: Color
    let copper: Color
    let bolt: Color
    let powered: Color
    let poweredCore: Color
    let spark: Color
    let rocket: Color
    let rocketDark: Color
    let rocketLight: Color
    let glass: Color

    init(theme: CircuitTheme) {
        switch theme {
        case .classic:
            self.init(base: .classic)
        case .novaGold:
            self.init(base: .gold)
        case .nebulaViolet:
            self.init(base: .violet)
        case .plasmaChrome:
            self.init(base: .chrome)
        }
    }

    private init(base: BasePalette) {
        backgroundTop = base.backgroundTop
        backgroundBottom = base.backgroundBottom
        nebulaA = base.nebulaA
        nebulaB = base.nebulaB
        skyline = base.skyline
        tile = base.tile
        tileTop = base.tileTop
        tileBottom = base.tileBottom
        tileEdge = base.tileEdge
        pipeDark = base.pipeDark
        pipeMid = base.pipeMid
        pipeLight = base.pipeLight
        copper = base.copper
        bolt = base.bolt
        powered = base.powered
        poweredCore = base.poweredCore
        spark = base.spark
        rocket = base.rocket
        rocketDark = base.rocketDark
        rocketLight = base.rocketLight
        glass = base.glass
    }
}

private struct BasePalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let nebulaA: Color
    let nebulaB: Color
    let skyline: Color
    let tile: Color
    let tileTop: Color
    let tileBottom: Color
    let tileEdge: Color
    let pipeDark: Color
    let pipeMid: Color
    let pipeLight: Color
    let copper: Color
    let bolt: Color
    let powered: Color
    let poweredCore: Color
    let spark: Color
    let rocket: Color
    let rocketDark: Color
    let rocketLight: Color
    let glass: Color

    static let classic = BasePalette(
        backgroundTop: Color(red: 0.02, green: 0.09, blue: 0.19), backgroundBottom: Color(red: 0.008, green: 0.02, blue: 0.055),
        nebulaA: Color(red: 0.12, green: 0.42, blue: 0.92).opacity(0.4), nebulaB: Color(red: 0.38, green: 0.22, blue: 0.78).opacity(0.3), skyline: Color(red: 0.025, green: 0.075, blue: 0.16),
        tile: Color(red: 0.075, green: 0.105, blue: 0.15), tileTop: Color(red: 0.14, green: 0.18, blue: 0.24), tileBottom: Color(red: 0.035, green: 0.052, blue: 0.078), tileEdge: Color(red: 0.22, green: 0.31, blue: 0.42),
        pipeDark: Color(red: 0.075, green: 0.09, blue: 0.12), pipeMid: Color(red: 0.29, green: 0.34, blue: 0.40), pipeLight: Color(red: 0.68, green: 0.76, blue: 0.83), copper: Color(red: 0.64, green: 0.34, blue: 0.12), bolt: Color(red: 0.55, green: 0.62, blue: 0.69),
        powered: Color(red: 1.0, green: 0.48, blue: 0.08), poweredCore: Color(red: 1.0, green: 0.91, blue: 0.48), spark: Color(red: 1.0, green: 0.35, blue: 0.1), rocket: Color(red: 0.98, green: 0.18, blue: 0.56), rocketDark: Color(red: 0.42, green: 0.04, blue: 0.23), rocketLight: Color(red: 1.0, green: 0.55, blue: 0.82), glass: Color(red: 0.18, green: 0.8, blue: 1.0)
    )

    static let gold = BasePalette(
        backgroundTop: Color(red: 0.12, green: 0.07, blue: 0.015), backgroundBottom: Color(red: 0.035, green: 0.02, blue: 0.008), nebulaA: .orange.opacity(0.28), nebulaB: .yellow.opacity(0.16), skyline: Color(red: 0.12, green: 0.065, blue: 0.02),
        tile: Color(red: 0.12, green: 0.085, blue: 0.045), tileTop: Color(red: 0.24, green: 0.16, blue: 0.07), tileBottom: Color(red: 0.045, green: 0.03, blue: 0.015), tileEdge: Color(red: 0.48, green: 0.3, blue: 0.08), pipeDark: Color(red: 0.15, green: 0.09, blue: 0.025), pipeMid: Color(red: 0.55, green: 0.32, blue: 0.07), pipeLight: Color(red: 1.0, green: 0.72, blue: 0.28), copper: Color(red: 0.88, green: 0.48, blue: 0.08), bolt: Color(red: 0.8, green: 0.64, blue: 0.33), powered: .orange, poweredCore: .yellow, spark: Color(red: 1, green: 0.25, blue: 0.04), rocket: Color(red: 1, green: 0.55, blue: 0.05), rocketDark: Color(red: 0.46, green: 0.18, blue: 0.01), rocketLight: Color(red: 1, green: 0.85, blue: 0.36), glass: Color(red: 1, green: 0.78, blue: 0.26)
    )

    static let violet = BasePalette(
        backgroundTop: Color(red: 0.08, green: 0.025, blue: 0.17), backgroundBottom: Color(red: 0.02, green: 0.008, blue: 0.06), nebulaA: .purple.opacity(0.38), nebulaB: .pink.opacity(0.2), skyline: Color(red: 0.08, green: 0.025, blue: 0.13),
        tile: Color(red: 0.10, green: 0.055, blue: 0.14), tileTop: Color(red: 0.19, green: 0.10, blue: 0.28), tileBottom: Color(red: 0.04, green: 0.02, blue: 0.07), tileEdge: Color(red: 0.40, green: 0.20, blue: 0.58), pipeDark: Color(red: 0.11, green: 0.04, blue: 0.16), pipeMid: Color(red: 0.42, green: 0.15, blue: 0.58), pipeLight: Color(red: 0.78, green: 0.46, blue: 1.0), copper: Color(red: 0.72, green: 0.30, blue: 0.78), bolt: Color(red: 0.62, green: 0.48, blue: 0.75), powered: Color(red: 0.86, green: 0.16, blue: 1), poweredCore: Color(red: 1, green: 0.68, blue: 1), spark: Color(red: 1, green: 0.18, blue: 0.64), rocket: Color(red: 0.63, green: 0.16, blue: 0.96), rocketDark: Color(red: 0.26, green: 0.04, blue: 0.42), rocketLight: Color(red: 0.88, green: 0.52, blue: 1), glass: Color(red: 0.45, green: 0.75, blue: 1)
    )

    static let chrome = BasePalette(
        backgroundTop: Color(red: 0.015, green: 0.075, blue: 0.16), backgroundBottom: Color(red: 0.005, green: 0.02, blue: 0.05), nebulaA: .cyan.opacity(0.28), nebulaB: .blue.opacity(0.24), skyline: Color(red: 0.02, green: 0.08, blue: 0.15),
        tile: Color(red: 0.055, green: 0.09, blue: 0.13), tileTop: Color(red: 0.12, green: 0.18, blue: 0.24), tileBottom: Color(red: 0.025, green: 0.045, blue: 0.07), tileEdge: Color(red: 0.22, green: 0.42, blue: 0.56), pipeDark: Color(red: 0.06, green: 0.10, blue: 0.14), pipeMid: Color(red: 0.32, green: 0.48, blue: 0.58), pipeLight: Color(red: 0.75, green: 0.92, blue: 1), copper: Color(red: 0.27, green: 0.62, blue: 0.82), bolt: Color(red: 0.62, green: 0.76, blue: 0.85), powered: Color(red: 0.08, green: 0.65, blue: 1), poweredCore: Color(red: 0.65, green: 0.95, blue: 1), spark: Color(red: 0.12, green: 0.78, blue: 1), rocket: Color(red: 0.08, green: 0.45, blue: 1), rocketDark: Color(red: 0.02, green: 0.16, blue: 0.42), rocketLight: Color(red: 0.48, green: 0.80, blue: 1), glass: Color(red: 0.55, green: 0.95, blue: 1)
    )
}
