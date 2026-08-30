import AVFAudio

@MainActor
final class ProceduralAudioEngine {
    enum AudioFailure: Error, Sendable {
        case formatUnavailable
        case engineStartFailed(String)
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private(set) var lastError: AudioFailure?

    init() {
        prepare()
    }

    func playPlacement(quality: Double) {
        let frequency = 240 + min(max(quality, 0), 1) * 420
        scheduleTone(frequency: frequency, duration: 0.045, amplitude: 0.16)
    }

    func playLaunch(combo: Int) {
        let frequency = 430 + Double(min(combo, 8)) * 55
        scheduleTone(frequency: frequency, duration: 0.16, amplitude: 0.22)
    }

    private func prepare() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
            lastError = .formatUnavailable
            return
        }
        self.format = format
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            player.play()
        } catch {
            lastError = .engineStartFailed(error.localizedDescription)
        }
    }

    private func scheduleTone(frequency: Double, duration: Double, amplitude: Float) {
        guard let format else { return }
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }
        writeTone(channel: channel, frames: Int(frameCount), frequency: frequency, duration: duration, amplitude: amplitude, sampleRate: format.sampleRate)
        player.scheduleBuffer(buffer, completionHandler: nil)
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
