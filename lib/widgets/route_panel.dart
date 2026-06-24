import 'package:flutter/material.dart';

/// Bottom panel untuk mode PERJALANAN (secondary).
/// Menampilkan speed selector + tombol "Mulai Perjalanan" / "Stop".
class RoutePanel extends StatelessWidget {
  final int waypointCount;
  final double speedKmh;
  final bool isMockRunning;
  final VoidCallback onStartRoute;
  final VoidCallback onStop;
  final VoidCallback onClearWaypoints;
  final void Function(double speed) onSpeedChanged;

  const RoutePanel({
    super.key,
    required this.waypointCount,
    required this.speedKmh,
    required this.isMockRunning,
    required this.onStartRoute,
    required this.onStop,
    required this.onClearWaypoints,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Status + waypoint count
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMockRunning ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isMockRunning ? 'Perjalanan Aktif' : 'Perjalanan Mode',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (waypointCount > 0)
                Text(
                  '$waypointCount titik',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Speed selector chips
          Text('Kecepatan:', style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpeedChip(
                label: 'Jalan',
                speed: 5,
                selected: speedKmh == 5,
                onTap: () => onSpeedChanged(5),
              ),
              _SpeedChip(
                label: 'Sepeda',
                speed: 15,
                selected: speedKmh == 15,
                onTap: () => onSpeedChanged(15),
              ),
              _SpeedChip(
                label: 'Mobil',
                speed: 40,
                selected: speedKmh == 40,
                onTap: () => onSpeedChanged(40),
              ),
              _SpeedChip(
                label: 'Custom',
                speed: speedKmh,
                selected:
                    speedKmh != 5 && speedKmh != 15 && speedKmh != 40,
                onTap: () => _showCustomSpeedDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tombol aksi
          Row(
            children: [
              if (!isMockRunning && waypointCount > 0)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStartRoute,
                    icon: const Icon(Icons.route),
                    label: const Text('Mulai Perjalanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!isMockRunning && waypointCount == 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.touch_app),
                    label: const Text('Tap di peta untuk tambah titik'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (isMockRunning) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (waypointCount > 0 && !isMockRunning) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClearWaypoints,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus semua titik',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomSpeedDialog(BuildContext context) {
    final controller = TextEditingController(text: speedKmh.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kecepatan Custom'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kecepatan (km/jam)',
            suffixText: 'km/j',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final speed = double.tryParse(controller.text);
              if (speed != null && speed > 0 && speed <= 200) {
                onSpeedChanged(speed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final double speed;
  final bool selected;
  final VoidCallback onTap;

  const _SpeedChip({
    required this.label,
    required this.speed,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${speed.toInt()} km/j',
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? theme.colorScheme.onPrimary.withOpacity(0.8)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
