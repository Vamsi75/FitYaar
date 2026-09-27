import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../gym_focus.dart';
import '../gym_models.dart';

/// Zone-occupancy hologram: one glowing concentric ring per gym zone (Free
/// weights / Racks / Cardio / Machines / Functional), arc length scaled to how
/// many members are in it, with a legend of counts.
class ZoneRings extends StatefulWidget {
  final List<GymActivityItem> zones;
  const ZoneRings({super.key, required this.zones});

  @override
  State<ZoneRings> createState() => _ZoneRingsState();
}

class _ZoneRingsState extends State<ZoneRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  static const _palette = [
    Color(0xFFFF7A3D), // orange
    Color(0xFF4DA3FF), // blue
    Color(0xFF35E0C8), // cyan
    Color(0xFFB388FF), // purple
    Color(0xFF7ED957), // green
    Color(0xFFFFC24D), // amber
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = [...widget.zones]..sort((a, b) => b.count.compareTo(a.count));
    final total = zones.fold<int>(0, (s, z) => s + z.count);
    if (total == 0) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: Text('No one training yet.', style: TextStyle(color: Colors.white54))),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _ZonePainter(
                  zones: zones, total: total, palette: _palette, t: _c.value),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  const Text('in the gym',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < zones.length; i++)
            _legend(_palette[i % _palette.length], zones[i], total),
        ]),
      ],
    );
  }

  // Ring fill = share of the current crowd, so the legend reads "count (share%)"
  // and a full ring means everyone is in that zone — not "packed vs capacity".
  Widget _legend(Color c, GymActivityItem z, int total) {
    final pct = total == 0 ? 0 : (z.count / total * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.5))),
      child: Text('${gymZoneEmoji(z.label)} ${z.label} · ${z.count} ($pct%)',
          style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ZonePainter extends CustomPainter {
  final List<GymActivityItem> zones;
  final int total;
  final List<Color> palette;
  final double t;
  _ZonePainter(
      {required this.zones, required this.total, required this.palette, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 6;
    const gap = 15.0;
    for (var i = 0; i < zones.length; i++) {
      final rr = maxR - i * gap;
      if (rr < 14) break;
      final z = zones[i];
      final color = palette[i % palette.length];
      // Fill = this zone's share of everyone currently in the gym (min 6% so a
      // lone member is still visible). A full ring = 100% of the crowd here.
      final frac = total == 0 ? 0.0 : (z.count / total).clamp(0.06, 1.0);
      final start = -math.pi / 2 + (t * 2 * math.pi) * (i.isEven ? 0.15 : -0.15);
      final sweep = 2 * math.pi * frac;
      final rect = Rect.fromCircle(center: center, radius: rr);
      // Track.
      canvas.drawArc(
          rect,
          0,
          2 * math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = Colors.white.withValues(alpha: 0.05));
      // Glow.
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Solid.
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ZonePainter old) =>
      old.t != t || old.zones != zones || old.total != total;
}
