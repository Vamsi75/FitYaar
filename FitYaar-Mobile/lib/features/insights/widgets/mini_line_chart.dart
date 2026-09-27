import 'package:flutter/material.dart';

/// Small line chart drawn with a CustomPainter (no external chart lib, matching
/// the app's custom-widget style). Points are plotted evenly by index; [labels]
/// (if given, same length as [values]) render under selected x positions.
class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double) formatY;

  const MiniLineChart({
    super.key,
    required this.values,
    this.labels = const [],
    required this.color,
    this.height = 160,
    required this.formatY,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Not enough data yet',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(
          values: values,
          labels: labels,
          color: color,
          formatY: formatY,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final String Function(double) formatY;

  _LinePainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.formatY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const rightPad = 10.0;
    const topPad = 14.0;
    const bottomPad = 22.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;

    double xAt(int i) => leftPad + chartW * (i / (values.length - 1));
    double yAt(double v) => topPad + chartH * (1 - (v - minV) / range);

    // Baseline + max gridlines with y labels.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final v in [minV, (minV + maxV) / 2, maxV]) {
      final y = yAt(v);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
      _text(canvas, formatY(v), Offset(0, y - 6),
          color: Colors.white38, size: 10, width: leftPad - 4, align: TextAlign.right);
    }

    // Build the line path.
    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(xAt(i), yAt(values[i]));
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }

    // Gradient fill under the line.
    final fillPath = Path.from(linePath)
      ..lineTo(xAt(values.length - 1), topPad + chartH)
      ..lineTo(xAt(0), topPad + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots.
    final dot = Paint()..color = color;
    final dotCore = Paint()..color = Colors.white;
    for (var i = 0; i < values.length; i++) {
      final p = Offset(xAt(i), yAt(values[i]));
      canvas.drawCircle(p, 4, dot);
      canvas.drawCircle(p, 1.6, dotCore);
    }

    // X labels: first, middle, last (only if provided).
    if (labels.length == values.length) {
      final idxs = {0, values.length ~/ 2, values.length - 1};
      for (final i in idxs) {
        _text(canvas, labels[i], Offset(xAt(i) - 24, size.height - bottomPad + 4),
            color: Colors.white38, size: 10, width: 48, align: TextAlign.center);
      }
    }
  }

  void _text(Canvas canvas, String s, Offset at,
      {required Color color, required double size, required double width, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.color != color || old.labels != labels;
}
