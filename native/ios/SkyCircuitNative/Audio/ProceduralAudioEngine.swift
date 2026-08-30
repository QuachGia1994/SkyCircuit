import AVFAudio

@MainActor
final class ProceduralAudioEngine {
    enum AudioFailure: Error, Sendable {
        case formatUnavailable
        case sessionConfigurationFailed(String)
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

    func activate() {
        do {
            try configureSession()
            if !engine.isRunning { try engine.start() }
            if !effectsPlayer.isPlaying { effectsPlayer.play() }
            if !musicPlayer.isPlaying { musicPlayer.play() }
            setMusicEnergy(combo: 1, igniting: false)
        } catch {
            lastError = .engineStartFailed(error.localizedDescription)
        }
    }

    func setEffectsEnabled(_ enabled: Bool) {
        effectsEnabled = enabled
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        if enabled { activate() }
        musicPlayer.volume = enabled ? 0.64 : 0
    }

    func setMusicEnergy(combo: Int, igniting: Bool) {
        guard musicEnabled else { return }
        let comboLift = Float(min(combo, 8)) * 0.02
        musicPlayer.volume = min(0.88, 0.62 + comboLift + (igniting ? 0.10 : 0))
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

    func playFireworkBurst(rocketCount: Int) {
        guard effectsEnabled else { return }
        let lift = Double(min(rocketCount, 4)) * 26
        scheduleChord(frequencies: [659.25 + lift, 783.99 + lift, 1046.50 + lift], duration: 0.32, amplitude: 0.16)
    }

    private func prepare() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
            lastError = .formatUnavailable
            return
        }
        self.format = format
        attachPlayers(format: format)
        do {
            try configureSession()
            try engine.start()
            effectsPlayer.play()
            try startMusic(format: format)
        } catch let failure as AudioFailure {
            lastError = failure
        } catch {
            lastError = .engineStartFailed(error.localizedDescription)
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            throw AudioFailure.sessionConfigurationFailed(error.localizedDescription)
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
        musicPlayer.volume = 0.64
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
            channel[frame] = Float((pad * 0.068 + shimmer * 0.030) * breath)
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

    private func scheduleChord(frequencies: [Double], duration: Double, amplitude: Float) {
        guard let format else { return }
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / format.sampleRate
            let envelope = min(1, time / 0.012) * max(0, 1 - time / duration)
            let sample = frequencies.reduce(0.0) { $0 + sin(2 * .pi * $1 * time) } / Double(max(1, frequencies.count))
            channel[frame] = Float(sample) * amplitude * Float(envelope)
        }
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
