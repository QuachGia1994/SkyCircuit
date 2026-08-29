package com.skycircuit.nativev2

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.compose.ui.unit.dp

class DailyRunWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            DailyRunWidgetContent(streak = 7, rank = 42)
        }
    }
}

class DailyRunWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = DailyRunWidget()
}

@Composable
private fun DailyRunWidgetContent(streak: Int, rank: Int) {
    Column(modifier = GlanceModifier.fillMaxSize().padding(16.dp)) {
        Text("SkyCircuit Daily Run", style = TextStyle(fontWeight = FontWeight.Bold))
        Text("🔥 $streak day streak")
        Text("Mini rank #$rank")
        Text("Open SkyCircuit to start today's run.")
    }
}
