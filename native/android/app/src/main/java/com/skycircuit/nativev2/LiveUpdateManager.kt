package com.skycircuit.nativev2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class LiveUpdateManager(private val context: Context) {
    private val manager = NotificationManagerCompat.from(context)

    init {
        val systemManager = context.getSystemService(NotificationManager::class.java)
        systemManager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Daily Run live updates",
                NotificationManager.IMPORTANCE_DEFAULT,
            )
        )
    }

    fun start(state: GameState) {
        post(state)
    }

    fun update(state: GameState) {
        post(state)
    }

    fun finish() {
        manager.cancel(NOTIFICATION_ID)
    }

    private fun post(state: GameState) {
        val progress = (state.dailyProgress * 100).toInt().coerceIn(0, 100)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("SkyCircuit Daily Run")
            .setContentText("🔥 ${state.streak} day streak · rank #${state.rank} · ${state.score} pts")
            .setShortCriticalText("#${state.rank}")
            .setProgress(100, progress, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setRequestPromotedOngoing(true)
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Runtime notification permission is requested by the host UI before production rollout.
        }
    }

    private companion object {
        const val CHANNEL_ID = "daily-run"
        const val NOTIFICATION_ID = 1201
    }
}
