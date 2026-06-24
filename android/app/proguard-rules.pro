# ProGuard / R8 rules for Fake GPS

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class com.fakegps.app.** { *; }

# Keep Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Keep Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
