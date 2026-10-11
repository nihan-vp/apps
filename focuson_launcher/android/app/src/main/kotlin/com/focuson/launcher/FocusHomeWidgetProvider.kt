package com.focuson.launcher

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.focuson.focuson_launcher.R

class FocusHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.focus_widget_layout)
            views.setTextViewText(R.id.widget_title, "FocusON Today")
            views.setTextViewText(R.id.widget_content, "Focus session ready. Open FocusON Launcher.")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
