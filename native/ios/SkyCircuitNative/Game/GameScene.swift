import SpriteKit

@MainActor
final class GameScene: SKScene {
    var onRotationQuality: (@MainActor (Double) -> Void)?
    var onLaunch: (@MainActor () -> Void)?

    private var tiles: [SKShapeNode] = []
    private let columns = 8
    private let rows = 8

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.01, green: 0.03, blue: 0.08, alpha: 1)
        buildBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let hitNodes = nodes(at: point)
        guard let tile = hitNodes.first(where: { $0.name?.hasPrefix("tile-") == true }) as? SKShapeNode else { return }

        tile.zRotation -= .pi / 2
        let normalized = normalizedRotation(tile.zRotation)
        let quality = max(0, 1 - abs(normalized) / (.pi / 2))
        onRotationQuality?(quality)

        if quality > 0.92 {
            tile.run(.sequence([
                .scale(to: 1.08, duration: 0.06),
                .scale(to: 1.0, duration: 0.08),
            ]))
            if let name = tile.name,
               let column = Int(name.split(separator: "-").last ?? ""),
               column % 5 == 0 {
                onLaunch?()
            }
        }
    }

    private func buildBoard() {
        removeAllChildren()
        tiles.removeAll(keepingCapacity: true)

        let boardSize = min(size.width * 0.9, size.height * 0.72)
        let cell = boardSize / CGFloat(columns)
        let originX = -boardSize / 2 + cell / 2
        let originY = -boardSize / 2 + cell / 2

        for row in 0..<rows {
            for column in 0..<columns {
                let tile = makeTile(cell: cell, row: row, column: column)
                tile.position = CGPoint(
                    x: originX + CGFloat(column) * cell,
                    y: originY + CGFloat(row) * cell
                )
                addChild(tile)
                tiles.append(tile)
            }
        }
    }

    private func makeTile(cell: CGFloat, row: Int, column: Int) -> SKShapeNode {
        let tile = SKShapeNode(rectOf: CGSize(width: cell * 0.9, height: cell * 0.9), cornerRadius: cell * 0.12)
        tile.name = "tile-\(row)-\(column)"
        tile.fillColor = SKColor(red: 0.055, green: 0.105, blue: 0.18, alpha: 1)
        tile.strokeColor = SKColor(red: 0.26, green: 0.42, blue: 0.58, alpha: 1)
        tile.lineWidth = 1.2

        let conduit = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -cell * 0.32, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: cell * 0.32))
        conduit.path = path
        conduit.lineCap = .round
        conduit.lineJoin = .round
        conduit.lineWidth = max(5, cell * 0.13)
        conduit.strokeColor = SKColor(red: 0.47, green: 0.86, blue: 1.0, alpha: 1)
        conduit.glowWidth = 1.4
        tile.addChild(conduit)

        let hub = SKShapeNode(circleOfRadius: max(3, cell * 0.07))
        hub.fillColor = .white
        hub.strokeColor = SKColor(red: 0.95, green: 0.6, blue: 0.17, alpha: 1)
        hub.lineWidth = 1
        tile.addChild(hub)
        return tile
    }

    private func normalizedRotation(_ angle: CGFloat) -> CGFloat {
        let quarter = CGFloat.pi / 2
        let remainder = angle.truncatingRemainder(dividingBy: quarter)
        return min(abs(remainder), quarter - abs(remainder))
    }
}
