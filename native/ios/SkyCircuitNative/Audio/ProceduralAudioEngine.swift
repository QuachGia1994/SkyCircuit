import AVFAudio

@MainActor
final class ProceduralAudioEngine {
    enum AudioFailure: Error, Sendable {
        case formatUnavailable
        case engineStartFailed(String)
        case musicBufferUnavailable
    }

    private let engine = AVAudioEngine()
    private let effectsPlayer = AVAudioPlayerNode()
    private let musicPlayer = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private var effectsEnabled = true
    private var musicEnabled = true
    private(set) var lastError: AudioFailure?

    init() {
        prepare()
    }

    func setEffectsEnabled(_ enabled: Bool) {
        effectsEnabled = enabled
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        musicPlayer.volume = enabled ? 0.34 : 0
    }

    func setMusicEnergy(combo: Int, igniting: Bool) {
        guard musicEnabled else { return }
        let comboLift = Float(min(combo, 8)) * 0.018
        musicPlayer.volume = min(0.56, 0.32 + comboLift + (igniting ? 0.08 : 0))
    }

    func playPlacement(quality: Double) {
        guard effectsEnabled else { return }
        let frequency = 240 + min(max(quality, 0), 1) * 420
        scheduleTone(frequency: frequency, duration: 0.045, amplitude: 0.16)
    }

    func playLaunch(combo: Int) {
        guard effectsEnabled else { return }
        let frequency = 430 + Double(min(combo, 8)) * 55
        scheduleTone(frequency: frequency, duration: 0.16, amplitude: 0.22)
    }

    private func prepare() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
            lastError = .formatUnavailable
            return
        }
        self.format = format
        attachPlayers(format: format)
        do {
            try engine.start()
            effectsPlayer.play()
            try startMusic(format: format)
        } catch let failure as AudioFailure {
            lastError = failure
        } catch {
            lastError = .engineStartFailed(error.localizedDescription)
        }
    }

    private func attachPlayers(format: AVAudioFormat) {
        engine.attach(effectsPlayer)
        engine.attach(musicPlayer)
        engine.connect(effectsPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
    }

    private func startMusic(format: AVAudioFormat) throws {
        guard let buffer = makeMusicBuffer(format: format) else {
            throw AudioFailure.musicBufferUnavailable
        }
        musicPlayer.volume = 0.34
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicPlayer.play()
    }

    private func makeMusicBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 8.0
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        writeMusic(channel: channel, frames: Int(frameCount), sampleRate: format.sampleRate)
        return buffer
    }

    private func writeMusic(channel: UnsafeMutablePointer<Float>, frames: Int, sampleRate: Double) {
        let roots = [110.0, 130.81, 146.83, 98.0]
        for frame in 0..<frames {
            let time = Double(frame) / sampleRate
            let root = roots[min(roots.count - 1, Int(time / 2.0))]
            let breath = 0.72 + 0.28 * sin(.pi * time / 2.0)
            let pad = sin(2 * .pi * root * time)
                + 0.48 * sin(2 * .pi * root * 1.5 * time + 0.7)
                + 0.24 * sin(2 * .pi * root * 2.0 * time + 1.4)
            let shimmer = 0.15 * sin(2 * .pi * 0.19 * time) * sin(2 * .pi * root * 4 * time)
            channel[frame] = Float((pad * 0.035 + shimmer * 0.018) * breath)
        }
    }

    private func scheduleTone(frequency: Double, duration: Double, amplitude: Float) {
        guard let format else { return }
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }
        writeTone(channel: channel, frames: Int(frameCount), frequency: frequency, duration: duration, amplitude: amplitude, sampleRate: format.sampleRate)
        effectsPlayer.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func writeTone(
        channel: UnsafeMutablePointer<Float>,
        frames: Int,
        frequency: Double,
        duration: Double,
        amplitude: Float,
        sampleRate: Double
    ) {
        for frame in 0..<frames {
            let time = Double(frame) / sampleRate
            let envelope = min(1, time / 0.008) * max(0, 1 - time / duration)
            channel[frame] = Float(sin(2 * .pi * frequency * time)) * amplitude * Float(envelope)
        }
    }
}
