import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Widget peta Google Maps yang dipakai bersama oleh mode Teleport & Perjalanan.
class MapWidget extends StatelessWidget {
  final GoogleMapController? Function(GoogleMapController)? onMapCreated;
  final LatLng? initialPosition;
  final LatLng? centerCrosshair;       // Posisi crosshair (mode teleport)
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final CameraTargetBounds? cameraBounds;
  final void Function(LatLng)? onCenterChanged;  // Dipanggil saat map digeser

  const MapWidget({
    super.key,
    this.onMapCreated,
    this.initialPosition,
    this.centerCrosshair,
    this.markers = const {},
    this.polylines = const {},
    this.cameraBounds,
    this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition ?? const LatLng(-6.2088, 106.8456),
            zoom: 17,
          ),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: onMapCreated,
          onCameraIdle: () {
            if (onCenterChanged != null && centerCrosshair != null) {
              onCenterChanged!(centerCrosshair!);
            }
          },
        ),

        // Crosshair di tengah peta (mode teleport)
        if (centerCrosshair != null)
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
