import SwiftUI

@MainActor
struct SettingsView: View {
    @Bindable var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SkyBackground(theme: engine.theme)
                ScrollView {
                    VStack(spacing: 14) {
                        languageCard
                        toggleCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle(L10n.text("settings", language: engine.language))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("close", language: engine.language)) { dismiss() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, engine.language.locale)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.text("language", language: engine.language), systemImage: "globe")
                .font(.headline.weight(.bold))
            ForEach(AppLanguage.allCases) { language in
                Button {
                    engine.setLanguage(language)
                } label: {
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if engine.language == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(chrome.cyan)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if language != .french { Divider().opacity(0.18) }
            }
        }
        .glassCard()
    }

    private var toggleCard: some View {
        VStack(spacing: 2) {
            settingToggle("music", symbol: "music.note", isOn: musicBinding)
            Divider().opacity(0.18)
            settingToggle("sound_effects", symbol: "speaker.wave.2.fill", isOn: effectsBinding)
            Divider().opacity(0.18)
            settingToggle("haptics", symbol: "waveform.path", isOn: hapticsBinding)
        }
        .glassCard()
    }

    private func settingToggle(_ key: String, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(L10n.text(key, language: engine.language), systemImage: symbol)
                .font(.subheadline.weight(.semibold))
        }
        .tint(chrome.cyan)
        .padding(.vertical, 10)
    }

    private var musicBinding: Binding<Bool> {
        Binding(get: { engine.musicEnabled }, set: engine.setMusicEnabled)
    }

    private var effectsBinding: Binding<Bool> {
        Binding(get: { engine.soundEffectsEnabled }, set: engine.setSoundEffectsEnabled)
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(get: { engine.hapticsEnabled }, set: engine.setHapticsEnabled)
    }

    private var chrome: ThemeChrome { ThemeChrome(theme: engine.theme) }
}

private extension View {
    func glassCard() -> some View {
        padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}
