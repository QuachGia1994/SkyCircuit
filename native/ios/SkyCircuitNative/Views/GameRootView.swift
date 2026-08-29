import SpriteKit
import StoreKit
import SwiftUI

struct GameRootView: View {
    @Bindable var engine: GameEngine
    @State private var showPlus = false

    var body: some View {
        ZStack {
            SpriteView(
                scene: engine.scene,
                isPaused: engine.phase != .playing,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                hud
                Spacer()
                controls
            }
            .padding()
        }
        .sheet(isPresented: $showPlus) {
            PlusStoreView(store: engine.store)
        }
        .task {
            await engine.store.loadProducts()
        }
    }

    private var hud: some View {
        HStack(spacing: 10) {
            stat("SCORE", value: "\(engine.score)")
            stat("COMBO", value: "×\(engine.combo)")
            stat("STREAK", value: "\(engine.streak)")
            stat("RANK", value: "#\(engine.rank)")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(engine.phase == .paused ? "Resume" : "Pause") {
                engine.togglePause()
            }
            .buttonStyle(.borderedProminent)

            Button("Daily Run") {
                engine.startDailyRun()
            }
            .buttonStyle(.borderedProminent)

            Button("Plus") {
                showPlus = true
            }
            .buttonStyle(.borderedProminent)
        }
        .fontWeight(.semibold)
    }

    private func stat(_ title: String, value: String) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

struct GlassPanel<Content: View>: View {
    @ContentBuilder private let content: () -> Content

    init(@ContentBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .glassEffect()
    }
}

struct PlusStoreView: View {
    @Bindable var store: StoreManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(store.hasPlus ? "SkyCircuit Plus Active" : "Unlock SkyCircuit Plus")
                        .font(.largeTitle.bold())

                    ForEach(store.products, id: \.id) { product in
                        ProductView(id: product.id)
                    }

                    if let lastError = store.lastError {
                        Text(lastError)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Plus")
        }
    }
}
