import SwiftUI

private struct TutorialPage {
    let eyebrowKey: String
    let titleKey: String
    let bodyKey: String
    let accent: Color
}

struct TutorialView: View {
    let theme: CircuitTheme
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    private let pages = [
        TutorialPage(eyebrowKey: "tutorial_step1_eyebrow", titleKey: "tutorial_step1_title", bodyKey: "tutorial_step1_body", accent: .cyan),
        TutorialPage(eyebrowKey: "tutorial_step2_eyebrow", titleKey: "tutorial_step2_title", bodyKey: "tutorial_step2_body", accent: .orange),
        TutorialPage(eyebrowKey: "tutorial_step3_eyebrow", titleKey: "tutorial_step3_title", bodyKey: "tutorial_step3_body", accent: .purple),
    ]

    var body: some View {
        ZStack {
            SkyBackground(theme: theme)
            Color.black.opacity(0.28).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    TutorialCircuitDemo(step: step, theme: theme)
                        .frame(height: 310)
                    copyPanel
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 34).stroke(chrome.cyan.opacity(0.42), lineWidth: 1.2))
                .shadow(color: .black.opacity(0.58), radius: 34, y: 18)
                .padding(.horizontal, 18)
                .padding(.vertical, 22)
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, language.locale)
    }

    private var copyPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("\(step + 1)")
                    .font(.title3.weight(.black))
                    .foregroundStyle(current.accent)
                    .frame(width: 48, height: 48)
                    .background(.thinMaterial, in: Circle())
                    .overlay(Circle().stroke(current.accent.opacity(0.72), lineWidth: 1.4))
                Text(L10n.text(current.eyebrowKey, language: language))
                    .font(.caption.weight(.black))
                    .tracking(2.2)
                    .foregroundStyle(current.accent)
            }
            Text(L10n.text(current.titleKey, language: language))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(L10n.text(current.bodyKey, language: language))
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
                .lineSpacing(6)
            progressDots
            actions
        }
        .padding(24)
        .background(Color.black.opacity(0.18))
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == step ? current.accent : Color.white.opacity(0.16))
                    .frame(width: index == step ? 42 : 28, height: 6)
                    .animation(.snappy(duration: 0.25), value: step)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button(L10n.text(step == 0 ? "skip" : "back", language: language)) {
                if step == 0 { dismiss() } else { changeStep(-1) }
            }
            .buttonStyle(GameControlStyle(kind: .secondary, accent: chrome.cyan))

            Button(L10n.text(step == pages.count - 1 ? "got_it" : "next", language: language)) {
                if step == pages.count - 1 { dismiss() } else { changeStep(1) }
            }
            .buttonStyle(GameControlStyle(kind: .primary, accent: chrome.gold))
        }
    }

    private func changeStep(_ delta: Int) {
        let next = min(max(step + delta, 0), pages.count - 1)
        withAnimation(.snappy(duration: 0.28)) { step = next }
    }

    private var current: TutorialPage { pages[step] }
    private var chrome: ThemeChrome { ThemeChrome(theme: theme) }
}

private struct TutorialCircuitDemo: View {
    let step: Int
    let theme: CircuitTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.2) / 2.2
                drawBackdrop(context: &context, size: size)
                drawCircuit(context: &context, size: size, phase: phase)
            }
        }
        .background(demoBackground)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34))
        .accessibilityHidden(true)
    }

    private var demoBackground: some ShapeStyle {
        LinearGradient(colors: [Color(red: 0.02, green: 0.11, blue: 0.24), Color(red: 0.01, green: 0.025, blue: 0.07)], startPoint: .top, endPoint: .bottom)
    }

    private func drawBackdrop(context: inout GraphicsContext, size: CGSize) {
        for row in 0..<5 {
            for column in 0..<9 {
                let x = size.width * CGFloat(column + 1) / 10
                let y = size.height * CGFloat(row + 1) / 6
                let dot = CGRect(x: x - 1.4, y: y - 1.4, width: 2.8, height: 2.8)
                context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.35)))
            }
        }
    }

    private func drawCircuit(context: inout GraphicsContext, size: CGSize, phase: Double) {
        let y = size.height * 0.52
        let source = CGPoint(x: size.width * 0.14, y: y)
        let rocket = CGPoint(x: size.width * 0.86, y: y)
        drawSource(context: &context, center: source)
        drawPipes(context: &context, size: size, y: y, phase: phase)
        if step == 2 { drawIgnition(context: &context, size: size, y: y, phase: phase) }
        drawRocket(context: &context, center: rocket, launching: step == 2 && phase > 0.68)
    }

    private func drawPipes(context: inout GraphicsContext, size: CGSize, y: CGFloat, phase: Double) {
        let spans = [(0.21, 0.38), (0.43, 0.61), (0.66, 0.79)]
        for (index, span) in spans.enumerated() {
            var copy = context
            let start = CGPoint(x: size.width * span.0, y: y)
            let end = CGPoint(x: size.width * span.1, y: y)
            if index == 1 && step == 0 {
                let angle = -38.0 + sin(phase * .pi * 2) * 38.0
                drawRotatingPipe(context: &copy, start: start, end: end, angle: angle)
            } else {
                drawMetalPipe(context: &copy, start: start, end: end)
            }
        }
    }

    private func drawRotatingPipe(context: inout GraphicsContext, start: CGPoint, end: CGPoint, angle: Double) {
        let center = CGPoint(x: (start.x + end.x) / 2, y: start.y)
        let length = end.x - start.x
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: .degrees(angle))
        drawMetalPipe(context: &context, start: CGPoint(x: -length / 2, y: 0), end: CGPoint(x: length / 2, y: 0))
    }

    private func drawMetalPipe(context: inout GraphicsContext, start: CGPoint, end: CGPoint) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(.black.opacity(0.82)), style: StrokeStyle(lineWidth: 28, lineCap: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [.white.opacity(0.9), Color(red: 0.48, green: 0.59, blue: 0.70), Color(red: 0.10, green: 0.15, blue: 0.22)]), startPoint: start, endPoint: CGPoint(x: start.x, y: start.y + 22)), style: StrokeStyle(lineWidth: 20, lineCap: .round))
        context.stroke(path, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private func drawSource(context: inout GraphicsContext, center: CGPoint) {
        let outer = CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52)
        context.fill(Path(ellipseIn: outer), with: .color(Color(red: 0.12, green: 0.16, blue: 0.22)))
        context.stroke(Path(ellipseIn: outer), with: .color(.orange.opacity(0.75)), lineWidth: 4)
        let core = CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)
        var glow = context
        glow.addFilter(.shadow(color: .orange.opacity(0.85), radius: 16))
        glow.fill(Path(ellipseIn: core), with: .color(.yellow))
    }

    private func drawIgnition(context: inout GraphicsContext, size: CGSize, y: CGFloat, phase: Double) {
        let startX = size.width * 0.19
        let endX = size.width * 0.82
        let progress = min(1, max(0, phase / 0.76))
        var path = Path()
        path.move(to: CGPoint(x: startX, y: y))
        path.addLine(to: CGPoint(x: startX + (endX - startX) * progress, y: y))
        var glow = context
        glow.addFilter(.shadow(color: .orange.opacity(0.9), radius: 15))
        glow.stroke(path, with: .linearGradient(Gradient(colors: [.white, .yellow, .orange]), startPoint: CGPoint(x: startX, y: y), endPoint: CGPoint(x: endX, y: y)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
    }

    private func drawRocket(context: inout GraphicsContext, center: CGPoint, launching: Bool) {
        var rocket = Path()
        rocket.move(to: CGPoint(x: center.x, y: center.y - 38))
        rocket.addCurve(to: CGPoint(x: center.x + 15, y: center.y + 24), control1: CGPoint(x: center.x + 18, y: center.y - 20), control2: CGPoint(x: center.x + 18, y: center.y + 10))
        rocket.addLine(to: CGPoint(x: center.x - 15, y: center.y + 24))
        rocket.addCurve(to: CGPoint(x: center.x, y: center.y - 38), control1: CGPoint(x: center.x - 18, y: center.y + 10), control2: CGPoint(x: center.x - 18, y: center.y - 20))
        context.fill(rocket, with: .linearGradient(Gradient(colors: [.pink, Color(red: 1, green: 0.42, blue: 0.72), Color(red: 0.45, green: 0.08, blue: 0.34)]), startPoint: CGPoint(x: center.x - 12, y: center.y), endPoint: CGPoint(x: center.x + 12, y: center.y)))
        let window = CGRect(x: center.x - 6, y: center.y - 16, width: 12, height: 12)
        context.fill(Path(ellipseIn: window), with: .color(.cyan))
        if launching { drawFlame(context: &context, center: center) }
    }

    private func drawFlame(context: inout GraphicsContext, center: CGPoint) {
        var flame = Path()
        flame.move(to: CGPoint(x: center.x - 7, y: center.y + 22))
        flame.addQuadCurve(to: CGPoint(x: center.x, y: center.y + 62), control: CGPoint(x: center.x - 12, y: center.y + 42))
        flame.addQuadCurve(to: CGPoint(x: center.x + 7, y: center.y + 22), control: CGPoint(x: center.x + 12, y: center.y + 42))
        var glow = context
        glow.addFilter(.shadow(color: .orange.opacity(0.85), radius: 15))
        glow.fill(flame, with: .linearGradient(Gradient(colors: [.white, .yellow, .orange, .pink.opacity(0)]), startPoint: CGPoint(x: center.x, y: center.y + 22), endPoint: CGPoint(x: center.x, y: center.y + 62)))
    }
}
