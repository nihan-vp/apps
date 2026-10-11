package com.focuson.launcher

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val LAUNCHER_CHANNEL = "com.focuson.bridge/launcher"
    private val INTEROP_CHANNEL = "com.focuson.bridge/interop"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDefaultLauncher" -> {
                    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                    val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    val currentHomePackage = resolveInfo?.activityInfo?.packageName
                    result.success(currentHomePackage == packageName)
                }
                "openHomeSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            Intent(Settings.ACTION_HOME_SETTINGS)
                        } else {
                            Intent(Settings.ACTION_SETTINGS)
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val alt = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                            alt.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(alt)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("SETTINGS_ERROR", e2.message, null)
                        }
                    }
                }
                "getInstalledApps" -> {
                    try {
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
                        val pkgAppsList = packageManager.queryIntentActivities(mainIntent, 0)
                        val appList = mutableListOf<Map<String, Any>>()

                        for (resolveInfo in pkgAppsList) {
                            val pkg = resolveInfo.activityInfo.packageName
                            if (pkg == packageName) continue // Exclude launcher itself from list
                            val label = resolveInfo.loadLabel(packageManager).toString()
                            val isSystem = (resolveInfo.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                            val appMap = mapOf(
                                "appName" to label,
                                "packageName" to pkg,
                                "isSystemApp" to isSystem
                            )
                            appList.add(appMap)
                        }
                        result.success(appList)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "launchApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARG", "Package name required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEROP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchIntentUri" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriStr))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_URI", "Uri required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
