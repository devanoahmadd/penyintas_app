package com.onaved.penyintas

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PenyintasWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val daysToLive = widgetData.getInt("days_to_live", 0)
            val budgetFormatted = widgetData.getString("budget_today_formatted", null) ?: "Rp --"
            val status = widgetData.getString("budget_status", "safe") ?: "safe"

            val dayColor = when (status) {
                "danger"  -> Color.parseColor("#E07A3C")
                "caution" -> Color.parseColor("#D4A93C")
                else      -> Color.parseColor("#0F7A3E") // safe
            }

            // Build views once — content is identical for every widget instance.
            val views = RemoteViews(context.packageName, R.layout.penyintas_widget)
            views.setTextViewText(R.id.tv_days, if (daysToLive > 0) daysToLive.toString() else "--")
            views.setTextColor(R.id.tv_days, dayColor)
            views.setTextViewText(R.id.tv_budget, budgetFormatted)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            for (widgetId in appWidgetIds) {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        } catch (e: Exception) {
            // Render layout defaults to avoid "can't load widget" on any crash.
            for (widgetId in appWidgetIds) {
                appWidgetManager.updateAppWidget(
                    widgetId,
                    RemoteViews(context.packageName, R.layout.penyintas_widget),
                )
            }
        }
    }
}
