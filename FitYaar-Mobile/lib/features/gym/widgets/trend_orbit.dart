import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../gym_models.dart';

/// Today's busy-by-hour trend as a 24-hour radial dial (not a bar chart): each
/// hour is a glowing radial spoke whose length/intensity is its typical
/// busyness, with a "now" needle and a peak-hours callout.
class TrendOrbit extends StatefulWidget {
  final List<HourlyBucket> buckets; // ideally length 24
  const TrendOrbit({super.key, required this.buckets});

  @override
  State<TrendOrbit> createState() => _TrendOrbitState();
}

class _TrendOrbitState extends State<TrendOrbit> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _fmtHour(int h) {
    if (h == 0) return '12 AM';
    if (h == 12) return '12 PM';
    return h < 12 ? '$h AM' : '${h - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final counts = List<int>.filled(24, 0);
    for (final b in widget.buckets) {
      if (b.hour >= 0 && b.hour < 24) counts[b.hour] = b.count;
    }
    final maxC = counts.fold<int>(0, math.max);
    final nowHour = TimeOfDay.now().hour;

    int peak = 0;
    for (var h = 1; h < 24; h++) {
      if (counts[h] > counts[peak]) peak = h;
    }
    final caption = maxC == 0
        ? 'Not enough history yet — check in to build the trend.'
        : 'Usually busiest around ${_fmtHour(peak)}';

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _TrendPainter(
                  counts: counts,
                  maxC: maxC,
                  nowHour: nowHour,
                  pulse: _c.value,
                  accent: primary),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmtHour(nowHour),
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: primary)),
                  const Text('now', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 2),
        Text('Longer rays = busier hours (30-day average) · ☀ day · 🌙 night',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<int> counts; // 24
  final int maxC;
  final int nowHour;
  final double pulse; // 0..1
  final Color accent;
  _TrendPainter(
      {required this.counts,
      required this.maxC,
      required this.nowHour,
      required this.pulse,
      required this.accent});

  double _angle(double hour) => (hour / 24) * 2 * math.pi - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2 - 14;
    final inner = outer * 0.42;
    final discRect = Rect.fromCircle(center: center, radius: outer);

    // Day/night backdrop so AM/PM read at a glance: day 6am–6pm (warm), the
    // rest night (cool). Day spans _angle(6)→_angle(18) = the bottom half.
    canvas.drawArc(discRect, _angle(6), math.pi, true,
        Paint()..color = const Color(0xFFF5A623).withValues(alpha: 0.05));
    canvas.drawArc(discRect, _angle(18), math.pi, true,
        Paint()..color = const Color(0xFF4DA3FF).withValues(alpha: 0.06));

    // Guide rings.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, outer, guide);
    canvas.drawCircle(center, inner, guide);

    // Radial spoke per hour.
    for (var h = 0; h < 24; h++) {
      final a = _angle(h.toDouble());
      final frac = maxC == 0 ? 0.0 : counts[h] / maxC;
      final len = inner + (outer - inner) * frac;
      final p1 = center + Offset(math.cos(a) * inner, math.sin(a) * inner);
      final p2 = center + Offset(math.cos(a) * len, math.sin(a) * len);
      final baseAlpha = 0.15 + 0.75 * frac;
      // Glow.
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: baseAlpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Solid.
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: baseAlpha));
    }

    // Cardinal hour labels with day/night cues: 🌙 midnight (top), 6a (right),
    // ☀ noon (bottom), 6p (left).
    const labels = {0: '🌙 12a', 6: '6a', 12: '☀ 12p', 18: '6p'};
    labels.forEach((h, text) {
      final a = _angle(h.toDouble());
      final pos = center + Offset(math.cos(a) * (outer + 8), math.sin(a) * (outer + 8));
      final tp = TextPainter(
        text: TextSpan(
            text: text, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });

    // "Now" needle with a pulsing dot.
    final na = _angle(nowHour.toDouble());
    final tip = center + Offset(math.cos(na) * (outer - 2), math.sin(na) * (outer - 2));
    canvas.drawLine(
        center + Offset(math.cos(na) * (inner - 4), math.sin(na) * (inner - 4)),
        tip,
        Paint()
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.85));
    final r = 4.0 + 3.0 * pulse;
    canvas.drawCircle(
        tip,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(tip, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.pulse != pulse || old.counts != counts || old.nowHour != nowHour;
}
