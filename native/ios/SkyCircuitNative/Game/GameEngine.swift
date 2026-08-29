import Foundation
import Observation

@MainActor
@Observable
final class GameEngine {
    enum Phase: String, Sendable {
        case playing
        case paused
        case gameOver
    }

    var phase: Phase = .playing
    var score = 0
    var combo = 1
    var streak = 1
    var rank = 42
    var dailyProgress = 0.0
    var renderMilliseconds = 0.0

    let scene = GameScene(size: CGSize(width: 768, height: 720))
    let store = StoreManager()

    private let haptics = HapticEngine()
    private let audio = ProceduralAudioEngine()
    private let liveActivity = DailyRunActivityManager()

    init() {
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.onRotationQuality = { [weak self] quality in
            self?.registerRotation(quality: quality)
        }
        scene.onLaunch = { [weak self] in
            self?.registerLaunch()
        }
    }

    func togglePause() {
        phase = phase == .paused ? .playing : .paused
    }

    func restart() {
        phase = .playing
        score = 0
        combo = 1
        dailyProgress = 0
    }

    func startDailyRun() {
        phase = .playing
        dailyProgress = 0
        liveActivity.start(streak: streak, score: score, rank: rank)
    }

    func finishDailyRun() {
        phase = .gameOver
        dailyProgress = 1
        Task { await liveActivity.finish(streak: streak, score: score, rank: rank) }
    }

    private func registerRotation(quality: Double) {
        haptics.playPlacement(quality: quality)
        audio.playPlacement(quality: quality)
        if quality > 0.92 {
            score += 10 * combo
            dailyProgress = min(1, dailyProgress + 0.04)
        } else {
            combo = 1
        }
        Task {
            await liveActivity.update(streak: streak, score: score, rank: rank, progress: dailyProgress)
        }
    }

    private func registerLaunch() {
        combo = min(combo + 1, 9)
        score += 100 * combo
        haptics.playLaunch(combo: combo)
        audio.playLaunch(combo: combo)
    }
}
