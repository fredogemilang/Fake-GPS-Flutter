import 'package:flutter/material.dart';

/// Menampilkan koordinat latitude/longitude dan alamat.
class CoordinateDisplay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const CoordinateDisplay({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.pin_drop, size: 18, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              'Lat: ${latitude.toStringAsFixed(6)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Lng: ${longitude.toStringAsFixed(6)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (address != null) ...[
          const SizedBox(height: 4),
          Text(
            address!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
