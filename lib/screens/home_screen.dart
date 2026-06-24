import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/mock_location_service.dart';
import '../widgets/map_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/teleport_panel.dart';
import '../widgets/route_panel.dart';
import '../widgets/joystick_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // --- Map state ---
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(-6.2088, 106.8456); // Jakarta default
  String? _currentAddress;
  bool _isMockRunning = false;
  bool _locationLoaded = false;

  // --- Tab state ---
  late TabController _tabController;
  int _activeTab = 0;

  // --- Route state ---
  final List<LatLng> _waypoints = [];
  double _speedKmh = 15;

  // --- Joystick state ---
  bool _showJoystick = false;

  // --- API Key ---
  static const String _mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _activeTab = _tabController.index));
    _initLocation();
    _checkMockStatus();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Dapatkan posisi GPS asli user saat pertama buka.
  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        final userPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentCenter = userPos;
          _locationLoaded = true;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 17));
      }
    } catch (_) {
      // GPS tidak tersedia — tetap pakai default
    }
  }

  Future<void> _checkMockStatus() async {
    final running = await MockLocationService.isRunning;
    if (mounted) setState(() => _isMockRunning = running);
  }

  /// Pindah lokasi instan (Teleport).
  Future<void> _onTeleportStart() async {
    // Cek dulu apakah mock location app sudah dipilih
    final enabled = await MockLocationService.isMockLocationEnabled;
    if (!enabled && mounted) {
      _showMockNotEnabledDialog();
      return;
    }

    final success = await MockLocationService.startMock(
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    if (mounted) {
      setState(() => _isMockRunning = success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '📍 Lokasi dipindahkan ke ${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}'
              : '❌ Gagal! Cek Developer Options > Mock Location App'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Mulai simulasi perjalanan.
  Future<void> _onRouteStart() async {
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 2 titik untuk rute'), backgroundColor: Colors.orange),
      );
      return;
    }

    final enabled = await MockLocationService.isMockLocationEnabled;
    if (!enabled && mounted) {
      _showMockNotEnabledDialog();
      return;
    }

    final points = _waypoints
        .map((w) => {'latitude': w.latitude, 'longitude': w.longitude})
        .toList();

    final success = await MockLocationService.startRoute(points: points, speedKmh: _speedKmh);

    if (mounted) {
      setState(() {
        _isMockRunning = success;
        _showJoystick = success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '🚗 Perjalanan — ${_waypoints.length} titik, ${_speedKmh.toInt()} km/j'
              : '❌ Gagal memulai perjalanan'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Stop mock.
  Future<void> _onStop() async {
    await MockLocationService.stopMock();
    if (mounted) {
      setState(() {
        _isMockRunning = false;
        _showJoystick = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock location dihentikan'), backgroundColor: Colors.blueGrey),
      );
    }
  }

  /// Map center berubah (dipanggil real-time dari onCameraMove).
  void _onMapCenterChanged(LatLng newCenter) {
    if (_activeTab == 0) {
      setState(() => _currentCenter = newCenter);
    }
  }

  /// Search place → animate ke lokasi.
  void _onPlaceSelected(String name, LatLng position) {
    setState(() {
      _currentCenter = position;
      _currentAddress = name;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 18));
  }

  /// Tap di map → tambah waypoint (mode perjalanan).
  void _onMapTap(LatLng position) {
    if (_activeTab == 1 && !_isMockRunning) {
      setState(() => _waypoints.add(position));
    }
  }

  void _clearWaypoints() => setState(() => _waypoints.clear());

  /// Dialog panduan jika mock location belum diaktifkan.
  void _showMockNotEnabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚙️ Mock Location belum aktif'),
        content: const Text(
          'Buka Settings → Developer Options → '
          '"Select mock location app" → pilih "Fake GPS".\n\n'
          'Kalau Developer Options belum muncul, tap "Build Number" 7× di About Phone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- PETA ---
          MapWidget(
            initialPosition: _currentCenter,
            showCrosshair: _activeTab == 0,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            onMapCreated: (c) => _mapController = c,
            onCenterChanged: _onMapCenterChanged,
            onMapTap: _onMapTap,
          ),

          // --- Top: Tab + Search ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.pin_drop, size: 20), text: 'Teleport'),
                      Tab(icon: Icon(Icons.route, size: 20), text: 'Perjalanan'),
                    ],
                    labelStyle: const TextStyle(fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    dividerColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 8),
                LocationSearchBar(apiKey: _mapsApiKey, onPlaceSelected: _onPlaceSelected),
              ],
            ),
          ),

          // --- Joystick ---
          if (_showJoystick && _activeTab == 1)
            Positioned(
              right: 16,
              bottom: 280,
              child: JoystickOverlay(onDirectionChanged: (dx, dy) {}),
            ),

          // --- Bottom Panel ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _activeTab == 0
                ? TeleportPanel(
                    latitude: _currentCenter.latitude,
                    longitude: _currentCenter.longitude,
                    address: _currentAddress,
                    isMockRunning: _isMockRunning,
                    onStart: _onTeleportStart,
                    onStop: _onStop,
                  )
                : RoutePanel(
                    waypointCount: _waypoints.length,
                    speedKmh: _speedKmh,
                    isMockRunning: _isMockRunning,
                    onStartRoute: _onRouteStart,
                    onStop: _onStop,
                    onClearWaypoints: _clearWaypoints,
                    onSpeedChanged: (s) => setState(() => _speedKmh = s),
                  ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('target'),
        position: _currentCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isMockRunning ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: 'Target'),
      ),
    };

    for (int i = 0; i < _waypoints.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('wp_$i'),
        position: _waypoints[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Titik ${i + 1}'),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_waypoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _waypoints,
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(10), PatternItem.gap(6)],
      ),
    };
  }
}
