package com.parsik.toolbax

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val telephonyChannel = "com.parsik.toolbax/telephony"
    private val appsChannel = "com.parsik.toolbax/apps"
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // getNetworkOperatorName() (unlike the SIM serial, phone number, or
        // IMEI) requires no runtime permission — it's just the carrier's
        // public display name for the currently registered network.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, telephonyChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getNetworkOperatorName") {
                    val telephonyManager =
                        getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                    val name = telephonyManager?.networkOperatorName
                    result.success(if (name.isNullOrBlank()) null else name)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listApps" -> backgroundExecutor.execute {
                        val apps = listInstalledApps()
                        mainHandler.post { result.success(apps) }
                    }
                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                            return@setMethodCallHandler
                        }
                        backgroundExecutor.execute {
                            val bytes = getAppIconBytes(packageName)
                            mainHandler.post { result.success(bytes) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Excludes pure system apps but keeps ones a user later updated (e.g. a
    // stock Gmail updated via the store) — those are FLAG_SYSTEM *and*
    // FLAG_UPDATED_SYSTEM_APP, and are meaningfully user-relevant.
    private fun listInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        @Suppress("DEPRECATION")
        val installedApps = pm.getInstalledApplications(0)

        return installedApps.mapNotNull { appInfo ->
            val isPureSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0
            if (isPureSystemApp) return@mapNotNull null

            try {
                @Suppress("DEPRECATION")
                val packageInfo: PackageInfo = pm.getPackageInfo(appInfo.packageName, 0)
                val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode.toLong()
                }

                val apkPath = appInfo.sourceDir
                val splitApkPaths = appInfo.splitSourceDirs?.toList() ?: emptyList()

                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to appInfo.loadLabel(pm).toString(),
                    "versionName" to (packageInfo.versionName ?: ""),
                    "versionCode" to versionCode,
                    "firstInstallTime" to packageInfo.firstInstallTime,
                    "lastUpdateTime" to packageInfo.lastUpdateTime,
                    "apkPath" to apkPath,
                    "splitApkPaths" to splitApkPaths,
                )
            } catch (e: PackageManager.NameNotFoundException) {
                null
            }
        }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 108
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 108
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
