import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Multi-layer concentric "orbit dial" occupancy gauge (cyberpunk-style): a
/// glowing arc fills to the live occupancy, ringed by tick marks and orbiting
/// particles with a soft pulse. Replaces the plain crowd number.
class OrbitDial extends StatefulWidget {
  final int liveCount;
  final int? capacity;
  final double size;
  const OrbitDial({super.key, required this.liveCount, this.capacity, this.size = 220});

  @override
  State<OrbitDial> createState() => _OrbitDialState();
}

class _OrbitDialState extends State<OrbitDial> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cap = widget.capacity ?? 0;
    final hasCap = cap > 0;
    final ratio = hasCap ? (widget.liveCount / cap).clamp(0.0, 1.0) : 0.0;
    final (label, busyColor) = ratio < 0.3
        ? ('Not busy', AppColors.live)
        : ratio < 0.7
            ? ('Getting busy', AppColors.busyMid)
            : ('Packed', AppColors.busyHigh);
    final accent = hasCap ? busyColor : const Color(0xFF4DA3FF);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _OrbitPainter(
              t: _c.value, ratio: ratio, accent: accent, showArc: hasCap),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.liveCount}',
                    style: TextStyle(
                        fontSize: 46, fontWeight: FontWeight.w800, color: accent, height: 1)),
                const SizedBox(height: 2),
                Text(hasCap ? 'of $cap here now' : 'here now',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.5))),
                  child: Text(hasCap ? label : 'Live',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double t; // 0..1 animation phase
  final double ratio;
  final Color accent;
  final bool showArc;
  _OrbitPainter(
      {required this.t, required this.ratio, required this.accent, required this.showArc});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2 - 6;
    const start = -math.pi / 2;
    final ringR = outer * 0.86;
    final ringRect = Rect.fromCircle(center: center, radius: ringR);

    // Dim concentric guide rings.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (final f in [0.6, 0.75, 0.92]) {
      canvas.drawCircle(center, outer * f, guide);
    }

    // Rim tick marks.
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (int i = 0; i < 60; i++) {
      final a = (i / 60) * 2 * math.pi;
      final r2 = outer - (i % 5 == 0 ? 10 : 5);
      canvas.drawLine(
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        tick,
      );
    }

    // Track ring.
    canvas.drawArc(
        ringRect,
        start,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Colors.white.withValues(alpha: 0.08));

    if (showArc) {
      final sweep = 2 * math.pi * ratio;
      // Glow underlay.
      canvas.drawArc(
          ringRect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // Solid gradient progress arc.
      canvas.drawArc(
          ringRect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              startAngle: start,
              endAngle: start + 2 * math.pi,
              colors: [accent.withValues(alpha: 0.55), accent],
            ).createShader(ringRect));
    }

    // Orbiting particles on two counter-rotating rings.
    void orbit(double radiusFrac, double dir, double phase, int count, double dotR, double alpha) {
      final rr = outer * radiusFrac;
      for (int i = 0; i < count; i++) {
        final a = dir * (t * 2 * math.pi) + phase + (i / count) * 2 * math.pi;
        final p = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        canvas.drawCircle(
            p,
            dotR,
            Paint()
              ..color = accent.withValues(alpha: alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(p, dotR * 0.5, Paint()..color = Colors.white.withValues(alpha: alpha));
      }
    }

    orbit(0.72, 1, 0, 3, 3.5, 0.9);
    orbit(0.5, -1, 1, 2, 2.5, 0.6);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.t != t || old.ratio != ratio || old.accent != accent || old.showArc != showArc;
}
