import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../analytics.dart';
import '../body_paths.dart';

// The heatmap keys on the body-map slug directly (see analytics.muscleSlugLabel /
// muscleGroupToSlug), so biceps, triceps, quads, hams, etc. highlight individually.
// Non-muscle slugs (head/hands/feet/…) aren't in the label map and stay faint.

final Map<String, Map<String, Path>> _pathCache = {};

Map<String, List<String>> _rawFor(String key) => switch (key) {
      'maleFront' => maleFront,
      'maleBack' => maleBack,
      'femaleFront' => femaleFront,
      'femaleBack' => femaleBack,
      _ => maleFront,
    };

Map<String, Path> _parsed(String key) {
  return _pathCache.putIfAbsent(key, () {
    final out = <String, Path>{};
    _rawFor(key).forEach((slug, strings) {
      final p = Path();
      for (final s in strings) {
        p.addPath(parseSvgPathData(s), Offset.zero);
      }
      out[slug] = p;
    });
    return out;
  });
}

/// Renders the anatomical body (front and/or back) with each muscle filled by
/// [intensity] (region -> 0..1) in the app's primary colour. Shared by the
/// Insights muscle-map card and the post-workout summary.
class MuscleBody extends StatelessWidget {
  /// Slug -> 0..1 intensity (see analytics.muscleGroupToSlug).
  final Map<String, double> intensity;
  final String? gender;
  final String? selected;
  final void Function(String?)? onTapMuscle;
  final double height;
  final bool showFront;
  final bool showBack;

  const MuscleBody({
    super.key,
    required this.intensity,
    this.gender,
    this.selected,
    this.onTapMuscle,
    this.height = 260,
    this.showFront = true,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final female = (gender ?? '').toLowerCase().startsWith('f');
    final g = female ? 'female' : 'male';
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showFront) Flexible(child: _figure(context, '${g}Front')),
          if (showFront && showBack) const SizedBox(width: 8),
          if (showBack) Flexible(child: _figure(context, '${g}Back')),
        ],
      ),
    );
  }

  Widget _figure(BuildContext context, String key) {
    final vb = bodyViewBox[key]!;
    final paths = _parsed(key);
    final color = Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: vb.width / vb.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final scale = c.maxWidth / vb.width;
          final painter = _MusclePainter(
            paths: paths,
            viewBox: vb,
            intensity: intensity,
            selected: selected,
            color: color,
          );
          final canvas = CustomPaint(painter: painter, size: Size.infinite);
          if (onTapMuscle == null) return canvas;
          return GestureDetector(
            onTapDown: (d) {
              final pt = Offset(
                  d.localPosition.dx / scale + vb.minX, d.localPosition.dy / scale + vb.minY);
              for (final e in paths.entries) {
                if (muscleSlugLabel.containsKey(e.key) && e.value.contains(pt)) {
                  onTapMuscle!(selected == e.key ? null : e.key);
                  return;
                }
              }
              onTapMuscle!(null);
            },
            child: canvas,
          );
        },
      ),
    );
  }
}

class _MusclePainter extends CustomPainter {
  final Map<String, Path> paths;
  final BodyViewBox viewBox;
  final Map<String, double> intensity;
  final String? selected;
  final Color color;

  _MusclePainter({
    required this.paths,
    required this.viewBox,
    required this.intensity,
    required this.selected,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    canvas.save();
    canvas.translate(-viewBox.minX * scale, -viewBox.minY * scale);
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / scale
      ..color = Colors.white.withValues(alpha: 0.14);

    paths.forEach((slug, path) {
      final t = intensity[slug] ?? 0;
      final fill = Paint()..style = PaintingStyle.fill;
      if (t > 0) {
        fill.color = color.withValues(alpha: 0.28 + 0.62 * t);
      } else {
        fill.color = Colors.white.withValues(alpha: 0.055);
      }
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    });

    if (selected != null) {
      final sel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 / scale
        ..color = Colors.white.withValues(alpha: 0.95);
      final path = paths[selected];
      if (path != null) canvas.drawPath(path, sel);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.intensity != intensity ||
      old.selected != selected ||
      old.viewBox != viewBox ||
      !identical(old.paths, paths);
}
