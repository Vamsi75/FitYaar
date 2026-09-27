import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass surface used across the app. Sits on the app's dark gradient
/// background (see main.dart) so the blur/translucency reads as "glass".
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? tint;

  /// Optional coloured outer glow — used to elevate a card as a highlight.
  final Color? glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
    this.tint,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final base = tint ?? Colors.white;
    final borderColor = glow != null
        ? glow!.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.08);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            // Subtle top→bottom sheen baked into the fill (an iOS "light
            // refraction" hint without a second layer/backdrop pass).
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: tint != null ? 0.20 : 0.10),
                base.withValues(alpha: tint != null ? 0.14 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (glow != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: glow!.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: -6),
          ],
        ),
        child: card,
      );
    }
    return card;
  }
}
