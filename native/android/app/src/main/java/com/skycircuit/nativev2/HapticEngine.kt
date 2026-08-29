package com.skycircuit.nativev2

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

class HapticEngine(context: Context) {
    private val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        context.getSystemService(VibratorManager::class.java).defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    fun playPlacement(quality: Float) {
        val clamped = quality.coerceIn(0f, 1f)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val primitive = if (clamped > 0.8f) {
                VibrationEffect.Composition.PRIMITIVE_LOW_TICK
            } else {
                VibrationEffect.Composition.PRIMITIVE_TICK
            }
            val supported = vibrator.arePrimitivesSupported(primitive).firstOrNull() == true
            if (supported) {
                val scale = 0.62f - clamped * 0.34f
                vibrator.vibrate(
                    VibrationEffect.startComposition()
                        .addPrimitive(primitive, scale.coerceIn(0.15f, 1f))
                        .compose()
                )
                return
            }
        }
        vibrator.vibrate(VibrationEffect.createOneShot(if (clamped > 0.8f) 12 else 22, 120))
    }

    fun playLaunch(combo: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val click = VibrationEffect.Composition.PRIMITIVE_CLICK
            val rise = VibrationEffect.Composition.PRIMITIVE_QUICK_RISE
            val supported = vibrator.arePrimitivesSupported(rise, click).all { it }
            if (supported) {
                val strength = (0.55f + combo.coerceAtMost(8) * 0.05f).coerceAtMost(1f)
                vibrator.vibrate(
                    VibrationEffect.startComposition()
                        .addPrimitive(rise, strength * 0.7f)
                        .addPrimitive(click, strength, 28)
                        .compose()
                )
                return
            }
        }
        vibrator.vibrate(VibrationEffect.createOneShot(55, 190))
    }
}
