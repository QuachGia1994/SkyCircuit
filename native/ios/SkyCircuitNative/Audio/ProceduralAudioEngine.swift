import AVFAudio

@MainActor
final class ProceduralAudioEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
        player.play()
    }

    func playPlacement(quality: Double) {
        let frequency = 240 + min(max(quality, 0), 1) * 420
        scheduleTone(frequency: frequency, duration: 0.045, amplitude: 0.16)
    }

    func playLaunch(combo: Int) {
        let frequency = 430 + Double(min(combo, 8)) * 55
        scheduleTone(frequency: frequency, duration: 0.16, amplitude: 0.22)
    }

    private func scheduleTone(frequency: Double, duration: Double, amplitude: Float) {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / format.sampleRate
            let envelope = min(1, time / 0.008) * max(0, 1 - time / duration)
            channel[frame] = Float(sin(2 * .pi * frequency * time)) * amplitude * Float(envelope)
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
}
