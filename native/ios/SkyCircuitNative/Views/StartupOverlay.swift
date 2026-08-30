import SwiftUI

struct StartupOverlay: View {
    let theme: CircuitTheme
    let language: AppLanguage

    var body: some View {
        ZStack {
            SkyBackground(theme: theme)
            VStack(spacing: 18) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .shadow(color: chrome.cyan.opacity(0.34), radius: 28)
                Text("SkyCircuit")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, chrome.cyan, chrome.gold], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: chrome.cyan.opacity(0.24), radius: 18)
                Text(L10n.text("startup_tagline", language: language))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(4.2)
                    .foregroundStyle(chrome.gold)
                ignitionLine
            }
            .padding(28)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SkyCircuit. \(L10n.text("startup_tagline", language: language))")
        .transition(.opacity.combined(with: .scale(scale: 1.02)))
    }

    private var ignitionLine: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6
                var rail = Path()
                rail.move(to: CGPoint(x: 0, y: size.height / 2))
                rail.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                context.stroke(rail, with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                let litWidth = size.width * phase
                var lit = Path()
                lit.move(to: CGPoint(x: 0, y: size.height / 2))
                lit.addLine(to: CGPoint(x: litWidth, y: size.height / 2))
                context.stroke(lit, with: .linearGradient(Gradient(colors: [chrome.cyan, chrome.gold, .orange]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                let spark = CGRect(x: max(0, litWidth - 5), y: size.height / 2 - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: spark), with: .color(.white))
            }
        }
        .frame(width: 170, height: 18)
        .accessibilityHidden(true)
    }

    private var chrome: ThemeChrome { ThemeChrome(theme: theme) }
}
