import ActivityKit
import Foundation

@MainActor
final class DailyRunActivityManager {
    private var activity: Activity<DailyRunAttributes>?

    func start(streak: Int, score: Int, rank: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DailyRunAttributes(runID: UUID(), startedAt: .now)
        let state = DailyRunAttributes.ContentState(streak: streak, score: score, rank: rank, progress: 0)
        let content = ActivityContent(state: state, staleDate: nil)
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    func update(streak: Int, score: Int, rank: Int, progress: Double) async {
        guard let activity else { return }
        let state = DailyRunAttributes.ContentState(
            streak: streak,
            score: score,
            rank: rank,
            progress: min(max(progress, 0), 1)
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func finish(streak: Int, score: Int, rank: Int) async {
        guard let activity else { return }
        let state = DailyRunAttributes.ContentState(streak: streak, score: score, rank: rank, progress: 1)
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
        self.activity = nil
    }
}
