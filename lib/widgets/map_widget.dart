import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Widget peta Google Maps yang dipakai bersama oleh mode Teleport & Perjalanan.
class MapWidget extends StatefulWidget {
  final void Function(GoogleMapController)? onMapCreated;
  final LatLng? initialPosition;
  final bool showCrosshair;          // Tampilkan crosshair (mode teleport)
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(LatLng)? onCenterChanged;  // Dipanggil saat map digeser
  final void Function(LatLng)? onMapTap;          // Dipanggil saat map di-tap

  const MapWidget({
    super.key,
    this.onMapCreated,
    this.initialPosition,
    this.showCrosshair = true,
    this.markers = const {},
    this.polylines = const {},
    this.onCenterChanged,
    this.onMapTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  void _onCameraMove(CameraPosition position) {
    // Update koordinat real-time saat map digeser
    widget.onCenterChanged?.call(position.target);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition ?? const LatLng(-6.2088, 106.8456),
            zoom: 17,
          ),
          markers: widget.markers,
          polylines: widget.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: _onMapCreated,
          onCameraMove: _onCameraMove,
          onTap: widget.onMapTap,
        ),

        // Crosshair di tengah peta (mode teleport)
        if (widget.showCrosshair)
          const IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_drop_down, color: Colors.green, size: 36),
                  Icon(Icons.location_on, color: Colors.green, size: 32),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
