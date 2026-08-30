import Foundation

struct CircuitDirection: OptionSet, Hashable, Sendable {
    let rawValue: UInt8

    static let north = CircuitDirection(rawValue: 1 << 0)
    static let east = CircuitDirection(rawValue: 1 << 1)
    static let south = CircuitDirection(rawValue: 1 << 2)
    static let west = CircuitDirection(rawValue: 1 << 3)
    static let all: [CircuitDirection] = [.north, .east, .south, .west]

    var opposite: CircuitDirection {
        switch self {
        case .north: .south
        case .east: .west
        case .south: .north
        default: .east
        }
    }
}

struct CircuitCell: Hashable, Sendable {
    let row: Int
    let column: Int
}

struct CircuitTile: Hashable, Sendable {
    var connections: CircuitDirection

    mutating func rotateClockwise() {
        let raw = connections.rawValue
        connections = CircuitDirection(rawValue: ((raw << 1) & 0x0F) | ((raw >> 3) & 0x01))
    }
}

struct LaunchSolution: Sendable {
    let burned: Set<CircuitCell>
    let rocketRows: [Int]
    let burnStages: [[CircuitCell]]
}

struct BurnAnimation: Sendable {
    enum Phase: Sendable { case burning, launching }

    let solution: LaunchSolution
    let startedAt: TimeInterval
    var phase: Phase = .burning
    var launchStartedAt: TimeInterval?
}

struct CircuitRenderFrame: Sendable {
    let powered: Set<CircuitCell>
    let burning: Set<CircuitCell>
    let nextStage: Set<CircuitCell>
    let rocketRows: Set<Int>
    let stageProgress: Double
    let launchProgress: Double
}

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case classic
    case zen
    case blitz

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        L10n.text("mode_\(rawValue)", language: language)
    }

    var initialTime: Double? { self == .zen ? nil : self == .blitz ? 45 : 70 }
    var target: Int { self == .blitz ? 12 : 8 }
}

enum CircuitTheme: String, CaseIterable, Identifiable, Sendable {
    case classic
    case novaGold
    case nebulaViolet
    case plasmaChrome

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .classic: key = "theme_classic"
        case .novaGold: key = "theme_nova_gold"
        case .nebulaViolet: key = "theme_nebula_violet"
        case .plasmaChrome: key = "theme_plasma_chrome"
        }
        return L10n.text(key, language: language)
    }

    var requiresPlus: Bool { self != .classic }
}
