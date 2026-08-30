import StoreKit
import SwiftUI

@MainActor
struct GameRootView: View {
    @Bindable var engine: GameEngine
    @State private var showPlus = false
    @State private var showTutorial = false
    @State private var showSettings = false
    @State private var showStartup = true

    var body: some View {
        ZStack {
            SkyBackground(theme: engine.theme)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    modeStrip
                    hud
                    board
                    statusCard
                    controls
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if showStartup { StartupOverlay(theme: engine.theme, language: engine.language) }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, engine.language.locale)
        .sheet(isPresented: $showPlus) { PlusStoreView(engine: engine) }
        .sheet(isPresented: $showSettings) { SettingsView(engine: engine) }
        .fullScreenCover(isPresented: $showTutorial, onDismiss: markTutorialSeen) {
            TutorialView(theme: engine.theme, language: engine.language)
        }
        .task { await engine.store.loadProducts() }
        .task { engine.activateAudio() }
        .task { await dismissStartupAfterDelay() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            brand
            Spacer(minLength: 4)
            iconButton("questionmark", accent: chrome.cyan) {
                guard engine.burnAnimation == nil else { return }
                showTutorial = true
            }
            iconButton("gearshape.fill", accent: .white.opacity(0.72)) { showSettings = true }
            Button(L10n.text("plus", language: engine.language)) {
                guard engine.burnAnimation == nil else { return }
                showPlus = true
            }
                .buttonStyle(GlassTextButtonStyle(accent: chrome.gold))
        }
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.text("firework_tagline", language: engine.language))
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(chrome.gold)
            HStack(spacing: 8) {
                Text("SkyCircuit")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                    .foregroundStyle(brandGradient)
                    .shadow(color: chrome.cyan.opacity(0.28), radius: 12)
                Circle()
                    .trim(from: 0.08, to: 0.82)
                    .stroke(chrome.cyan.opacity(0.75), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: 34, height: 34)
                    .rotationEffect(.degrees(-24))
                    .overlay(Image(systemName: "sparkle").font(.caption).foregroundStyle(chrome.gold))
            }
        }
    }

    private var modeStrip: some View {
        HStack(spacing: 10) {
            Label(engine.mode.title(language: engine.language), systemImage: "circle.grid.cross")
                .font(.caption.weight(.black))
                .tracking(1.1)
                .foregroundStyle(chrome.gold)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(chrome.gold.opacity(0.42), lineWidth: 1))

            Button {
                engine.startDailyRun()
            } label: {
                Label(L10n.text("daily", language: engine.language), systemImage: "flame.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(chrome.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(chrome.cyan.opacity(0.30), lineWidth: 1))

            Spacer()
            levelBadge
        }
    }

    private var levelBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(L10n.format("level_format", language: engine.language, engine.level))
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.86))
            Text(L10n.format("rockets_format", language: engine.language, engine.launched, engine.target))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(chrome.cyan.opacity(0.34), lineWidth: 1))
    }

    private var hud: some View {
        HStack(spacing: 8) {
            statCard(L10n.text("score", language: engine.language), "\(engine.score)", "star.fill", chrome.gold)
            statCard(L10n.text("combo", language: engine.language), "×\(engine.combo)", "bolt.fill", .orange)
            statCard(L10n.text("time", language: engine.language), timeText, "timer", chrome.cyan)
            statCard(L10n.text("best", language: engine.language), "\(engine.best)", "trophy.fill", .pink)
        }
    }

    private var board: some View {
        CircuitBoardView(engine: engine)
            .padding(5)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(boardStroke, lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.55), radius: 24, y: 14)
            .shadow(color: chrome.cyan.opacity(0.08), radius: 18)
    }

    private var statusCard: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(chrome.gold.opacity(0.12))
                Circle().stroke(chrome.gold.opacity(0.38), lineWidth: 1)
                Image(systemName: engine.burnAnimation == nil ? "lightbulb.max.fill" : "flame.fill")
                    .foregroundStyle(engine.burnAnimation == nil ? chrome.gold : .orange)
            }
            .frame(width: 38, height: 38)

            Text(engine.status)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button(L10n.text(engine.phase == .paused ? "resume" : "pause", language: engine.language)) { engine.togglePause() }
                .buttonStyle(GameControlStyle(kind: .secondary, accent: chrome.cyan))
            Button(L10n.text("new_game", language: engine.language)) { engine.restart() }
                .buttonStyle(GameControlStyle(kind: .primary, accent: chrome.gold))
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 9, weight: .bold)).foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.68)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(.horizontal, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [accent.opacity(0.28), .white.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    private func iconButton(_ symbol: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(GlassIconButtonStyle(accent: accent))
    }

    private func dismissStartupAfterDelay() async {
        do {
            try await Task.sleep(for: .seconds(4.0))
        } catch {
            return
        }
        guard showStartup else { return }
        withAnimation(.easeOut(duration: 0.34)) { showStartup = false }
        guard !UserDefaults.standard.bool(forKey: "skycircuit.native.tutorialSeen") else { return }
        do {
            try await Task.sleep(for: .milliseconds(320))
        } catch {
            return
        }
        showTutorial = true
    }

    private func markTutorialSeen() {
        UserDefaults.standard.set(true, forKey: "skycircuit.native.tutorialSeen")
    }

    private var timeText: String {
        guard let time = engine.timeLeft else { return "∞" }
        return String(max(0, Int(ceil(time))))
    }

    private var brandGradient: LinearGradient {
        LinearGradient(colors: [.white, chrome.cyan.opacity(0.92), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var boardStroke: LinearGradient {
        LinearGradient(colors: [chrome.gold.opacity(0.38), chrome.cyan.opacity(0.32), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var chrome: ThemeChrome { ThemeChrome(theme: engine.theme) }
}

struct SkyBackground: View {
    let theme: CircuitTheme

    var body: some View {
        ZStack {
            LinearGradient(colors: chrome.background, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [chrome.cyan.opacity(0.18), .clear], center: .topTrailing, startRadius: 20, endRadius: 430)
            RadialGradient(colors: [chrome.violet.opacity(0.14), .clear], center: .bottomLeading, startRadius: 10, endRadius: 360)
            stars
            skyline
        }
        .ignoresSafeArea()
    }

    private var stars: some View {
        Canvas { context, size in
            for index in 0..<56 {
                let x = CGFloat((index * 137 + 23) % 997) / 997 * size.width
                let y = CGFloat((index * 89 + 17) % 991) / 991 * size.height
                let radius = CGFloat(index % 3 + 1) * 0.75
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(index % 8 == 0 ? chrome.cyan.opacity(0.70) : .white.opacity(0.36)))
            }
        }
    }

    private var skyline: some View {
        VStack {
            Spacer()
            Canvas { context, size in
                for index in 0..<9 {
                    let width = size.width / 11
                    let x = CGFloat(index) * width * 1.35 - width * 0.2
                    let height = CGFloat(45 + (index * 37) % 110)
                    let rect = CGRect(x: x, y: size.height - height, width: width, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(chrome.city.opacity(0.72)))
                }
            }
            .frame(height: 190)
        }
        .allowsHitTesting(false)
    }

    private var chrome: ThemeChrome { ThemeChrome(theme: theme) }
}

struct ThemeChrome {
    let cyan: Color
    let gold: Color
    let violet: Color
    let city: Color
    let background: [Color]

    init(theme: CircuitTheme) {
        switch theme {
        case .classic:
            cyan = Color(red: 0.35, green: 0.82, blue: 1)
            gold = Color(red: 1, green: 0.72, blue: 0.28)
            violet = Color(red: 0.48, green: 0.35, blue: 0.95)
            city = Color(red: 0.025, green: 0.08, blue: 0.16)
            background = [Color(red: 0.015, green: 0.065, blue: 0.14), Color(red: 0.006, green: 0.02, blue: 0.055), .black]
        case .novaGold:
            cyan = Color(red: 1, green: 0.70, blue: 0.22)
            gold = Color(red: 1, green: 0.82, blue: 0.35)
            violet = .orange
            city = Color(red: 0.11, green: 0.055, blue: 0.015)
            background = [Color(red: 0.12, green: 0.065, blue: 0.012), Color(red: 0.045, green: 0.024, blue: 0.006), .black]
        case .nebulaViolet:
            cyan = Color(red: 0.77, green: 0.46, blue: 1)
            gold = Color(red: 1, green: 0.42, blue: 0.76)
            violet = Color(red: 0.56, green: 0.20, blue: 1)
            city = Color(red: 0.075, green: 0.02, blue: 0.13)
            background = [Color(red: 0.085, green: 0.025, blue: 0.17), Color(red: 0.025, green: 0.008, blue: 0.06), .black]
        case .plasmaChrome:
            cyan = Color(red: 0.30, green: 0.86, blue: 1)
            gold = Color(red: 0.38, green: 0.74, blue: 1)
            violet = Color(red: 0.22, green: 0.46, blue: 1)
            city = Color(red: 0.02, green: 0.075, blue: 0.14)
            background = [Color(red: 0.01, green: 0.075, blue: 0.16), Color(red: 0.005, green: 0.02, blue: 0.05), .black]
        }
    }
}

private struct GlassIconButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(configuration.isPressed ? 0.78 : 0.38), lineWidth: 1))
            .shadow(color: accent.opacity(0.09), radius: 12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

private struct GlassTextButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.black))
            .tracking(1)
            .foregroundStyle(accent)
            .frame(width: 70, height: 50)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.46), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct GameControlStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    let kind: Kind
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(kind == .primary ? Color(red: 0.035, green: 0.06, blue: 0.10) : .white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(background, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(accent.opacity(0.48), lineWidth: 1))
            .shadow(color: accent.opacity(kind == .primary ? 0.22 : 0.08), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var background: AnyShapeStyle {
        if kind == .primary {
            return AnyShapeStyle(LinearGradient(colors: [accent.opacity(0.95), .orange.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return AnyShapeStyle(.regularMaterial)
    }
}

@MainActor
struct PlusStoreView: View {
    @Bindable var engine: GameEngine
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                SkyBackground(theme: engine.theme)
                ScrollView {
                    VStack(spacing: 18) {
                        plusHeader
                        themeSection
                        modeSection
                        benefitSection
                        products
                    }
                    .padding(18)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var plusHeader: some View {
        VStack(spacing: 6) {
            Text(L10n.text("plus_title", language: engine.language))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, ThemeChrome(theme: engine.theme).gold], startPoint: .leading, endPoint: .trailing))
            Text(L10n.text(engine.store.isBetaUnlocked ? "plus_beta_full" : "plus_premium_subtitle", language: engine.language))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(engine.store.isBetaUnlocked ? ThemeChrome(theme: engine.theme).cyan : .white.opacity(0.62))
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.text("themes_pulse", language: engine.language))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CircuitTheme.allCases) { theme in
                    ThemeCard(theme: theme, language: engine.language, selected: engine.theme == theme, unlocked: !theme.requiresPlus || engine.store.hasPlus) {
                        engine.setTheme(theme)
                    }
                }
            }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.text("modes", language: engine.language))
            HStack(spacing: 9) {
                ForEach(GameMode.allCases) { mode in
                    Button {
                        engine.setMode(mode)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: mode == .classic ? "circle.grid.cross" : mode == .zen ? "leaf.fill" : "bolt.fill")
                            Text(mode.title(language: engine.language)).font(.caption2.weight(.black))
                            if mode != .classic && !engine.store.hasPlus { Image(systemName: "lock.fill").font(.caption2) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 74)
                    }
                    .buttonStyle(ModeCardStyle(active: engine.mode == mode, accent: ThemeChrome(theme: engine.theme).cyan))
                }
            }
        }
    }

    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.text("plus_benefits", language: engine.language))
            LazyVGrid(columns: columns, spacing: 10) {
                benefit("nosign", "no_ads", "no_ads_body")
                benefit("paintpalette.fill", "exclusive_skins", "exclusive_skins_body")
                benefit("bolt.fill", "early_modes", "early_modes_body")
                benefit("calendar.badge.clock", "daily_streak", "daily_streak_body")
            }
        }
    }

    @ViewBuilder
    private var products: some View {
        if engine.store.isBetaUnlocked {
            Label(L10n.text("beta_full_access_enabled", language: engine.language), systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(ThemeChrome(theme: engine.theme).cyan)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else if engine.store.products.isEmpty {
            Text(L10n.text("store_not_configured", language: engine.language))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.56))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            ForEach(engine.store.products, id: \.id) { product in
                ProductView(id: product.id)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private func benefit(_ symbol: String, _ titleKey: String, _ bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol).font(.title2).foregroundStyle(ThemeChrome(theme: engine.theme).gold)
            Text(L10n.text(titleKey, language: engine.language)).font(.caption.weight(.black)).foregroundStyle(.white)
            Text(L10n.text(bodyKey, language: engine.language)).font(.caption2).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.caption.weight(.black)).tracking(1.4).foregroundStyle(.white.opacity(0.62))
    }
}

private struct ThemeCard: View {
    let theme: CircuitTheme
    let language: AppLanguage
    let selected: Bool
    let unlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                ThemePreview(theme: theme)
                    .frame(height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.title(language: language)).font(.caption.weight(.black))
                        Text(L10n.text(unlocked ? "available" : "plus", language: language)).font(.caption2).foregroundStyle(.white.opacity(0.48))
                    }
                    Spacer()
                    Image(systemName: selected ? "checkmark.seal.fill" : unlocked ? "circle" : "lock.fill")
                }
            }
            .padding(10)
            .foregroundStyle(.white)
        }
        .buttonStyle(ThemeCardStyle(selected: selected, accent: ThemeChrome(theme: theme).gold))
    }
}

private struct ThemePreview: View {
    let theme: CircuitTheme

    var body: some View {
        Canvas { context, size in
            let chrome = ThemeChrome(theme: theme)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: chrome.background), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            var pipe = Path()
            pipe.move(to: CGPoint(x: 8, y: size.height * 0.70))
            pipe.addLine(to: CGPoint(x: size.width * 0.48, y: size.height * 0.70))
            pipe.addQuadCurve(to: CGPoint(x: size.width * 0.70, y: size.height * 0.42), control: CGPoint(x: size.width * 0.66, y: size.height * 0.70))
            pipe.addLine(to: CGPoint(x: size.width - 12, y: size.height * 0.42))
            context.stroke(pipe, with: .color(.black.opacity(0.75)), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
            context.stroke(pipe, with: .linearGradient(Gradient(colors: [.white.opacity(0.72), chrome.cyan, chrome.gold]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            context.stroke(pipe, with: .color(chrome.gold.opacity(0.82)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct ThemeCardStyle: ButtonStyle {
    let selected: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(selected ? accent.opacity(0.8) : .white.opacity(0.09), lineWidth: selected ? 1.5 : 1))
            .shadow(color: selected ? accent.opacity(0.16) : .clear, radius: 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct ModeCardStyle: ButtonStyle {
    let active: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(active ? accent : .white.opacity(0.72))
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(active ? accent.opacity(0.58) : .white.opacity(0.08), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
