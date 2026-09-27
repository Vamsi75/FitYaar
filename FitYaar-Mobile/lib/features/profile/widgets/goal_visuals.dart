import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../insights/analytics.dart' show DayVolume;

// Colours are driven by the app theme (deep-orange glass), lightened for accents —
// no hard-coded neon. `base` = colorScheme.primary, `light` = base blended to white.
Color _lighten(Color c, [double t = 0.35]) => Color.lerp(c, Colors.white, t)!;

// ─────────────────────────────────────────────────────────────────────────────
// 1) Area chart — smooth spline, soft orange gradient fill, gentle glow, tappable
//    data nodes (the latest node quietly pulses). Muted glass, not neon.
// ─────────────────────────────────────────────────────────────────────────────
class MoltenAreaChart extends StatefulWidget {
  final List<double> values;
  final double height;
  final String Function(double)? formatValue;
  final Color? color;
  const MoltenAreaChart({
    super.key,
    required this.values,
    this.height = 170,
    this.formatValue,
    this.color,
  });

  @override
  State<MoltenAreaChart> createState() => _MoltenAreaChartState();
}

class _MoltenAreaChartState extends State<MoltenAreaChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vals = widget.values;
    if (vals.length < 2) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('Not enough data yet',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }
    final base = widget.color ?? Theme.of(context).colorScheme.primary;
    final light = _lighten(base);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return GestureDetector(
        onTapDown: (d) {
          final n = vals.length;
          final dx = w / (n - 1);
          final i = (d.localPosition.dx / dx).round().clamp(0, n - 1);
          setState(() => _selected = _selected == i ? null : i);
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            size: Size(w, widget.height),
            painter: _AreaPainter(
                vals, _selected, _pulse.value, widget.formatValue, base, light),
          ),
        ),
      );
    });
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> v;
  final int? selected;
  final double pulse;
  final String Function(double)? fmt;
  final Color base, light;
  _AreaPainter(this.v, this.selected, this.pulse, this.fmt, this.base, this.light);

  @override
  void paint(Canvas canvas, Size size) {
    final n = v.length;
    final maxV = v.reduce(max), minV = v.reduce(min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    const padTop = 16.0, padBottom = 8.0;
    final chartH = size.height - padTop - padBottom;
    final dx = size.width / (n - 1);
    final baseline = padTop + chartH;

    Offset pt(int i) =>
        Offset(i * dx, padTop + chartH * (1 - (v[i] - minV) / range));
    final pts = [for (var i = 0; i < n; i++) pt(i)];

    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = pts[i > 0 ? i - 1 : i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < n ? i + 2 : i + 1];
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    // Soft gradient fill.
    final area = Path.from(line)
      ..lineTo(pts.last.dx, baseline)
      ..lineTo(pts.first.dx, baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader =
            ui.Gradient.linear(const Offset(0, padTop), Offset(0, baseline), [
          base.withValues(alpha: 0.26),
          base.withValues(alpha: 0.02),
        ]),
    );

    // Gentle glow + crisp stroke.
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = base.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
              Offset.zero, Offset(size.width, 0), [light, base]));

    // Data nodes.
    for (var i = 0; i < n; i++) {
      final isLast = i == n - 1, isSel = selected == i;
      if (isLast || isSel) {
        final glowR = (isLast ? 6.0 : 5.0) + (isLast ? 2 * pulse : 0);
        canvas.drawCircle(
            pts[i],
            glowR,
            Paint()
              ..color = base.withValues(alpha: 0.20)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(pts[i], isSel ? 5 : 4, Paint()..color = Colors.white);
        canvas.drawCircle(
            pts[i],
            isSel ? 5 : 4,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = base);
      } else {
        canvas.drawCircle(
            pts[i], 2, Paint()..color = base.withValues(alpha: 0.45));
      }
    }

    if (selected != null) {
      final p = pts[selected!];
      final label = fmt?.call(v[selected!]) ?? v[selected!].round().toString();
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      final bx =
          (p.dx - tp.width / 2 - 6).clamp(0.0, size.width - tp.width - 12);
      final r = RRect.fromLTRBR(bx, p.dy - tp.height - 16, bx + tp.width + 12,
          p.dy - 6, const Radius.circular(6));
      canvas.drawRRect(
          r, Paint()..color = const Color(0xFF241318).withValues(alpha: 0.96));
      canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = base.withValues(alpha: 0.45));
      tp.paint(canvas, Offset(bx + 6, p.dy - tp.height - 13));
    }
  }

  @override
  bool shouldRepaint(covariant _AreaPainter o) =>
      o.selected != selected || o.pulse != pulse || o.v != v || o.base != base;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2) Buddy Ring — interlocking double-arc gauge (You + Yaar), orange → light,
//    subtle glow, central stat + badge.
// ─────────────────────────────────────────────────────────────────────────────
class BuddyRing extends StatelessWidget {
  final double primary; // 0..1
  final double secondary; // 0..1
  final String centerValue;
  final String centerLabel;
  final String? badge;
  final double size;
  final Color? color;
  const BuddyRing({
    super.key,
    required this.primary,
    required this.secondary,
    required this.centerValue,
    required this.centerLabel,
    this.badge,
    this.size = 168,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    final light = _lighten(base, 0.4);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
              primary.clamp(0, 1), secondary.clamp(0, 1), base, light),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(centerValue,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(centerLabel,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white54, letterSpacing: 0.4)),
          if (badge != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: base.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: base.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bolt, size: 12, color: light),
                  const SizedBox(width: 3),
                  Text(badge!,
                      style: TextStyle(
                          fontSize: 11,
                          color: light,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double primary, secondary;
  final Color base, light;
  _RingPainter(this.primary, this.secondary, this.base, this.light);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rOuter = size.width / 2 - 10;
    final rInner = rOuter - 13;
    const start = -pi / 2;
    final outer = Rect.fromCircle(center: c, radius: rOuter);
    final inner = Rect.fromCircle(center: c, radius: rInner);

    Paint track(double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawArc(outer, start, 2 * pi, false, track(9));
    canvas.drawArc(inner, start, 2 * pi, false, track(7));

    final grad = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      colors: [base, light, base],
      transform: const GradientRotation(-pi / 2),
    ).createShader(outer);
    canvas.drawArc(
        outer,
        start,
        2 * pi * primary,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = base.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawArc(
        outer,
        start,
        2 * pi * primary,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..shader = grad);

    canvas.drawArc(
        inner,
        start,
        2 * pi * secondary,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = light.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.primary != primary || o.secondary != secondary || o.base != base;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) Streak Sparkline — rounded pill bars; training days glow in the app orange,
//    rest days are muted frosted capsules.
// ─────────────────────────────────────────────────────────────────────────────
class StreakSparkline extends StatelessWidget {
  final List<DayVolume> days;
  final double height;
  const StreakSparkline({super.key, required this.days, this.height = 84});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    final light = _lighten(base);
    final maxV = days.fold<double>(0, (a, b) => b.volume > a ? b.volume : a);
    final today = DateTime.now();
    const wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Bar(
                    day: d,
                    maxV: maxV,
                    wd: wd,
                    today: today,
                    base: base,
                    light: light),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final DayVolume day;
  final double maxV;
  final List<String> wd;
  final DateTime today;
  final Color base, light;
  const _Bar(
      {required this.day,
      required this.maxV,
      required this.wd,
      required this.today,
      required this.base,
      required this.light});

  @override
  Widget build(BuildContext context) {
    final active = day.volume > 0;
    final frac = maxV <= 0 ? 0.0 : (day.volume / maxV);
    final barH = active ? (12 + frac * 44) : 10.0;
    final isToday = day.day.year == today.year &&
        day.day.month == today.month &&
        day.day.day == today.day;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: barH,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [light, base])
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.05),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: base.withValues(alpha: 0.30),
                        blurRadius: 7,
                        spreadRadius: -2,
                        offset: const Offset(0, -2))
                  ]
                : null,
            border: isToday
                ? Border.all(color: Colors.white.withValues(alpha: 0.55))
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(wd[day.day.weekday - 1],
            style: TextStyle(
                fontSize: 10, color: isToday ? light : Colors.white38)),
      ],
    );
  }
}
