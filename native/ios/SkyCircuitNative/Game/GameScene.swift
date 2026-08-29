import SpriteKit

@MainActor
final class GameScene: SKScene {
    var onRotationQuality: (@MainActor (Double) -> Void)?
    var onLaunch: (@MainActor () -> Void)?

    private enum PipeKind: Int {
        case elbow
        case straight
        case tee
        case cross
    }

    private let columns = 8
    private let rows = 8
    private var tiles: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = .clear
        view.allowsTransparency = true
        buildBoard()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != .zero else { return }
        buildBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let hitNodes = nodes(at: point)
        guard let tile = hitNodes.compactMap({ tileAncestor(from: $0) }).first else { return }

        let newRotation = tile.zRotation - .pi / 2
        tile.run(.rotate(toAngle: newRotation, duration: 0.11))

        let targetQuarter = tile.userData?["target"] as? Int ?? 0
        let currentQuarter = normalizedQuarter(newRotation)
        let delta = abs(currentQuarter - targetQuarter)
        let wrapped = min(delta, 4 - delta)
        let quality: Double = switch wrapped {
        case 0: 1
        case 1: 0.62
        default: 0.2
        }

        onRotationQuality?(quality)
        updateEnergy(on: tile, quality: quality)

        if quality > 0.92 {
            tile.run(.sequence([
                .scale(to: 1.045, duration: 0.055),
                .scale(to: 1.0, duration: 0.08),
            ]))

            let row = tile.userData?["row"] as? Int ?? 0
            let column = tile.userData?["column"] as? Int ?? 0
            if (row + column) % 5 == 0 {
                playIgnitionPulse(from: tile)
                onLaunch?()
            }
        }
    }

    private func buildBoard() {
        removeAllChildren()
        tiles.removeAll(keepingCapacity: true)

        let boardSize = min(size.width * 0.79, size.height * 0.84)
        let cell = boardSize / CGFloat(columns)
        let originX = -boardSize / 2 + cell / 2
        let originY = -boardSize / 2 + cell / 2

        addChild(makeBoardChassis(boardSize: boardSize, cell: cell))

        for row in 0..<rows {
            addChild(makeSource(row: row, x: -boardSize / 2 - cell * 0.43, y: originY + CGFloat(row) * cell, cell: cell))
            addChild(makeRocket(row: row, x: boardSize / 2 + cell * 0.43, y: originY + CGFloat(row) * cell, cell: cell))

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

    private func makeBoardChassis(boardSize: CGFloat, cell: CGFloat) -> SKNode {
        let node = SKNode()

        let shadow = SKShapeNode(
            rectOf: CGSize(width: boardSize + cell * 0.38, height: boardSize + cell * 0.38),
            cornerRadius: cell * 0.32
        )
        shadow.fillColor = SKColor(white: 0.005, alpha: 0.78)
        shadow.strokeColor = .clear
        shadow.position.y = -cell * 0.05
        shadow.zPosition = -12
        node.addChild(shadow)

        let frame = SKShapeNode(
            rectOf: CGSize(width: boardSize + cell * 0.28, height: boardSize + cell * 0.28),
            cornerRadius: cell * 0.28
        )
        frame.fillColor = SKColor(red: 0.025, green: 0.045, blue: 0.075, alpha: 0.98)
        frame.strokeColor = SKColor(red: 0.25, green: 0.43, blue: 0.62, alpha: 0.78)
        frame.lineWidth = max(2, cell * 0.035)
        frame.glowWidth = cell * 0.018
        frame.zPosition = -10
        node.addChild(frame)

        let inner = SKShapeNode(
            rectOf: CGSize(width: boardSize + cell * 0.07, height: boardSize + cell * 0.07),
            cornerRadius: cell * 0.18
        )
        inner.fillColor = SKColor(red: 0.035, green: 0.028, blue: 0.025, alpha: 1)
        inner.strokeColor = SKColor(red: 0.52, green: 0.3, blue: 0.12, alpha: 0.45)
        inner.lineWidth = 1
        inner.zPosition = -9
        node.addChild(inner)

        return node
    }

    private func makeTile(cell: CGFloat, row: Int, column: Int) -> SKShapeNode {
        let side = cell * 0.91
        let tile = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: cell * 0.1)
        tile.name = "tile-\(row)-\(column)"
        tile.fillColor = SKColor(red: 0.045, green: 0.065, blue: 0.09, alpha: 1)
        tile.strokeColor = SKColor(red: 0.19, green: 0.29, blue: 0.39, alpha: 1)
        tile.lineWidth = max(1.2, cell * 0.018)
        tile.userData = [
            "row": row,
            "column": column,
            "target": (row * 3 + column * 5) % 4,
        ]

        let inset = SKShapeNode(rectOf: CGSize(width: side * 0.86, height: side * 0.86), cornerRadius: cell * 0.075)
        inset.fillColor = SKColor(red: 0.075, green: 0.09, blue: 0.115, alpha: 1)
        inset.strokeColor = SKColor(red: 0.34, green: 0.25, blue: 0.15, alpha: 0.55)
        inset.lineWidth = 1
        inset.zPosition = 0.1
        tile.addChild(inset)

        addBolts(to: tile, cell: cell)

        let kind = PipeKind(rawValue: (row * 5 + column * 3) % 4) ?? .elbow
        let pipePath = makePipePath(kind: kind, cell: cell)
        addPipeLayers(path: pipePath, to: tile, cell: cell)

        let initialQuarter = (row + column * 2) % 4
        tile.zRotation = -CGFloat(initialQuarter) * .pi / 2
        return tile
    }

    private func makePipePath(kind: PipeKind, cell: CGFloat) -> CGPath {
        let extent = cell * 0.34
        let path = CGMutablePath()

        switch kind {
        case .elbow:
            path.move(to: CGPoint(x: -extent, y: 0))
            path.addLine(to: CGPoint(x: -extent * 0.25, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: extent * 0.25),
                control: CGPoint(x: 0, y: 0)
            )
            path.addLine(to: CGPoint(x: 0, y: extent))
        case .straight:
            path.move(to: CGPoint(x: -extent, y: 0))
            path.addLine(to: CGPoint(x: extent, y: 0))
        case .tee:
            path.move(to: CGPoint(x: -extent, y: 0))
            path.addLine(to: CGPoint(x: extent, y: 0))
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: extent))
        case .cross:
            path.move(to: CGPoint(x: -extent, y: 0))
            path.addLine(to: CGPoint(x: extent, y: 0))
            path.move(to: CGPoint(x: 0, y: -extent))
            path.addLine(to: CGPoint(x: 0, y: extent))
        }
        return path
    }

    private func addPipeLayers(path: CGPath, to tile: SKShapeNode, cell: CGFloat) {
        let shadow = SKShapeNode(path: path)
        shadow.lineCap = .round
        shadow.lineJoin = .round
        shadow.lineWidth = max(9, cell * 0.24)
        shadow.strokeColor = SKColor(red: 0.008, green: 0.012, blue: 0.018, alpha: 1)
        shadow.zPosition = 1
        tile.addChild(shadow)

        let metal = SKShapeNode(path: path)
        metal.lineCap = .round
        metal.lineJoin = .round
        metal.lineWidth = max(7, cell * 0.18)
        metal.strokeColor = SKColor(red: 0.25, green: 0.27, blue: 0.31, alpha: 1)
        metal.zPosition = 2
        tile.addChild(metal)

        let rim = SKShapeNode(path: path)
        rim.lineCap = .round
        rim.lineJoin = .round
        rim.lineWidth = max(3, cell * 0.085)
        rim.strokeColor = SKColor(red: 0.54, green: 0.6, blue: 0.68, alpha: 0.92)
        rim.zPosition = 3
        tile.addChild(rim)

        let energy = SKShapeNode(path: path)
        energy.name = "energy"
        energy.lineCap = .round
        energy.lineJoin = .round
        energy.lineWidth = max(1.8, cell * 0.038)
        energy.strokeColor = SKColor(red: 1, green: 0.55, blue: 0.09, alpha: 1)
        energy.glowWidth = cell * 0.09
        energy.alpha = 0.16
        energy.zPosition = 4
        tile.addChild(energy)

        let hub = SKShapeNode(circleOfRadius: max(3.5, cell * 0.064))
        hub.fillColor = SKColor(red: 0.2, green: 0.12, blue: 0.055, alpha: 1)
        hub.strokeColor = SKColor(red: 0.92, green: 0.55, blue: 0.19, alpha: 1)
        hub.lineWidth = max(1, cell * 0.018)
        hub.zPosition = 5
        tile.addChild(hub)
    }

    private func addBolts(to tile: SKShapeNode, cell: CGFloat) {
        let offset = cell * 0.34
        for point in [
            CGPoint(x: -offset, y: -offset), CGPoint(x: offset, y: -offset),
            CGPoint(x: -offset, y: offset), CGPoint(x: offset, y: offset),
        ] {
            let bolt = SKShapeNode(circleOfRadius: max(1.1, cell * 0.018))
            bolt.position = point
            bolt.fillColor = SKColor(red: 0.45, green: 0.34, blue: 0.2, alpha: 0.9)
            bolt.strokeColor = SKColor(white: 0.1, alpha: 1)
            bolt.lineWidth = 0.7
            bolt.zPosition = 6
            tile.addChild(bolt)
        }
    }

    private func makeSource(row: Int, x: CGFloat, y: CGFloat, cell: CGFloat) -> SKNode {
        let source = SKNode()
        source.position = CGPoint(x: x, y: y)
        source.zPosition = 8

        let housing = SKShapeNode(circleOfRadius: cell * 0.17)
        housing.fillColor = SKColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1)
        housing.strokeColor = SKColor(red: 0.52, green: 0.37, blue: 0.19, alpha: 1)
        housing.lineWidth = max(1.2, cell * 0.025)
        source.addChild(housing)

        let core = SKShapeNode(circleOfRadius: cell * 0.075)
        core.fillColor = SKColor(red: 1, green: 0.54, blue: 0.11, alpha: 1)
        core.strokeColor = .white
        core.lineWidth = 1
        core.glowWidth = cell * 0.12
        source.addChild(core)

        core.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.58, duration: 0.7 + Double(row % 3) * 0.08),
            .fadeAlpha(to: 1, duration: 0.55),
        ])))
        return source
    }

    private func makeRocket(row: Int, x: CGFloat, y: CGFloat, cell: CGFloat) -> SKNode {
        let rocket = SKNode()
        rocket.position = CGPoint(x: x, y: y)
        rocket.zPosition = 9

        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: 0, y: cell * 0.25))
        bodyPath.addQuadCurve(to: CGPoint(x: cell * 0.115, y: -cell * 0.11), control: CGPoint(x: cell * 0.16, y: cell * 0.08))
        bodyPath.addLine(to: CGPoint(x: cell * 0.07, y: -cell * 0.22))
        bodyPath.addLine(to: CGPoint(x: -cell * 0.07, y: -cell * 0.22))
        bodyPath.addLine(to: CGPoint(x: -cell * 0.115, y: -cell * 0.11))
        bodyPath.addQuadCurve(to: CGPoint(x: 0, y: cell * 0.25), control: CGPoint(x: -cell * 0.16, y: cell * 0.08))
        bodyPath.closeSubpath()

        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 0.96, green: 0.13, blue: 0.55, alpha: 1)
        body.strokeColor = SKColor(red: 1, green: 0.63, blue: 0.82, alpha: 1)
        body.lineWidth = 1.2
        body.glowWidth = cell * 0.03
        rocket.addChild(body)

        let window = SKShapeNode(circleOfRadius: cell * 0.055)
        window.position.y = cell * 0.045
        window.fillColor = SKColor(red: 0.15, green: 0.82, blue: 1, alpha: 1)
        window.strokeColor = SKColor(white: 0.9, alpha: 0.85)
        window.lineWidth = 1
        window.glowWidth = cell * 0.025
        rocket.addChild(window)

        let flame = SKShapeNode(path: flamePath(cell: cell))
        flame.name = "flame"
        flame.fillColor = SKColor(red: 1, green: 0.56, blue: 0.08, alpha: 1)
        flame.strokeColor = SKColor(red: 1, green: 0.9, blue: 0.45, alpha: 0.9)
        flame.glowWidth = cell * 0.08
        flame.position.y = -cell * 0.25
        rocket.addChild(flame)

        flame.run(.repeatForever(.sequence([
            .scaleY(to: 0.72, duration: 0.09 + Double(row % 2) * 0.02),
            .scaleY(to: 1.08, duration: 0.12),
        ])))
        return rocket
    }

    private func flamePath(cell: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -cell * 0.045, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: -cell * 0.16), control: CGPoint(x: -cell * 0.015, y: -cell * 0.09))
        path.addQuadCurve(to: CGPoint(x: cell * 0.045, y: 0), control: CGPoint(x: cell * 0.015, y: -cell * 0.09))
        path.closeSubpath()
        return path
    }

    private func updateEnergy(on tile: SKShapeNode, quality: Double) {
        guard let energy = tile.childNode(withName: "energy") as? SKShapeNode else { return }
        let targetAlpha = quality > 0.92 ? CGFloat(1) : CGFloat(0.15 + quality * 0.25)
        energy.removeAllActions()
        energy.run(.fadeAlpha(to: targetAlpha, duration: 0.12))
        energy.strokeColor = quality > 0.92
            ? SKColor(red: 1, green: 0.53, blue: 0.06, alpha: 1)
            : SKColor(red: 0.35, green: 0.76, blue: 0.92, alpha: 1)
    }

    private func playIgnitionPulse(from tile: SKShapeNode) {
        guard let energy = tile.childNode(withName: "energy") as? SKShapeNode else { return }
        energy.run(.sequence([
            .group([
                .fadeAlpha(to: 1, duration: 0.06),
                .scale(to: 1.07, duration: 0.06),
            ]),
            .group([
                .scale(to: 1, duration: 0.16),
                .fadeAlpha(to: 0.82, duration: 0.16),
            ]),
        ]))
    }

    private func tileAncestor(from node: SKNode) -> SKShapeNode? {
        var candidate: SKNode? = node
        while let current = candidate {
            if let tile = current as? SKShapeNode, tile.name?.hasPrefix("tile-") == true {
                return tile
            }
            candidate = current.parent
        }
        return nil
    }

    private func normalizedQuarter(_ angle: CGFloat) -> Int {
        let quarter = CGFloat.pi / 2
        let raw = Int(round((-angle / quarter).truncatingRemainder(dividingBy: 4)))
        return (raw % 4 + 4) % 4
    }
}