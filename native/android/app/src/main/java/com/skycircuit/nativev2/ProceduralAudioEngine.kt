package com.skycircuit.nativev2

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.sin

class ProceduralAudioEngine : AutoCloseable {
    private val sampleRate = 44_100
    @Volatile private var closed = false

    fun playPlacement(quality: Float) {
        val frequency = 240.0 + quality.coerceIn(0f, 1f) * 420.0
        playTone(frequency, 45, 0.16f)
    }

    fun playLaunch(combo: Int) {
        playTone(430.0 + combo.coerceAtMost(8) * 55.0, 160, 0.22f)
    }

    private fun playTone(frequency: Double, durationMs: Int, amplitude: Float) {
        if (closed) return
        thread(name = "SkyCircuitAudio", isDaemon = true) {
            val samples = sampleRate * durationMs / 1000
            val pcm = ShortArray(samples)
            for (index in pcm.indices) {
                val time = index.toDouble() / sampleRate
                val progress = index.toDouble() / samples.coerceAtLeast(1)
                val envelope = minOf(1.0, time / 0.008) * maxOf(0.0, 1.0 - progress)
                pcm[index] = (sin(2.0 * PI * frequency * time) * Short.MAX_VALUE * amplitude * envelope).toInt().toShort()
            }
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(pcm.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()
            try {
                track.write(pcm, 0, pcm.size)
                track.play()
                Thread.sleep(durationMs.toLong() + 12)
            } finally {
                track.release()
            }
        }
    }

    override fun close() {
        closed = true
    }
}
