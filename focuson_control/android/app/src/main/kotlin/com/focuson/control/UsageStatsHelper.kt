package com.focuson.control

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process

object UsageStatsHelper {
    fun hasUsagePermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun queryUsage(context: Context, startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val statsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: return emptyList()

        val packageManager = context.packageManager
        val results = mutableListOf<Map<String, Any>>()

        for (stats in statsList) {
            val totalTime = stats.totalTimeInForeground / 1000 // Convert ms to seconds
            if (totalTime <= 0) continue

            val appName = try {
                val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                stats.packageName
            }

            results.add(
                mapOf(
                    "packageName" to stats.packageName,
                    "appName" to appName,
                    "totalTimeInForeground" to totalTime,
                    "lastTimeUsed" to stats.lastTimeUsed
                )
            )
        }

        return results
    }
}
