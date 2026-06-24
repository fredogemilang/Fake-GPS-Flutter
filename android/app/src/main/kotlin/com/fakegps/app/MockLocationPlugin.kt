package com.fakegps.app

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter Method Channel plugin untuk mock location.
 * Method yang didukung:
 *   - startMock(lat, lng) → bool
 *   - updateLocation(lat, lng)
 *   - startRoute(points, speedKmh) → bool
 *   - stopMock()
 *   - isRunning → bool
 *   - isMockLocationEnabled → bool
 */
class MockLocationPlugin : MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    fun register(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.fakegps.app/mock_location")
        channel.setMethodCallHandler(this)
    }

    fun unregister() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startMock" -> {
                val lat = call.argument<Double>("latitude")
                val lng = call.argument<Double>("longitude")
                if (lat == null || lng == null) {
                    result.error("INVALID_ARGS", "latitude dan longitude diperlukan", null)
                    return
                }
                val service = startAndGetService()
                val success = service.startMock(lat, lng)
                result.success(success)
            }

            "updateLocation" -> {
                val lat = call.argument<Double>("latitude") ?: return
                val lng = call.argument<Double>("longitude") ?: return
                MockLocationService.instance?.updateLocation(lat, lng)
                result.success(null)
            }

            "startRoute" -> {
                val rawPoints = call.argument<List<Map<String, Double>>>("points")
                val speedKmh = call.argument<Double>("speedKmh") ?: 15.0

                if (rawPoints == null || rawPoints.size < 2) {
                    result.error("INVALID_ARGS", "Minimal 2 titik untuk rute", null)
                    return
                }

                val points = rawPoints.map {
                    Pair(it["latitude"]!!, it["longitude"]!!)
                }

                val service = startAndGetService()
                val success = service.startRoute(points, speedKmh)
                result.success(success)
            }

            "stopMock" -> {
                MockLocationService.instance?.stopMock()
                result.success(null)
            }

            "isRunning" -> {
                result.success(MockLocationService.instance?.let { it.hashCode() > 0 } ?: false)
            }

            "isMockLocationEnabled" -> {
                // Cek apakah ada mock location app yang diset di Developer Options
                try {
                    val mockApp = Settings.Secure.getString(
                        context.contentResolver,
                        "mock_location"
                    )
                    // Jika string kosong, tidak ada mock app yang dipilih
                    result.success(!mockApp.isNullOrEmpty())
                } catch (_: Exception) {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Jalankan MockLocationService sebagai foreground service dan kembalikan instance-nya.
     */
    private fun startAndGetService(): MockLocationService {
        val existing = MockLocationService.instance
        if (existing != null) return existing

        val intent = Intent(context, MockLocationService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }

        // Tunggu sebentar agar service sempat onCreate
        var retries = 0
        while (MockLocationService.instance == null && retries < 10) {
            Thread.sleep(50)
            retries++
        }

        return MockLocationService.instance!!
    }
}
