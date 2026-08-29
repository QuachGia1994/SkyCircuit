import ActivityKit
import Foundation

struct DailyRunAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        var streak: Int
        var score: Int
        var rank: Int
        var progress: Double
    }

    let runID: UUID
    let startedAt: Date
}
