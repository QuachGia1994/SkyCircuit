import StoreKit
import SwiftUI

@MainActor
struct PlusStoreView: View {
    @Bindable var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    private let skinColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            SkyBackground(theme: engine.theme)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    livePreview
                    skinSection
                    modeSection
                    benefitSection
                    roadmapSection
                    roadmapFooter
                    purchaseSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, engine.language.locale)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("plus_eyebrow", language: engine.language))
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(chrome.gold)
                    .lineLimit(2)
                HStack(spacing: 0) {
                    Text("SkyCircuit").foregroundStyle(.white)
                    Text(" Plus").foregroundStyle(chrome.gold)
                }
                .font(.system(size: 39, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.74)
                .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(PlusGlassIconStyle(accent: chrome.cyan))
            .accessibilityLabel(L10n.text("close", language: engine.language))
        }
    }

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("live_skin_preview", language: engine.language))
                .font(.caption.weight(.black))
                .tracking(1.6)
                .foregroundStyle(chrome.gold)
            Text(engine.theme.title(language: engine.language))
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
            PlusThemePreview(theme: engine.theme)
                .frame(height: 132)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(chrome.cyan.opacity(0.30), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }

    private var skinSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlusSectionHeader(
                title: L10n.text("skins", language: engine.language),
                hint: L10n.text("tap_skin_preview", language: engine.language),
                accent: chrome.gold
            )
            LazyVGrid(columns: skinColumns, spacing: 10) {
                ForEach(CircuitTheme.allCases) { theme in
                    PlusSkinCard(
                        theme: theme,
                        language: engine.language,
                        selected: engine.theme == theme,
                        unlocked: !theme.requiresPlus || engine.store.hasPlus
                    ) {
                        engine.setTheme(theme)
                    }
                }
            }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlusSectionHeader(
                title: L10n.text("modes", language: engine.language),
                hint: L10n.text("modes_hint", language: engine.language),
                accent: chrome.gold
            )
            VStack(spacing: 10) {
                ForEach(GameMode.allCases) { mode in
                    PlusModeCard(
                        mode: mode,
                        language: engine.language,
                        selected: engine.mode == mode,
                        unlocked: mode == .classic || engine.store.hasPlus,
                        accent: chrome.cyan
                    ) {
                        engine.setMode(mode)
                    }
                }
            }
        }
    }

    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlusSectionHeader(
                title: L10n.text("plus_benefits", language: engine.language),
                hint: L10n.text("product_direction", language: engine.language),
                accent: chrome.gold
            )
            VStack(spacing: 10) {
                PlusBenefitCard(symbol: "nosign", title: "no_ads", bodyKey: "no_ads_body", language: engine.language, accent: chrome.cyan)
                PlusBenefitCard(symbol: "paintpalette.fill", title: "exclusive_skins", bodyKey: "exclusive_skins_body", language: engine.language, accent: chrome.cyan)
                PlusBenefitCard(symbol: "bolt.fill", title: "early_modes", bodyKey: "early_modes_body", language: engine.language, accent: chrome.gold)
                PlusBenefitCard(symbol: "calendar.badge.clock", title: "daily_streak", bodyKey: "daily_streak_body", language: engine.language, accent: chrome.gold)
            }
        }
    }

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlusSectionHeader(
                title: L10n.text("roadmap", language: engine.language),
                hint: L10n.text("no_purchase_backend", language: engine.language),
                accent: chrome.gold
            )
            FlowLayout(spacing: 8) {
                roadmapChip("plus_skins", "roadmap_ready")
                roadmapChip("zen_blitz", "roadmap_ready")
                roadmapChip("daily_challenge", "roadmap_next")
                roadmapChip("weekly_events", "roadmap_later")
                roadmapChip("leaderboards", "roadmap_later")
                roadmapChip("seasonal_themes", "roadmap_later")
            }
        }
    }

    private var roadmapFooter: some View {
        VStack(spacing: 7) {
            Text(L10n.text("plus_footer_title", language: engine.language))
                .font(.headline.weight(.black))
                .foregroundStyle(Color(red: 1.0, green: 0.90, blue: 0.62))
            Text(L10n.text("plus_footer_body", language: engine.language))
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color(red: 0.82, green: 0.76, blue: 0.62))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.36, green: 0.23, blue: 0.05).opacity(0.92), Color(red: 0.10, green: 0.08, blue: 0.10).opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(chrome.gold.opacity(0.54), lineWidth: 1))
        .shadow(color: chrome.gold.opacity(0.12), radius: 18)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if engine.store.isBetaUnlocked {
            Label(L10n.text("beta_full_access_enabled", language: engine.language), systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(chrome.cyan)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        } else if engine.store.products.isEmpty {
            Text(L10n.text("store_not_configured", language: engine.language))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        } else {
            ForEach(engine.store.products, id: \.id) { product in
                ProductView(id: product.id)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func roadmapChip(_ titleKey: String, _ statusKey: String) -> some View {
        PlusRoadmapChip(
            title: L10n.text(titleKey, language: engine.language),
            status: L10n.text(statusKey, language: engine.language),
            accent: chrome.gold
        )
    }

    private var chrome: ThemeChrome { ThemeChrome(theme: engine.theme) }
}

private struct PlusSectionHeader: View {
    let title: String
    let hint: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .tracking(1.6)
                .foregroundStyle(accent)
            Spacer(minLength: 4)
            Text(hint)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.54))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct PlusSkinCard: View {
    let theme: CircuitTheme
    let language: AppLanguage
    let selected: Bool
    let unlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                PlusThemePreview(theme: theme)
                    .frame(height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(theme.title(language: language))
                            .font(.caption.weight(.black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.80)
                        Text(L10n.text(unlocked ? "free_or_unlocked" : "plus_preview", language: language))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(unlocked ? .white.opacity(0.55) : ThemeChrome(theme: theme).gold)
                    }
                    Spacer(minLength: 2)
                    Image(systemName: selected ? "checkmark.seal.fill" : unlocked ? "circle" : "lock.fill")
                        .font(.headline)
                }
            }
            .padding(10)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        }
        .buttonStyle(PlusSkinCardStyle(selected: selected, accent: ThemeChrome(theme: theme).gold))
        .accessibilityLabel(theme.title(language: language))
        .accessibilityValue(L10n.text(selected ? "selected" : unlocked ? "free_or_unlocked" : "plus_preview", language: language))
    }
}

private struct PlusModeCard: View {
    let mode: GameMode
    let language: AppLanguage
    let selected: Bool
    let unlocked: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(selected ? accent : .white.opacity(0.72))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode.title(language: language))
                        .font(.headline.weight(.black))
                        .foregroundStyle(selected ? accent : .white)
                    Text(description)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .multilineTextAlignment(.leading)
                    Text(L10n.text(unlocked ? "free_or_unlocked" : "plus_preview", language: language))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(unlocked ? ThemeChrome(theme: .classic).gold : .orange)
                }
                Spacer(minLength: 4)
                if !unlocked { Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.56)) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        }
        .buttonStyle(PlusModeCardStyle(active: selected, accent: accent))
        .accessibilityLabel(mode.title(language: language))
    }

    private var symbol: String {
        switch mode {
        case .classic: "circle.grid.cross"
        case .zen: "leaf.fill"
        case .blitz: "bolt.fill"
        }
    }

    private var description: String {
        switch mode {
        case .classic: L10n.text("classic_desc", language: language)
        case .zen: L10n.text("zen_desc", language: language)
        case .blitz: L10n.text("blitz_desc", language: language)
        }
    }
}

private struct PlusBenefitCard: View {
    let symbol: String
    let title: String
    let bodyKey: String
    let language: AppLanguage
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.07))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accent.opacity(0.36), lineWidth: 1)
                Image(systemName: symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text(title, language: language))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(L10n.text(bodyKey, language: language))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))
    }
}

private struct PlusRoadmapChip: View {
    let title: String
    let status: String
    let accent: Color

    var body: some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
            Text(status.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color(red: 0.025, green: 0.086, blue: 0.16).opacity(0.92), in: Capsule())
        .overlay(Capsule().stroke(Color(red: 0.29, green: 0.51, blue: 0.70).opacity(0.32), lineWidth: 1))
    }
}

private struct PlusThemePreview: View {
    let theme: CircuitTheme

    var body: some View {
        Canvas { context, size in
            let chrome = ThemeChrome(theme: theme)
            drawBackground(context: &context, size: size, chrome: chrome)
            drawPipe(context: &context, size: size, chrome: chrome)
            drawRocket(context: &context, size: size, chrome: chrome)
        }
        .background(.black.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func drawBackground(context: inout GraphicsContext, size: CGSize, chrome: ThemeChrome) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .linearGradient(Gradient(colors: chrome.background), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
        for index in 0..<18 {
            let x = CGFloat((index * 47 + 13) % 193) / 193 * size.width
            let y = CGFloat((index * 71 + 9) % 197) / 197 * size.height
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.white.opacity(0.34)))
        }
    }

    private func drawPipe(context: inout GraphicsContext, size: CGSize, chrome: ThemeChrome) {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: size.height * 0.62))
        path.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.62))
        path.addQuadCurve(to: CGPoint(x: size.width * 0.70, y: size.height * 0.38), control: CGPoint(x: size.width * 0.66, y: size.height * 0.62))
        path.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.38))
        context.stroke(path, with: .color(.black.opacity(0.78)), style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [.white.opacity(0.80), chrome.cyan, chrome.gold]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(chrome.gold.opacity(0.82)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func drawRocket(context: inout GraphicsContext, size: CGSize, chrome: ThemeChrome) {
        let center = CGPoint(x: size.width * 0.90, y: size.height * 0.37)
        var rocket = Path()
        rocket.move(to: CGPoint(x: center.x, y: center.y - 23))
        rocket.addQuadCurve(to: CGPoint(x: center.x + 11, y: center.y + 12), control: CGPoint(x: center.x + 13, y: center.y - 6))
        rocket.addLine(to: CGPoint(x: center.x + 6, y: center.y + 22))
        rocket.addLine(to: CGPoint(x: center.x - 6, y: center.y + 22))
        rocket.addLine(to: CGPoint(x: center.x - 11, y: center.y + 12))
        rocket.addQuadCurve(to: CGPoint(x: center.x, y: center.y - 23), control: CGPoint(x: center.x - 13, y: center.y - 6))
        context.fill(rocket, with: .linearGradient(Gradient(colors: [chrome.violet, .pink, .white.opacity(0.90)]), startPoint: CGPoint(x: center.x - 12, y: center.y), endPoint: CGPoint(x: center.x + 12, y: center.y)))
        context.stroke(rocket, with: .color(.pink.opacity(0.86)), lineWidth: 1.2)
        context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 9, width: 8, height: 8)), with: .color(chrome.cyan))
    }
}

private struct PlusGlassIconStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.42), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

private struct PlusSkinCardStyle: ButtonStyle {
    let selected: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? accent.opacity(0.92) : .white.opacity(0.09), lineWidth: selected ? 1.5 : 1))
            .shadow(color: selected ? accent.opacity(0.16) : .clear, radius: 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct PlusModeCardStyle: ButtonStyle {
    let active: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(active ? accent.opacity(0.72) : .white.opacity(0.09), lineWidth: active ? 1.4 : 1))
            .shadow(color: active ? accent.opacity(0.10) : .clear, radius: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var rowWidth: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > width {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (rowWidth == 0 ? 0 : spacing) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
