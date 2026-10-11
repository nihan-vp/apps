package com.focuson.tools

import android.app.ActivityManager
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.focuson.bridge/tools"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memInfo = ActivityManager.MemoryInfo()
                    actManager.getMemoryInfo(memInfo)

                    val info = mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "device" to Build.DEVICE,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "board" to Build.BOARD,
                        "cpuAbi" to Build.SUPPORTED_ABIS.joinToString(", "),
                        "totalRamBytes" to memInfo.totalMem,
                        "availRamBytes" to memInfo.availMem,
                        "lowMemory" to memInfo.lowMemory
                    )
                    result.success(info)
                }

                "getStorageInfo" -> {
                    val path = Environment.getDataDirectory()
                    val stat = StatFs(path.path)
                    val blockSize = stat.blockSizeLong
                    val totalBlocks = stat.blockCountLong
                    val availableBlocks = stat.availableBlocksLong

                    val totalBytes = totalBlocks * blockSize
                    val freeBytes = availableBlocks * blockSize
                    val usedBytes = totalBytes - freeBytes

                    val storage = mapOf(
                        "totalBytes" to totalBytes,
                        "freeBytes" to freeBytes,
                        "usedBytes" to usedBytes,
                        "path" to path.absolutePath
                    )
                    result.success(storage)
                }

                "getLocalIpAddress" -> {
                    var ip = "127.0.0.1"
                    try {
                        val interfaces = NetworkInterface.getNetworkInterfaces()
                        while (interfaces.hasMoreElements()) {
                            val networkInterface = interfaces.nextElement()
                            val addresses = networkInterface.inetAddresses
                            while (addresses.hasMoreElements()) {
                                val address = addresses.nextElement()
                                if (!address.isLoopbackAddress && address is Inet4Address) {
                                    ip = address.hostAddress ?: ip
                                    break
                                }
                            }
                        }
                    } catch (e: Exception) {
                        ip = "127.0.0.1"
                    }
                    result.success(ip)
                }

                else -> result.notImplemented()
            }
        }
    }
}
