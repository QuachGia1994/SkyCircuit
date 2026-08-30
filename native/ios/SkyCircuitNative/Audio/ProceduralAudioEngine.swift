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
            engine.mainMixerNode.outputVolume = 1.0
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
        musicPlayer.volume = enabled ? 0.78 : 0
    }

    func setMusicEnergy(combo: Int, igniting: Bool) {
        guard musicEnabled else { return }
        let comboLift = Float(min(combo, 8)) * 0.018
        musicPlayer.volume = min(0.96, 0.76 + comboLift + (igniting ? 0.08 : 0))
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
        scheduleFireworkBlast(rocketCount: rocketCount)
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
            try session.setCategory(.playback, mode: .default)
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
        musicPlayer.volume = 0.78
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
            let presence = 0.34 * sin(2 * .pi * root * 4.0 * time + 0.3)
                + 0.22 * sin(2 * .pi * root * 6.0 * time + 1.1)
                + 0.12 * sin(2 * .pi * root * 9.0 * time + 2.0)
            let shimmer = 0.15 * sin(2 * .pi * 0.19 * time) * sin(2 * .pi * root * 8.0 * time)
            let mixed = (pad * 0.060 + presence * 0.16 + shimmer * 0.034) * breath
            channel[frame] = Float(tanh(mixed * 1.35))
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

    private func scheduleFireworkBlast(rocketCount: Int) {
        guard let format else { return }
        let duration = 0.46
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }
        let lift = Double(min(rocketCount, 4)) * 32
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / format.sampleRate
            let pseudo = sin(Double(frame) * 12.9898 + 78.233) * 43_758.5453
            let white = (pseudo - floor(pseudo)) * 2 - 1
            let crack = white * exp(-time * 24)
            let boom = sin(2 * .pi * (190 + lift * 0.15) * time) * exp(-time * 8)
            let sparkle = (sin(2 * .pi * (1_450 + lift) * time) + sin(2 * .pi * (2_350 + lift) * time)) * 0.5 * exp(-time * 5.5)
            let tail = white * 0.22 * exp(-time * 6.5)
            let sample = crack * 0.54 + boom * 0.24 + sparkle * 0.30 + tail
            channel[frame] = Float(tanh(sample * 1.2))
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
