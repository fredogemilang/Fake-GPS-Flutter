package com.fakegps.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import kotlin.math.*

/**
 * Foreground service yang meng-inject mock GPS location ke Android.
 * Menangani dua mode: Teleport (static) & Perjalanan (route interpolation).
 */
class MockLocationService : Service() {

    private lateinit var locationManager: LocationManager
    private var mockLatitude: Double = 0.0
    private var mockLongitude: Double = 0.0
    private var isRunning: Boolean = false

    // Route state
    private var routePoints: List<Pair<Double, Double>> = emptyList()
    private var currentRouteIndex: Int = 0
    private var speedMetersPerSecond: Double = 0.0
    private var routeTimer: java.util.Timer? = null
    private var isRouteMode: Boolean = false

    companion object {
        const val CHANNEL_ID = "mock_location_channel"
        const val NOTIFICATION_ID = 4242
        const val ACTION_STOP = "com.fakegps.app.STOP_MOCK"

        var instance: MockLocationService? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopMock()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopMock()
        instance = null
        super.onDestroy()
    }

    /**
     * Mulai mock location di koordinat statis (mode Teleport).
     */
    fun startMock(latitude: Double, longitude: Double): Boolean {
        if (!ensureMockProvider()) return false

        mockLatitude = latitude
        mockLongitude = longitude
        isRouteMode = false
        isRunning = true

        pushLocation(latitude, longitude)

        startForeground(NOTIFICATION_ID, buildNotification(latitude, longitude))
        return true
    }

    /**
     * Mulai simulasi rute (mode Perjalanan).
     */
    fun startRoute(points: List<Pair<Double, Double>>, speedKmh: Double): Boolean {
        if (points.size < 2) return false
        if (!ensureMockProvider()) return false

        routePoints = points
        currentRouteIndex = 0
        speedMetersPerSecond = speedKmh * 1000.0 / 3600.0
        isRouteMode = true
        isRunning = true

        val start = points.first()
        mockLatitude = start.first
        mockLongitude = start.second

        pushLocation(mockLatitude, mockLongitude)
        startForeground(NOTIFICATION_ID, buildNotification(mockLatitude, mockLongitude))

        // Mulai interpolasi rute
        startRouteInterpolation(speedKmh)

        return true
    }

    /**
     * Update koordinat secara langsung (untuk joystick / manual movement).
     */
    fun updateLocation(latitude: Double, longitude: Double) {
        mockLatitude = latitude
        mockLongitude = longitude
        if (isRunning) {
            pushLocation(latitude, longitude)
            updateNotification(latitude, longitude)
        }
    }

    /**
     * Stop mock location.
     */
    fun stopMock() {
        isRunning = false
        isRouteMode = false
        routeTimer?.cancel()
        routeTimer = null
        routePoints = emptyList()

        try {
            locationManager.clearTestProviderLocation(LocationManager.GPS_PROVIDER)
            locationManager.removeTestProvider(LocationManager.GPS_PROVIDER)
        } catch (_: Exception) {}

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /**
     * Cek apakah mock location provier sudah terdaftar; jika belum, daftarkan.
     */
    private fun ensureMockProvider(): Boolean {
        return try {
            val providers = locationManager.allProviders
            if (!providers.contains(LocationManager.GPS_PROVIDER)) {
                // Provider tidak ada — tidak mungkin terjadi di device normal
                return false
            }

            // Coba tambahkan test provider (mungkin sudah ada)
            try {
                locationManager.addTestProvider(
                    LocationManager.GPS_PROVIDER,
                    false,   // requiresNetwork
                    false,   // requiresSatellite
                    false,   // requiresCell
                    false,   // hasMonetaryCost
                    false,   // supportsAltitude
                    true,    // supportsSpeed
                    true,    // supportsBearing
                    android.location.Criteria.POWER_LOW,
                    android.location.Criteria.ACCURACY_FINE
                )
            } catch (_: Exception) {
                // Provider mungkin sudah terdaftar — tidak masalah
            }

            // Set enabled
            locationManager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, true)
            true
        } catch (e: SecurityException) {
            // Mock location app tidak dipilih di Developer Options
            false
        }
    }

    /**
     * Push koordinat ke Android mock location provider.
     */
    private fun pushLocation(latitude: Double, longitude: Double) {
        val location = Location(LocationManager.GPS_PROVIDER).apply {
            this.latitude = latitude
            this.longitude = longitude
            altitude = 100.0
            time = System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            }
            accuracy = 5.0f
            speed = 0f
            bearing = 0f
        }

        try {
            locationManager.setTestProviderLocation(
                LocationManager.GPS_PROVIDER,
                location
            )
        } catch (_: SecurityException) {
            stopMock()
        }
    }

    /**
     * Interpolasi rute: setiap ~1 detik update koordinat ke titik berikutnya.
     */
    private fun startRouteInterpolation(speedKmh: Double) {
        routeTimer?.cancel()
        routeTimer = java.util.Timer()

        var segmentIndex = 0
        var progressInSegment = 0.0 // 0.0 - 1.0

        routeTimer?.scheduleAtFixedRate(
            object : java.util.TimerTask() {
                override fun run() {
                    if (!isRunning || segmentIndex >= routePoints.size - 1) {
                        if (segmentIndex >= routePoints.size - 1) {
                            // Rute selesai
                            isRouteMode = false
                        }
                        cancel()
                        return
                    }

                    val start = routePoints[segmentIndex]
                    val end = routePoints[segmentIndex + 1]

                    // Hitung jarak antar dua titik (meter)
                    val segmentDistance = haversineDistance(start, end)
                    // Berapa lama untuk menyelesaikan segment ini (detik)
                    val segmentDuration = segmentDistance / speedMetersPerSecond
                    // Progress increment per tick (~1 detik)
                    val increment = 1.0 / max(segmentDuration, 0.5)

                    progressInSegment += increment

                    if (progressInSegment >= 1.0) {
                        // Pindah ke segment berikutnya
                        progressInSegment = 0.0
                        segmentIndex++
                        if (segmentIndex >= routePoints.size - 1) {
                            // Sampai di akhir rute
                            val finalPoint = routePoints.last()
                            mockLatitude = finalPoint.first
                            mockLongitude = finalPoint.second
                            pushLocation(mockLatitude, mockLongitude)
                            updateNotification(mockLatitude, mockLongitude)
                            isRouteMode = false
                            cancel()
                            return
                        }
                    }

                    // Interpolasi posisi
                    val lat = start.first + (end.first - start.first) * progressInSegment
                    val lng = start.second + (end.second - start.second) * progressInSegment

                    mockLatitude = lat
                    mockLongitude = lng
                    pushLocation(lat, lng)

                    // Update notification di UI thread
                    android.os.Handler(mainLooper).post {
                        updateNotification(lat, lng)
                    }
                }
            },
            0,
            1000L // Update setiap ~1 detik
        )
    }

    /**
     * Haversine formula untuk jarak antar dua koordinat (dalam meter).
     */
    private fun haversineDistance(
        p1: Pair<Double, Double>,
        p2: Pair<Double, Double>
    ): Double {
        val R = 6_371_000.0 // Earth radius in meters
        val dLat = Math.toRadians(p2.first - p1.first)
        val dLng = Math.toRadians(p2.second - p1.second)
        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(p1.first)) * cos(Math.toRadians(p2.first)) *
                sin(dLng / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // --- Notification helpers ---

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mock Location",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Menunjukkan bahwa mock location sedang aktif"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(lat: Double, lng: Double): Notification {
        val stopIntent = Intent(this, MockLocationService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent untuk buka aplikasi saat notif diklik
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = PendingIntent.getActivity(
            this, 1, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Fake GPS Aktif")
            .setContentText(
                String.format("%.6f, %.6f%s", lat, lng,
                    if (isRouteMode) " (perjalanan)" else "")
            )
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .build()
    }

    private fun updateNotification(lat: Double, lng: Double) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(lat, lng))
    }
}
