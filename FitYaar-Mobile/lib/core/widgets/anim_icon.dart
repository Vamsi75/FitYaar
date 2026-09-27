import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// An animated icon that gracefully falls back to a static [Icon] when the
/// asset hasn't been added yet (see assets/anim/README.md). Supports both
/// Lottie JSON (`.json`, vector, tintable — lightest) and raster assets
/// (`.webp` / `.gif` animate natively, `.png` is a still frame). Lets us ship
/// the integration before the icon files exist and keeps partial sets working.
class AnimIcon extends StatelessWidget {
  /// Asset path, e.g. 'assets/anim/dumbbell.json' or 'assets/anim/calendar.png'.
  final String asset;
  final IconData fallback;
  final double size;
  final Color? color;

  const AnimIcon({
    super.key,
    required this.asset,
    required this.fallback,
    required this.size,
    this.color,
  });

  bool get _isLottie => asset.toLowerCase().endsWith('.json');

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    Widget fallbackIcon(_, __, ___) => Icon(fallback, size: size * 0.82, color: c);
    return SizedBox(
      width: size,
      height: size,
      child: _isLottie
          ? Lottie.asset(asset,
              fit: BoxFit.contain, repeat: true, errorBuilder: fallbackIcon)
          // WebP/GIF animate automatically; PNG renders as a still.
          : Image.asset(asset, fit: BoxFit.contain, errorBuilder: fallbackIcon),
    );
  }
}
