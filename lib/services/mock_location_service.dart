import 'package:flutter/services.dart';

/// Wrapper untuk Method Channel ke native Android mock location.
class MockLocationService {
  static const _channel = MethodChannel('com.fakegps.app/mock_location');

  /// Cek apakah mock location sedang berjalan.
  static Future<bool> get isRunning async {
    final result = await _channel.invokeMethod<bool>('isRunning');
    return result ?? false;
  }

  /// Mulai mock location di koordinat [latitude], [longitude].
  /// Mengembalikan true jika berhasil.
  static Future<bool> startMock(double latitude, double longitude) async {
    final result = await _channel.invokeMethod<bool>('startMock', {
      'latitude': latitude,
      'longitude': longitude,
    });
    return result ?? false;
  }

  /// Update koordinat mock location (untuk mode perjalanan).
  static Future<void> updateLocation(double latitude, double longitude) async {
    await _channel.invokeMethod('updateLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Mulai simulasi rute dengan [points] dan [speedKmh] (km/jam).
  static Future<bool> startRoute({
    required List<Map<String, double>> points,
    required double speedKmh,
  }) async {
    final result = await _channel.invokeMethod<bool>('startRoute', {
      'points': points,
      'speedKmh': speedKmh,
    });
    return result ?? false;
  }

  /// Stop mock location (baik teleport maupun perjalanan).
  static Future<void> stopMock() async {
    await _channel.invokeMethod('stopMock');
  }

  /// Cek apakah user sudah mengaktifkan mock location app di Developer Options.
  static Future<bool> get isMockLocationEnabled async {
    final result = await _channel.invokeMethod<bool>('isMockLocationEnabled');
    return result ?? false;
  }
}
