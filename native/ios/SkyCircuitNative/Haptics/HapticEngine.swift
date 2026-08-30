import CoreHaptics

@MainActor
final class HapticEngine {
    private var engine: CHHapticEngine?
    private var enabled = true

    init() {
        prepare()
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            try engine.start()
            self.engine = engine
        } catch {
            self.engine = nil
        }
    }

    func playPlacement(quality: Double) {
        guard enabled, let engine else { return }
        let clamped = min(max(quality, 0), 1)
        let intensity = Float(0.58 - clamped * 0.30)
        let sharpness = Float(0.28 + clamped * 0.68)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
        }
    }

    func playLaunch(combo: Int) {
        guard enabled, let engine else { return }
        let strength = Float(min(1, 0.55 + Double(combo) * 0.06))
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: strength * 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
                ],
                relativeTime: 0,
                duration: 0.12
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: strength),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95),
                ],
                relativeTime: 0.11
            ),
        ]
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
        }
    }
}
