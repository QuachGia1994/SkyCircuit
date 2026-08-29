package com.skycircuit.nativev2

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

enum class GamePhase { Playing, Paused, GameOver }

data class GameState(
    val phase: GamePhase = GamePhase.Playing,
    val score: Int = 0,
    val combo: Int = 1,
    val streak: Int = 1,
    val rank: Int = 42,
    val dailyProgress: Float = 0f,
    val renderMilliseconds: Float = 0f,
    val dailyRunActive: Boolean = false,
)

class GameEngine(context: Context) : AutoCloseable {
    private val _state = MutableStateFlow(GameState())
    val state: StateFlow<GameState> = _state.asStateFlow()

    private val haptics = HapticEngine(context)
    private val audio = ProceduralAudioEngine()
    private val liveUpdate = LiveUpdateManager(context)
    val billing = BillingManager(context)

    fun togglePause() {
        _state.update { current ->
            current.copy(phase = if (current.phase == GamePhase.Paused) GamePhase.Playing else GamePhase.Paused)
        }
    }

    fun restart() {
        _state.value = GameState(streak = _state.value.streak, rank = _state.value.rank)
        liveUpdate.finish()
    }

    fun startDailyRun() {
        _state.update { it.copy(phase = GamePhase.Playing, dailyProgress = 0f, dailyRunActive = true) }
        liveUpdate.start(_state.value)
    }

    fun finishDailyRun() {
        _state.update { it.copy(phase = GamePhase.GameOver, dailyProgress = 1f, dailyRunActive = false) }
        liveUpdate.finish()
    }

    fun registerRotationQuality(quality: Float) {
        val clamped = quality.coerceIn(0f, 1f)
        haptics.playPlacement(clamped)
        audio.playPlacement(clamped)
        _state.update { current ->
            if (clamped > 0.92f) {
                current.copy(
                    score = current.score + 10 * current.combo,
                    dailyProgress = (current.dailyProgress + 0.04f).coerceAtMost(1f),
                )
            } else {
                current.copy(combo = 1)
            }
        }
        if (_state.value.dailyRunActive) liveUpdate.update(_state.value)
    }

    fun registerLaunch() {
        _state.update { current ->
            val nextCombo = (current.combo + 1).coerceAtMost(9)
            current.copy(combo = nextCombo, score = current.score + 100 * nextCombo)
        }
        haptics.playLaunch(_state.value.combo)
        audio.playLaunch(_state.value.combo)
        if (_state.value.dailyRunActive) liveUpdate.update(_state.value)
    }

    fun recordRenderTime(milliseconds: Float) {
        if (kotlin.math.abs(_state.value.renderMilliseconds - milliseconds) < 0.25f) return
        _state.update { it.copy(renderMilliseconds = milliseconds) }
    }

    override fun close() {
        audio.close()
        billing.close()
        liveUpdate.finish()
    }
}
