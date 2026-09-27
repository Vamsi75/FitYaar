import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Branded splash: the primary logo (icon + wordmark + tagline) fills the screen
/// immediately, with the orbit loader animating beneath it.
class BrandLoading extends StatefulWidget {
  const BrandLoading({super.key});

  @override
  State<BrandLoading> createState() => _BrandLoadingState();
}

class _BrandLoadingState extends State<BrandLoading> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

  @override
  void dispose() {
    _spin.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Image.asset(
                    'assets/brand/primary_logo.png',
                    width: 280,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: 52,
                height: 52,
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (_, __) => CustomPaint(painter: _OrbitPainter(_spin.value)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three trailing "comet" dots orbiting a center — brand orange fading to peach.
class _OrbitPainter extends CustomPainter {
  final double t; // 0..1
  _OrbitPainter(this.t);

  static const _orange = Color(0xFFFF7043);
  static const _peach = Color(0xFFFFB59D);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final base = t * 2 * math.pi;

    final specs = <(double, double, double, Color)>[
      (0.0, 5.5, 1.0, _orange),
      (-0.6, 4.5, 0.55, _orange),
      (-1.2, 3.5, 0.3, _peach),
    ];
    for (final (off, dotR, op, col) in specs) {
      final ang = base + off;
      final p = Offset(center.dx + radius * math.cos(ang), center.dy + radius * math.sin(ang));
      canvas.drawCircle(p, dotR, Paint()..color = col.withValues(alpha: op));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}
