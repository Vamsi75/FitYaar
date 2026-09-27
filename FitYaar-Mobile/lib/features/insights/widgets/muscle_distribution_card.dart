import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../analytics.dart';

/// Muscle split as a spider/radar chart: working sets per region, last 30 days
/// (orange) vs last 3 months (grey).
class MuscleDistributionCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  const MuscleDistributionCard(
      {super.key, required this.sessions, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final s30 = regionSetsSince(sessions, catalog, now.subtract(const Duration(days: 30)));
    final s90 = regionSetsSince(sessions, catalog, now.subtract(const Duration(days: 90)));
    final t90 = s90.values.fold<int>(0, (a, b) => a + b);

    const regions = MuscleRegion.values;
    final v30 = [for (final r in regions) s30[r]!.toDouble()];
    final v90 = [for (final r in regions) s90[r]!.toDouble()];
    final maxV = [
      ...v30,
      ...v90,
      1.0
    ].reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.radar, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Muscle split', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _legendDot(theme.colorScheme.primary, 'Last 30 days'),
            const SizedBox(width: 16),
            _legendDot(Colors.white54, 'Last 3 months'),
          ]),
          const SizedBox(height: 8),
          if (t90 == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text('No sets in the last 3 months',
                      style: TextStyle(color: Colors.white54))),
            )
          else
            SizedBox(
              height: 260,
              child: CustomPaint(
                size: Size.infinite,
                painter: _RadarPainter(
                  labels: [for (final r in regions) regionLabel(r)],
                  primary: v30,
                  secondary: v90,
                  maxValue: maxV,
                  primaryColor: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]);
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> primary; // 30d
  final List<double> secondary; // 90d
  final double maxValue;
  final Color primaryColor;

  _RadarPainter({
    required this.labels,
    required this.primary,
    required this.secondary,
    required this.maxValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) / 2 - 34;

    Offset pointAt(double frac, int i) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      return Offset(
        center.dx + radius * frac * math.cos(angle),
        center.dy + radius * frac * math.sin(angle),
      );
    }

    // Grid rings.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);
    for (final ring in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final p = pointAt(ring, i % n);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, grid);
    }
    // Spokes + labels.
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, pointAt(1.0, i), grid);
      final lp = pointAt(1.18, i);
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }

    void drawSeries(List<double> vals, Color color, double fillA) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final frac = (vals[i] / maxValue).clamp(0.0, 1.0);
        final p = pointAt(frac, i);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: fillA));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color);
      for (var i = 0; i < n; i++) {
        final frac = (vals[i] / maxValue).clamp(0.0, 1.0);
        canvas.drawCircle(pointAt(frac, i), 2.5, Paint()..color = color);
      }
    }

    // 3-month first (behind), then 30-day on top.
    drawSeries(secondary, Colors.white54, 0.10);
    drawSeries(primary, primaryColor, 0.22);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.primary != primary || old.secondary != secondary || old.maxValue != maxValue;
}
