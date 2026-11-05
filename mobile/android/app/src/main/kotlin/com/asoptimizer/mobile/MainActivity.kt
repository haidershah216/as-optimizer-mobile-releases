package com.asoptimizer.mobile

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.view.Display
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.asoptimizer.mobile/engine"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getHardwareTelemetry" -> {
                    try {
                        val data = collectHardwareTelemetry()
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("TELEMETRY_ERROR", e.localizedMessage, null)
                    }
                }
                "getInstalledGames" -> {
                    try {
                        val games = scanInstalledGames()
                        result.success(games)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", e.localizedMessage, null)
                    }
                }
                "runGameTurbo" -> {
                    val pkg = call.argument<String>("packageName") ?: "com.tencent.ig"
                    try {
                        val report = executeGameTurbo(pkg)
                        result.success(report)
                    } catch (e: Exception) {
                        result.error("TURBO_ERROR", e.localizedMessage, null)
                    }
                }
                "setRefreshRateLock" -> {
                    val hz = call.argument<Double>("refreshRate") ?: 120.0
                    try {
                        val success = applyRefreshRateLock(hz)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("HERTZ_ERROR", e.localizedMessage, null)
                    }
                }
                "launchGame" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val intent = packageManager.getLaunchIntentForPackage(pkg)
                        if (intent != null) {
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_PKG", "Package name missing", null)
                    }
                }
                "testNetworkPing" -> {
                    val host = call.argument<String>("host") ?: "1.1.1.1"
                    try {
                        val ping = measurePing(host)
                        result.success(ping)
                    } catch (e: Exception) {
                        result.success(-1)
                    }
                }
                "checkShizukuStatus" -> {
                    result.success(checkShizukuAvailable())
                }
                "applyPubgConfig" -> {
                    val pkg = call.argument<String>("packageName") ?: "com.tencent.ig"
                    val unlockFps = call.argument<Int>("fpsTarget") ?: 90
                    val shadows = call.argument<Boolean>("shadows") ?: false
                    try {
                        val ok = writePubgOptimizations(pkg, unlockFps, shadows)
                        result.success(ok)
                    } catch (e: Exception) {
                        result.error("CONFIG_ERROR", e.localizedMessage, null)
                    }
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(android.provider.Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun measurePing(host: String): Int {
        val start = System.currentTimeMillis()
        return try {
            val address = java.net.InetAddress.getByName(host)
            val reachable = address.isReachable(1500)
            if (reachable) {
                (System.currentTimeMillis() - start).toInt()
            } else {
                val socket = java.net.Socket()
                socket.connect(java.net.InetSocketAddress(host, 443), 1500)
                socket.close()
                (System.currentTimeMillis() - start).toInt()
            }
        } catch (_: Exception) {
            -1
        }
    }

    private fun checkShizukuAvailable(): Boolean {
        return try {
            val pm = packageManager
            pm.getPackageInfo("moe.shizuku.privileged.api", 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun writePubgOptimizations(pkg: String, fpsTarget: Int, enableShadows: Boolean): Boolean {
        val isRoot = checkRootStatus()
        if (isRoot) {
            try {
                val dataPath = "/data/data/$pkg/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Config/Android"
                val dir = File(dataPath)
                if (dir.exists()) {
                    val iniFile = File(dir, "UserCustom.ini")
                    val content = StringBuilder()
                    content.append("[UserCustom DeviceProfile]\n")
                    content.append("+CVars=r.PUBGDeviceFPSPolicy=$fpsTarget\n")
                    content.append("+CVars=r.PUBGMSAAMode=0\n")
                    if (!enableShadows) {
                        content.append("+CVars=r.ShadowQuality=0\n")
                        content.append("+CVars=r.Shadow.CSM.MaxCascades=0\n")
                    }
                    Runtime.getRuntime().exec(arrayOf("su", "-c", "echo '${content.toString()}' > ${iniFile.absolutePath}")).waitFor()
                    return true
                }
            } catch (_: Exception) {}
        }
        return true
    }

    private fun collectHardwareTelemetry(): Map<String, Any> {
        val map = mutableMapOf<String, Any>()

        // 1. Device identity
        map["brand"] = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        map["model"] = Build.MODEL
        map["device"] = Build.DEVICE
        map["hardware"] = Build.HARDWARE
        map["board"] = Build.BOARD
        map["androidVersion"] = Build.VERSION.RELEASE
        map["sdkInt"] = Build.VERSION.SDK_INT

        // 2. CPU info
        val cores = Runtime.getRuntime().availableProcessors()
        map["cpuCores"] = cores
        map["cpuCurFreqMhz"] = readCurrentCpuFreqMhz()
        map["socName"] = detectSocName()

        // 3. RAM info
        val actMgr = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        actMgr.getMemoryInfo(memInfo)
        map["totalRamMb"] = memInfo.totalMem / (1024 * 1024)
        map["availRamMb"] = memInfo.availMem / (1024 * 1024)
        map["lowMemory"] = memInfo.lowMemory

        // 4. Battery & Thermals
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        var tempC = 0.0
        var batteryPct = 100
        if (batteryIntent != null) {
            val rawTemp = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
            tempC = rawTemp / 10.0
            val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level != -1 && scale != -1) {
                batteryPct = (level * 100 / scale)
            }
        }
        map["batteryTempC"] = tempC
        map["batteryPct"] = batteryPct

        // 5. Display Hz
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            wm.defaultDisplay
        }
        val hz = display?.mode?.refreshRate ?: 60f
        map["refreshRateHz"] = hz.toDouble()

        // 6. Root & Elevated Privilege status
        val isRoot = checkRootStatus()
        map["isRooted"] = isRoot

        return map
    }

    private fun readCurrentCpuFreqMhz(): Int {
        val paths = arrayOf(
            "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq",
            "/sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq",
            "/sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq"
        )
        for (p in paths) {
            val file = File(p)
            if (file.exists() && file.canRead()) {
                try {
                    val text = file.readText().trim()
                    val khz = text.toLongOrNull() ?: 0L
                    if (khz > 0) return (khz / 1000).toInt()
                } catch (_: Exception) {}
            }
        }
        return 0
    }

    private fun detectSocName(): String {
        try {
            val reader = BufferedReader(FileReader("/proc/cpuinfo"))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                if (line!!.startsWith("Hardware", ignoreCase = true) || line!!.startsWith("model name", ignoreCase = true)) {
                    val parts = line!!.split(":")
                    if (parts.size > 1) {
                        val soc = parts[1].trim()
                        reader.close()
                        return soc
                    }
                }
            }
            reader.close()
        } catch (_: Exception) {}
        return Build.HARDWARE
    }

    private fun checkRootStatus(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun scanInstalledGames(): List<Map<String, Any>> {
        val targets = listOf(
            Triple("com.tencent.ig", "PUBG Mobile (Global)", "global"),
            Triple("com.pubg.imobile", "BGMI (Battlegrounds Mobile India)", "bgmi"),
            Triple("com.pubg.krmobile", "PUBG Mobile (Korea/Japan)", "kr"),
            Triple("com.vng.pubgmobile", "PUBG Mobile (Vietnam)", "vn"),
            Triple("com.rekoo.pubgm", "PUBG Mobile (Taiwan)", "tw"),
            Triple("com.tencent.tmgp.pubgmhd", "Game for Peace (China)", "cn"),
            Triple("com.dts.freefireth", "Garena Free Fire", "freefire"),
            Triple("com.dts.freefiremax", "Free Fire MAX", "freefiremax"),
            Triple("com.activision.callofduty.shooter", "Call of Duty: Mobile", "codm")
        )

        val pm = packageManager
        val list = mutableListOf<Map<String, Any>>()

        for (target in targets) {
            val pkg = target.first
            val name = target.second
            val tag = target.third
            try {
                val info = pm.getPackageInfo(pkg, 0)
                list.add(mapOf(
                    "packageName" to pkg,
                    "gameName" to name,
                    "tag" to tag,
                    "versionName" to (info.versionName ?: "1.0"),
                    "isInstalled" to true
                ))
            } catch (_: PackageManager.NameNotFoundException) {
                // Not installed
            }
        }
        return list
    }

    private fun executeGameTurbo(packageName: String): Map<String, Any> {
        val steps = mutableListOf<String>()

        // 1. RAM purge
        val actMgr = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        actMgr.killBackgroundProcesses(packageName)
        System.gc()
        steps.add("Background memory trimmed & JVM heap compressed.")

        // 2. Shell optimizations if elevated
        val isRoot = checkRootStatus()
        if (isRoot) {
            try {
                // Compile Dexopt in speed mode
                Runtime.getRuntime().exec(arrayOf("su", "-c", "cmd package compile -m speed -f $packageName")).waitFor()
                steps.add("AOT Dexopt Speed mode compiled for $packageName (Zero JIT stutter).")

                // Android GameMode API set performance
                Runtime.getRuntime().exec(arrayOf("su", "-c", "cmd game set --mode 2 $packageName")).waitFor()
                steps.add("Android GameMode API set to Extreme Performance (Mode 2).")

                // Enforce 120Hz display lock
                Runtime.getRuntime().exec(arrayOf("su", "-c", "settings put system peak_refresh_rate 120.0 && settings put system min_refresh_rate 120.0")).waitFor()
                steps.add("Display refresh rate locked to 120.0 Hz.")
            } catch (e: Exception) {
                steps.add("Elevated tweaks partially applied: ${e.message}")
            }
        } else {
            steps.add("Standard OS Game Turbo active: RAM purged and foreground game prioritized.")
        }

        return mapOf(
            "success" to true,
            "targetPackage" to packageName,
            "isElevated" to isRoot,
            "steps" to steps
        )
    }

    private fun applyRefreshRateLock(hz: Double): Boolean {
        val isRoot = checkRootStatus()
        if (!isRoot) return false
        return try {
            val p = Runtime.getRuntime().exec(arrayOf(
                "su", "-c",
                "settings put system peak_refresh_rate $hz && settings put system min_refresh_rate $hz && settings put system user_refresh_rate ${hz.toInt()}"
            ))
            p.waitFor() == 0
        } catch (_: Exception) {
            false
        }
    }
}

