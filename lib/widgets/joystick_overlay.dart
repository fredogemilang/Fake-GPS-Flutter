import 'package:flutter/material.dart';

/// D-Pad joystick overlay untuk kontrol arah manual.
/// Hanya tampil saat mode perjalanan aktif.
class JoystickOverlay extends StatelessWidget {
  final void Function(double dx, double dy)? onDirectionChanged;

  const JoystickOverlay({super.key, this.onDirectionChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Up
          _JoystickButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: () => onDirectionChanged?.call(0, 1),
            onReleased: () => onDirectionChanged?.call(0, 0),
          ),
          const SizedBox(height: 4),
          // Left + Right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _JoystickButton(
                icon: Icons.keyboard_arrow_left,
                onPressed: () => onDirectionChanged?.call(-1, 0),
                onReleased: () => onDirectionChanged?.call(0, 0),
              ),
              const SizedBox(width: 24),
              _JoystickButton(
                icon: Icons.keyboard_arrow_right,
                onPressed: () => onDirectionChanged?.call(1, 0),
                onReleased: () => onDirectionChanged?.call(0, 0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Down
          _JoystickButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: () => onDirectionChanged?.call(0, -1),
            onReleased: () => onDirectionChanged?.call(0, 0),
          ),
        ],
      ),
    );
  }
}

class _JoystickButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const _JoystickButton({
    required this.icon,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  State<_JoystickButton> createState() => _JoystickButtonState();
}

class _JoystickButtonState extends State<_JoystickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onReleased();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onReleased();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _pressed ? Colors.white30 : Colors.white12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 28),
      ),
    );
  }
}
