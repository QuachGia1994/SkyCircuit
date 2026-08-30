import Foundation
import Observation

@MainActor
@Observable
final class GameEngine {
    enum Phase: String, Sendable { case playing, paused, gameOver }

    var phase: Phase = .playing
    var score = 0
    var combo = 1
    var streak = 1
    var rank = 42
    var dailyProgress = 0.0
    var level = 1
    var launched = 0
    var best = 0
    var mode: GameMode = .classic
    var theme: CircuitTheme = .classic
    var timeLeft: Double? = 70
    var tiles: [CircuitTile] = []
    var burnAnimation: BurnAnimation?
    var language: AppLanguage = .english
    var musicEnabled = true
    var soundEffectsEnabled = true
    var hapticsEnabled = true
    var status = ""

    let store = StoreManager()

    private let haptics = HapticEngine()
    private let audio = ProceduralAudioEngine()
    private let liveActivity = DailyRunActivityManager()
    private var lastFrameAt: TimeInterval?
    private var countdownRemaining: Double?
    private let rows = 8
    private let columns = 8

    var target: Int { mode.target + max(0, level - 1) * 2 }

    private let burnStageDuration = 0.14
    private let rocketFlightDuration = 1.55

    init() {
        let defaults = UserDefaults.standard
        best = defaults.integer(forKey: "skycircuit.native.best")
        streak = max(1, defaults.integer(forKey: "skycircuit.native.streak"))
        if let savedLanguage = defaults.string(forKey: "skycircuit.native.language"),
           let restoredLanguage = AppLanguage(rawValue: savedLanguage) {
            language = restoredLanguage
        }
        if let savedTheme = defaults.string(forKey: "skycircuit.native.theme"),
           let restoredTheme = CircuitTheme(rawValue: savedTheme) {
            theme = restoredTheme
        }
        musicEnabled = defaults.object(forKey: "skycircuit.native.music") as? Bool ?? true
        soundEffectsEnabled = defaults.object(forKey: "skycircuit.native.effects") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "skycircuit.native.haptics") as? Bool ?? true
        audio.setMusicEnabled(musicEnabled)
        audio.setEffectsEnabled(soundEffectsEnabled)
        haptics.setEnabled(hapticsEnabled)
        restart()
    }

    func activateAudio() {
        audio.activate()
    }

    func togglePause() {
        guard burnAnimation == nil else { return }
        guard phase != .gameOver else { return }
        phase = phase == .paused ? .playing : .paused
        status = L10n.text(phase == .paused ? "status_paused" : "status_online", language: language)
        lastFrameAt = nil
    }

    func restart() {
        phase = .playing
        score = 0
        combo = 1
        launched = 0
        level = 1
        dailyProgress = 0
        timeLeft = mode.initialTime
        countdownRemaining = mode.initialTime
        burnAnimation = nil
        tiles = Self.makeBoard(count: rows * columns)
        status = L10n.text("status_connect", language: language)
        audio.setMusicEnergy(combo: combo, igniting: false)
        lastFrameAt = nil
    }

    func setMode(_ nextMode: GameMode) {
        guard nextMode == .classic || store.hasPlus else { return }
        mode = nextMode
        restart()
    }

    func setTheme(_ nextTheme: CircuitTheme) {
        guard !nextTheme.requiresPlus || store.hasPlus else { return }
        theme = nextTheme
        UserDefaults.standard.set(nextTheme.rawValue, forKey: "skycircuit.native.theme")
    }

    func setLanguage(_ nextLanguage: AppLanguage) {
        language = nextLanguage
        UserDefaults.standard.set(nextLanguage.rawValue, forKey: "skycircuit.native.language")
        refreshLocalizedStatus()
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "skycircuit.native.music")
        audio.setMusicEnabled(enabled)
    }

    func setSoundEffectsEnabled(_ enabled: Bool) {
        soundEffectsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "skycircuit.native.effects")
        audio.setEffectsEnabled(enabled)
    }

    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "skycircuit.native.haptics")
        haptics.setEnabled(enabled)
    }

    private func refreshLocalizedStatus() {
        if phase == .gameOver {
            status = L10n.text("status_time_expired", language: language)
        } else if phase == .paused {
            status = L10n.text("status_paused", language: language)
        } else if burnAnimation != nil {
            status = L10n.text("status_ignition", language: language)
        } else {
            status = L10n.text("status_connect", language: language)
        }
    }

    func rotateTile(row: Int, column: Int, at now: TimeInterval) {
        guard phase == .playing, burnAnimation == nil else { return }
        guard let index = index(row: row, column: column) else { return }
        tiles[index].rotateClockwise()
        let quality = connectionQuality(row: row, column: column)
        haptics.playPlacement(quality: quality)
        audio.playPlacement(quality: quality)
        resolveAfterRotation(at: now)
    }

    func advanceFrame(at now: TimeInterval) {
        advanceTimer(at: now)
        guard var burn = burnAnimation else { return }
        switch burn.phase {
        case .burning:
            guard now - burn.startedAt >= burnDuration(burn.solution) else { return }
            burn.phase = .launching
            burn.launchStartedAt = now
            burnAnimation = burn
            beginLaunch(burn.solution)
        case .launching:
            guard let started = burn.launchStartedAt, now - started >= rocketFlightDuration else { return }
            finishLaunch(burn.solution, at: now)
        }
    }

    func renderFrame(at now: TimeInterval) -> CircuitRenderFrame {
        guard let burn = burnAnimation else { return Self.emptyRenderFrame }
        if burn.phase == .launching { return launchingFrame(burn, at: now) }
        return burningFrame(burn, at: now)
    }

    func startDailyRun() {
        refreshDailyStreak()
        phase = .playing
        dailyProgress = 0
        liveActivity.start(streak: streak, score: score, rank: rank)
    }

    private func resolveAfterRotation(at now: TimeInterval) {
        let solution = resolveLaunch()
        guard !solution.rocketRows.isEmpty else {
            combo = 1
            audio.setMusicEnergy(combo: combo, igniting: false)
            status = L10n.text("status_keep_rotating", language: language)
            return
        }
        burnAnimation = BurnAnimation(solution: solution, startedAt: now)
        audio.setMusicEnergy(combo: combo, igniting: true)
        status = L10n.text("status_ignition", language: language)
    }

    private func beginLaunch(_ solution: LaunchSolution) {
        let rocketCount = solution.rocketRows.count
        score += rocketCount * 100 + max(0, rocketCount - 1) * 175 + solution.burned.count * 5
        launched += rocketCount
        combo = min(combo + 1, 9)
        dailyProgress = min(1, dailyProgress + Double(rocketCount) / Double(max(target, 1)))
        haptics.playLaunch(combo: combo)
        audio.playLaunch(combo: combo)
        audio.setMusicEnergy(combo: combo, igniting: true)
        scheduleFireworkSound(rocketCount: rocketCount)
        status = rocketCount > 1
            ? L10n.format("status_rocket_multi_format", language: language, rocketCount, combo)
            : L10n.format("status_rocket_single_format", language: language, combo)
        updateBestIfNeeded()
        Task { await liveActivity.update(streak: streak, score: score, rank: rank, progress: dailyProgress) }
    }

    private func finishLaunch(_ solution: LaunchSolution, at now: TimeInterval) {
        consume(solution.burned)
        burnAnimation = nil
        audio.setMusicEnergy(combo: combo, igniting: false)
        if launched >= target {
            level += 1
            launched = 0
            tiles = Self.makeBoard(count: rows * columns)
            status = L10n.format("status_level_format", language: language, level)
            return
        }
        let cascade = resolveLaunch()
        guard !cascade.rocketRows.isEmpty else { return }
        burnAnimation = BurnAnimation(solution: cascade, startedAt: now)
    }

    private func advanceTimer(at now: TimeInterval) {
        defer { lastFrameAt = now }
        guard phase == .playing, burnAnimation == nil, var remaining = countdownRemaining else { return }
        guard let previous = lastFrameAt else { return }
        remaining = max(0, remaining - min(0.05, now - previous))
        countdownRemaining = remaining
        publishTimerIfNeeded(remaining)
        guard remaining == 0 else { return }
        phase = .gameOver
        status = L10n.text("status_time_expired", language: language)
    }

    private func publishTimerIfNeeded(_ remaining: Double) {
        let visibleSecond = Int(ceil(remaining))
        let publishedSecond = timeLeft.map { Int(ceil($0)) }
        guard visibleSecond != publishedSecond || remaining == 0 else { return }
        timeLeft = remaining
    }

    private func updateBestIfNeeded() {
        guard score > best else { return }
        best = score
        UserDefaults.standard.set(best, forKey: "skycircuit.native.best")
    }

    private func refreshDailyStreak() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lastRun = defaults.object(forKey: "skycircuit.native.lastDaily") as? Date
        guard let lastRun else { return saveDailyStreak(today: today, value: 1) }
        guard !calendar.isDate(lastRun, inSameDayAs: today) else { return }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let nextStreak = yesterday.map { calendar.isDate(lastRun, inSameDayAs: $0) } == true ? streak + 1 : 1
        saveDailyStreak(today: today, value: nextStreak)
    }

    private func saveDailyStreak(today: Date, value: Int) {
        streak = value
        UserDefaults.standard.set(today, forKey: "skycircuit.native.lastDaily")
        UserDefaults.standard.set(value, forKey: "skycircuit.native.streak")
    }

    private func burningFrame(_ burn: BurnAnimation, at now: TimeInterval) -> CircuitRenderFrame {
        let raw = max(0, now - burn.startedAt) / burnStageDuration
        let completed = min(burn.solution.burnStages.count, Int(floor(raw)))
        let active = completed < burn.solution.burnStages.count ? completed : -1
        let powered = Set(burn.solution.burnStages.prefix(completed).flatMap { $0 })
        let burning = active >= 0 ? Set(burn.solution.burnStages[active]) : []
        let next = active + 1 < burn.solution.burnStages.count ? Set(burn.solution.burnStages[active + 1]) : []
        return CircuitRenderFrame(powered: powered, burning: burning, nextStage: next, rocketRows: [], stageProgress: active >= 0 ? raw - floor(raw) : 1, launchProgress: 0)
    }

    private func launchingFrame(_ burn: BurnAnimation, at now: TimeInterval) -> CircuitRenderFrame {
        let started = burn.launchStartedAt ?? now
        let progress = min(1, max(0, (now - started) / rocketFlightDuration))
        return CircuitRenderFrame(powered: burn.solution.burned, burning: [], nextStage: [], rocketRows: Set(burn.solution.rocketRows), stageProgress: 1, launchProgress: progress)
    }

    private func scheduleFireworkSound(rocketCount: Int) {
        Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(930))
            } catch {
                return
            }
            guard burnAnimation?.phase == .launching else { return }
            audio.playFireworkBurst(rocketCount: rocketCount)
        }
    }

    private func burnDuration(_ solution: LaunchSolution) -> Double {
        Double(max(1, solution.burnStages.count)) * burnStageDuration
    }

    private func connectionQuality(row: Int, column: Int) -> Double {
        guard let tile = tile(row: row, column: column) else { return 0 }
        let edges = CircuitDirection.all.filter { tile.connections.contains($0) }
        guard !edges.isEmpty else { return 0 }
        let valid = edges.filter { isMutuallyConnected(row: row, column: column, direction: $0) }.count
        return Double(valid) / Double(edges.count)
    }

    private func resolveLaunch() -> LaunchSolution {
        var accepted: Set<CircuitCell> = []
        var rocketRows: Set<Int> = []
        var distances: [CircuitCell: Int] = [:]

        for row in 0..<rows {
            let source = CircuitCell(row: row, column: 0)
            guard tile(row: row, column: 0)?.connections.contains(.west) == true else { continue }
            guard let path = pairedRocketPath(from: source) else { continue }
            rocketRows.insert(row)
            mergePath(path, into: &accepted, distances: &distances)
        }

        let stages = makeStages(cells: accepted, distances: distances)
        return LaunchSolution(burned: accepted, rocketRows: rocketRows.sorted(), burnStages: stages)
    }

    private func pairedRocketPath(from source: CircuitCell) -> [CircuitCell]? {
        let target = CircuitCell(row: source.row, column: columns - 1)
        guard tile(row: target.row, column: target.column)?.connections.contains(.east) == true else { return nil }
        var queue = [source]
        var cursor = 0
        var visited: Set<CircuitCell> = [source]
        var parent: [CircuitCell: CircuitCell] = [:]

        while cursor < queue.count {
            let cell = queue[cursor]
            cursor += 1
            if cell == target { return reconstructPath(from: source, to: target, parent: parent) }
            for next in neighbors(of: cell) where !visited.contains(next) {
                visited.insert(next)
                parent[next] = cell
                queue.append(next)
            }
        }
        return nil
    }

    private func reconstructPath(from source: CircuitCell, to target: CircuitCell, parent: [CircuitCell: CircuitCell]) -> [CircuitCell]? {
        var current = target
        var path = [target]
        while current != source {
            guard let previous = parent[current] else { return nil }
            path.append(previous)
            current = previous
        }
        return Array(path.reversed())
    }

    private func mergePath(_ path: [CircuitCell], into cells: inout Set<CircuitCell>, distances: inout [CircuitCell: Int]) {
        for (distance, cell) in path.enumerated() {
            cells.insert(cell)
            distances[cell] = min(distances[cell] ?? distance, distance)
        }
    }

    private func neighbors(of cell: CircuitCell) -> [CircuitCell] {
        guard let current = tile(row: cell.row, column: cell.column) else { return [] }
        return CircuitDirection.all.compactMap { direction in
            guard current.connections.contains(direction) else { return nil }
            guard let next = adjacent(to: cell, direction: direction) else { return nil }
            guard tile(row: next.row, column: next.column)?.connections.contains(direction.opposite) == true else { return nil }
            return next
        }
    }

    private func adjacent(to cell: CircuitCell, direction: CircuitDirection) -> CircuitCell? {
        let candidate: CircuitCell
        switch direction {
        case .north: candidate = CircuitCell(row: cell.row - 1, column: cell.column)
        case .east: candidate = CircuitCell(row: cell.row, column: cell.column + 1)
        case .south: candidate = CircuitCell(row: cell.row + 1, column: cell.column)
        default: candidate = CircuitCell(row: cell.row, column: cell.column - 1)
        }
        guard candidate.row >= 0, candidate.row < rows, candidate.column >= 0, candidate.column < columns else { return nil }
        return candidate
    }

    private func isMutuallyConnected(row: Int, column: Int, direction: CircuitDirection) -> Bool {
        let cell = CircuitCell(row: row, column: column)
        if direction == .west, column == 0 { return true }
        if direction == .east, column == columns - 1 { return true }
        guard let next = adjacent(to: cell, direction: direction) else { return false }
        return tile(row: next.row, column: next.column)?.connections.contains(direction.opposite) == true
    }

    private func consume(_ burned: Set<CircuitCell>) {
        guard !burned.isEmpty else { return }
        for column in 0..<columns {
            let survivors = (0..<rows).compactMap { row -> CircuitTile? in
                let cell = CircuitCell(row: row, column: column)
                return burned.contains(cell) ? nil : tile(row: row, column: column)
            }
            let refill = Self.makeBoard(count: rows - survivors.count)
            let nextColumn = refill + survivors
            for row in 0..<rows { tiles[row * columns + column] = nextColumn[row] }
        }
    }

    private func makeStages(cells: Set<CircuitCell>, distances: [CircuitCell: Int]) -> [[CircuitCell]] {
        let maxDistance = cells.compactMap { distances[$0] }.max() ?? -1
        guard maxDistance >= 0 else { return [] }
        return (0...maxDistance).map { distance in
            cells.filter { distances[$0] == distance }.sorted { ($0.row, $0.column) < ($1.row, $1.column) }
        }
    }

    private func tile(row: Int, column: Int) -> CircuitTile? {
        guard let index = index(row: row, column: column) else { return nil }
        return tiles[index]
    }

    private func index(row: Int, column: Int) -> Int? {
        guard row >= 0, row < rows, column >= 0, column < columns else { return nil }
        return row * columns + column
    }

    private static func makeBoard(count: Int) -> [CircuitTile] {
        let pool: [CircuitDirection] = [
            [.north, .south], [.north, .south], [.north, .east], [.north, .east],
            [.north, .east], [.north, .east, .south], [.north, .east, .south, .west],
        ]
        return (0..<count).map { _ in
            var tile = CircuitTile(connections: pool.randomElement() ?? [.north, .east])
            for _ in 0..<Int.random(in: 0...3) { tile.rotateClockwise() }
            return tile
        }
    }

    private static let emptyRenderFrame = CircuitRenderFrame(powered: [], burning: [], nextStage: [], rocketRows: [], stageProgress: 0, launchProgress: 0)
}
