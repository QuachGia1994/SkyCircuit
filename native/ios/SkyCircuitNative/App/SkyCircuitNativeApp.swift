import SwiftUI

@main
struct SkyCircuitNativeApp: App {
    @State private var engine = GameEngine()

    var body: some Scene {
        WindowGroup {
            GameRootView(engine: engine)
        }
    }
}
