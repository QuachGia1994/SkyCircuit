import AVFAudio

@MainActor
final class ProceduralAudioEngine {
    enum AudioFailure: Error, Sendable {
        case formatUnavailable
        case sessionConfigurationFailed(String)
        case engineStartFailed(String)
        case musicAssetUnavailable
        case musicPlayerFailed(String)
    }

    private let engine = AVAudioEngine()
    private let effectsPlayer = AVAudioPlayerNode()
    private var backgroundPlayer: AVAudioPlayer?
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
            if musicEnabled { backgroundPlayer?.play() }
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
        guard let backgroundPlayer else { return }
        if enabled {
            activate()
            backgroundPlayer.play()
        } else {
            backgroundPlayer.pause()
        }
    }

    func setMusicEnergy(combo: Int, igniting: Bool) {
        guard musicEnabled, let backgroundPlayer else { return }
        let comboLift = Float(min(combo, 8)) * 0.014
        backgroundPlayer.volume = min(0.90, 0.72 + comboLift + (igniting ? 0.05 : 0))
        backgroundPlayer.rate = min(1.16, 1.08 + Float(min(combo, 8)) * 0.006 + (igniting ? 0.02 : 0))
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
        attachEffectsPlayer(format: format)
        do {
            try configureSession()
            try engine.start()
            effectsPlayer.play()
            try prepareBackgroundMusic()
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

    private func attachEffectsPlayer(format: AVAudioFormat) {
        engine.attach(effectsPlayer)
        engine.connect(effectsPlayer, to: engine.mainMixerNode, format: format)
    }

    private func prepareBackgroundMusic() throws {
        guard let url = Bundle.main.url(forResource: "duru-arcade-vibe", withExtension: "mp3") else {
            throw AudioFailure.musicAssetUnavailable
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.72
            player.enableRate = true
            player.rate = 1.08
            player.prepareToPlay()
            backgroundPlayer = player
            if musicEnabled { player.play() }
        } catch {
            throw AudioFailure.musicPlayerFailed(error.localizedDescription)
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
