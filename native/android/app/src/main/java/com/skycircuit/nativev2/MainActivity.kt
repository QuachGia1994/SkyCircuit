package com.skycircuit.nativev2

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                SkyCircuitNativeScreen()
            }
        }
    }
}

@Composable
private fun SkyCircuitNativeScreen() {
    val context = androidx.compose.ui.platform.LocalContext.current
    val engine = remember { GameEngine(context.applicationContext) }
    val state by engine.state.collectAsState()

    DisposableEffect(engine) {
        onDispose { engine.close() }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFF081C40), Color(0xFF030814))
                )
            )
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text("SkyCircuit Native V2", style = MaterialTheme.typography.headlineMedium, color = Color.White)
            Hud(state)

            Surface(
                modifier = Modifier.fillMaxWidth().weight(1f),
                shape = RoundedCornerShape(24.dp),
                tonalElevation = 6.dp,
            ) {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { CircuitRenderView(it, engine) },
                )
            }

            Text(
                text = "Render ${"%.2f".format(state.renderMilliseconds)} ms · target < 8.3 ms at 120 Hz",
                color = Color(0xFF9FC8E8),
                style = MaterialTheme.typography.labelSmall,
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = engine::togglePause, modifier = Modifier.weight(1f)) {
                    Text(if (state.phase == GamePhase.Paused) "Resume" else "Pause")
                }
                Button(onClick = engine::startDailyRun, modifier = Modifier.weight(1f)) {
                    Text("Daily Run")
                }
                Button(onClick = engine::restart, modifier = Modifier.weight(1f)) {
                    Text("Restart")
                }
            }
        }
    }
}

@Composable
private fun Hud(state: GameState) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        HudCell("SCORE", state.score.toString(), Modifier.weight(1f))
        HudCell("COMBO", "×${state.combo}", Modifier.weight(1f))
        HudCell("STREAK", state.streak.toString(), Modifier.weight(1f))
        HudCell("RANK", "#${state.rank}", Modifier.weight(1f))
    }
}

@Composable
private fun HudCell(label: String, value: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        color = Color(0xAA102B4E),
        tonalElevation = 4.dp,
    ) {
        Column(modifier = Modifier.padding(10.dp)) {
            Text(label, color = Color(0xFF8EB5D3), style = MaterialTheme.typography.labelSmall)
            Spacer(Modifier.height(2.dp))
            Text(value, color = Color.White, style = MaterialTheme.typography.titleMedium)
        }
    }
}
