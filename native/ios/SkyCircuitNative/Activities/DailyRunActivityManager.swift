import ActivityKit
import Foundation

@MainActor
final class DailyRunActivityManager {
    private var activityID: String?
    private(set) var lastError: String?

    func start(streak: Int, score: Int, rank: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DailyRunAttributes(runID: UUID(), startedAt: .now)
        let state = DailyRunAttributes.ContentState(streak: streak, score: score, rank: rank, progress: 0)
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            activityID = try Activity.request(attributes: attributes, content: content, pushType: nil).id
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func update(streak: Int, score: Int, rank: Int, progress: Double) async {
        guard let activityID else { return }
        let state = DailyRunAttributes.ContentState(
            streak: streak,
            score: score,
            rank: rank,
            progress: min(max(progress, 0), 1)
        )
        await Self.updateActivity(id: activityID, state: state)
    }

    func finish(streak: Int, score: Int, rank: Int) async {
        guard let activityID else { return }
        let state = DailyRunAttributes.ContentState(streak: streak, score: score, rank: rank, progress: 1)
        await Self.endActivity(id: activityID, state: state)
        self.activityID = nil
    }

    private nonisolated static func updateActivity(id: String, state: DailyRunAttributes.ContentState) async {
        guard let activity = Activity<DailyRunAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    private nonisolated static func endActivity(id: String, state: DailyRunAttributes.ContentState) async {
        guard let activity = Activity<DailyRunAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
    }
}
