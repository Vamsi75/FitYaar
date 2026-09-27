import 'package:flutter/material.dart';

/// A high-contrast initials avatar for the dark HUD: translucent fill, a bright
/// neon primary ring, and a soft glow — legible on the dark gradient where a
/// low-alpha filled circle reads as muddy.
class GlowAvatar extends StatelessWidget {
  final String name;
  final double size;
  const GlowAvatar({super.key, required this.name, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: c.withValues(alpha: 0.75), width: 1.4),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 9, spreadRadius: 0.5),
        ],
      ),
      child: Text(_initials(name),
          style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade100)),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }
}
