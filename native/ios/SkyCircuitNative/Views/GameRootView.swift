import SpriteKit
import StoreKit
import SwiftUI

struct GameRootView: View {
    @Bindable var engine: GameEngine
    @State private var showPlus = false

    var body: some View {
        ZStack {
            SkyBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    modeAndLevel
                    hud
                    board
                    status
                    controls
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPlus) {
            PlusStoreView(store: engine.store)
        }
        .task {
            await engine.store.loadProducts()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FIREWORK CIRCUIT PUZZLE")
                    .font(.caption2.weight(.black))
                    .tracking(2.3)
                    .foregroundStyle(Color.orange.opacity(0.95))

                Text("SkyCircuit")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.72, green: 0.9, blue: 1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.35), radius: 10)
            }

            Spacer(minLength: 8)

            iconButton("questionmark") { }
            Button {
                showPlus = true
            } label: {
                Text("PLUS")
                    .font(.subheadline.weight(.black))
                    .tracking(1)
                    .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.32))
                    .frame(width: 72, height: 52)
            }
            .buttonStyle(GlassOutlineButtonStyle(accent: Color(red: 1, green: 0.68, blue: 0.2)))
        }
    }

    private var modeAndLevel: some View {
        HStack {
            Text("CLASSIC")
                .font(.caption.weight(.black))
                .tracking(1.2)
                .foregroundStyle(Color(red: 1, green: 0.74, blue: 0.35))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.black.opacity(0.24), in: Capsule())
                .overlay(Capsule().stroke(Color.orange.opacity(0.45), lineWidth: 1))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("LEVEL 1")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
                Text("0/8 ROCKETS")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(.black.opacity(0.22), in: Capsule())
            .overlay(Capsule().stroke(Color(red: 0.28, green: 0.48, blue: 0.72).opacity(0.7), lineWidth: 1))
        }
    }

    private var hud: some View {
        HStack(spacing: 8) {
            stat("SCORE", value: "\(engine.score)")
            stat("COMBO", value: "×\(engine.combo)")
            stat("STREAK", value: "\(engine.streak)")
            stat("RANK", value: "#\(engine.rank)")
        }
    }

    private var board: some View {
        SpriteView(
            scene: engine.scene,
            isPaused: engine.phase != .playing,
            preferredFramesPerSecond: 120,
            options: [.allowsTransparency, .ignoresSiblingOrder, .shouldCullNonVisibleNodes]
        )
        .aspectRatio(1.02, contentMode: .fit)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.08, blue: 0.05), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.42), Color.cyan.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 24, y: 14)
    }

    private var status: some View {
        Text(engine.phase == .paused
             ? "Paused. Tap Resume when you're ready."
             : "Classic mode. Rotate tiles and connect a spark to a rocket.")
            .font(.callout)
            .foregroundStyle(.white.opacity(0.58))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button(engine.phase == .paused ? "Resume" : "Pause") {
                engine.togglePause()
            }
            .buttonStyle(GameControlStyle(kind: .secondary))

            Button("New Game") {
                engine.restart()
            }
            .buttonStyle(GameControlStyle(kind: .primary))
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.14, blue: 0.24).opacity(0.92), Color(red: 0.03, green: 0.08, blue: 0.15).opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.24, green: 0.43, blue: 0.64).opacity(0.62), lineWidth: 1)
        )
    }

    private func iconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(GlassOutlineButtonStyle(accent: Color.cyan.opacity(0.55)))
    }
}

private struct SkyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.16),
                    Color(red: 0.01, green: 0.035, blue: 0.08),
                    .black,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            Canvas { context, size in
                for index in 0..<46 {
                    let x = CGFloat((index * 137 + 23) % 997) / 997 * size.width
                    let y = CGFloat((index * 89 + 17) % 991) / 991 * size.height
                    let radius = CGFloat(index % 3 + 1) * 0.7
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                        with: .color(index % 8 == 0 ? .cyan.opacity(0.65) : .white.opacity(0.34))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct GlassOutlineButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(configuration.isPressed ? 0.9 : 0.55), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

private struct GameControlStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(kind == .primary ? Color(red: 0.04, green: 0.08, blue: 0.14) : .white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(kind == .primary ? Color.orange.opacity(0.8) : Color.blue.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: kind == .primary ? .orange.opacity(0.24) : .black.opacity(0.3), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var background: LinearGradient {
        if kind == .primary {
            LinearGradient(
                colors: [Color(red: 1, green: 0.75, blue: 0.3), Color(red: 0.92, green: 0.5, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [Color(red: 0.09, green: 0.18, blue: 0.31), Color(red: 0.05, green: 0.11, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct PlusStoreView: View {
    @Bindable var store: StoreManager

    var body: some View {
        NavigationStack {
            ZStack {
                SkyBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        Text("SkyCircuit Plus")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .yellow], startPoint: .leading, endPoint: .trailing)
                            )

                        Text("Premium Upgrade & Exclusive Skins")
                            .foregroundStyle(.white.opacity(0.72))

                        HStack(spacing: 10) {
                            benefit("leaf.fill", "ZEN")
                            benefit("bolt.fill", "BLITZ")
                            benefit("star.fill", "DAILY")
                            benefit("nosign", "NO ADS")
                        }

                        ForEach(store.products, id: \.id) { product in
                            ProductView(id: product.id)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }

                        if store.products.isEmpty {
                            Text("Store products are not configured for this test build yet.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                        }

                        if let lastError = store.lastError {
                            Text(lastError)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .padding(22)
                }
            }
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func benefit(_ symbol: String, _ title: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.yellow)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}