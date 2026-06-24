# Fake GPS - Aplikasi Mock Location Android

Aplikasi Android untuk **mock location / fake GPS** menggunakan Google Maps API.
Dibangun dengan Flutter + native Android Kotlin.
**Cloud build** via Codemagic / GitHub Actions — tidak perlu install Android SDK lokal.

## Fitur

### Mode 1: Teleport (Default)
- Pilih lokasi di Google Maps → geser map atau search
- Tekan "Pindah ke Sini" → lokasi langsung berubah instan
- Cocok untuk pindah lokasi cepat

### Mode 2: Perjalanan (Secondary)
- Tap beberapa titik di peta untuk membuat rute
- Atur kecepatan: Jalan (5 km/j), Sepeda (15 km/j), Mobil (40 km/j), atau Custom
- Tekan "Mulai Perjalanan" → koordinat bergerak otomatis mengikuti rute
- Joystick D-Pad opsional untuk kontrol arah manual

## Persyaratan

- **Device Android fisik** (emulator tidak support mock location)
- **Developer Options** diaktifkan
- **Aplikasi dipilih sebagai Mock Location App** di Developer Options
- Google Maps API Key dari [Google Cloud Console](https://console.cloud.google.com/)

## Cara Setup di Device

1. **Enable Developer Options:**
   `Settings → About Phone → Tap "Build Number" 7×`

2. **Pilih Mock Location App:**
   `Settings → Developer Options → Select Mock Location App → Fake GPS`

3. **Matikan Google Location Accuracy** (opsional, supaya GPS asli tidak konflik):
   `Settings → Location → Google Location Accuracy → Off`

## Cloud Build (CI/CD)

### Codemagic (Recommended)
1. Hubungkan repo GitHub ke [Codemagic](https://codemagic.io/)
2. Tambahkan environment variable `MAPS_API_KEY` di Codemagic UI
3. Push ke branch `main` → auto-build APK

### GitHub Actions
1. Tambahkan secret `MAPS_API_KEY` di Settings → Secrets → Actions
2. Push ke `main` atau trigger manual dari Actions tab
3. Download APK dari artifacts

### Build Manual (opsional, jika ada Flutter SDK lokal)
```bash
flutter pub get
flutter build apk --debug --dart-define=MAPS_API_KEY=YOUR_KEY
```

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp config
├── screens/
│   └── home_screen.dart         # Tab layout (Teleport | Perjalanan)
├── services/
│   ├── mock_location_service.dart  # Method Channel wrapper
│   └── location_search_service.dart # Places autocomplete
├── widgets/
│   ├── map_widget.dart            # Google Maps widget
│   ├── search_bar.dart            # Places search bar
│   ├── coordinate_display.dart   # Lat/Lng display
│   ├── teleport_panel.dart        # Teleport mode controls
│   ├── route_panel.dart          # Route mode controls
│   └── joystick_overlay.dart     # D-Pad joystick
└── models/
    └── route_point.dart          # Route waypoint model

android/app/src/main/kotlin/com/fakegps/app/
├── MainActivity.kt               # Flutter activity
├── MockLocationPlugin.kt         # Method Channel handler
└── MockLocationService.kt        # Foreground service (mock GPS injector)
```

## Teknologi

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter (Dart) |
| Peta | Google Maps Flutter |
| Native | Kotlin + Android LocationManager API |
| CI/CD | Codemagic / GitHub Actions |

## Batasan

- ❌ Aplikasi lain bisa mendeteksi lokasi ini sebagai mock (`isFromMockProvider()`)
- ❌ Tidak support iOS
- ❌ Harus menggunakan Developer Options (tidak bisa tanpa root)
