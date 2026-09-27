import 'package:flutter/material.dart';

import '../../insights/analytics.dart' show muscleGroupToSlug;
import '../../insights/widgets/muscle_body.dart';

/// A small circular silhouette thumbnail with one muscle highlighted, reusing
/// the app's [MuscleBody] heatmap. No external images — it renders the same SVG
/// art the insights heatmap uses, scaled to fill and cropped to the region.
class MuscleThumb extends StatelessWidget {
  final String muscleToken; // backend MuscleGroup enum token
  final double size;
  final String? gender;
  final bool selected;
  const MuscleThumb(
    this.muscleToken, {
    super.key,
    this.size = 56,
    this.gender,
    this.selected = false,
  });

  // Muscles best seen from the back figure.
  static const _back = {
    'upper-back',
    'lower-back',
    'trapezius',
    'triceps',
    'hamstring',
    'gluteal',
    'calves',
  };

  // Vertical crop focus per slug (-1 top … 1 bottom of the tall figure).
  static double _focusY(String? slug) {
    switch (slug) {
      case 'neck':
      case 'trapezius':
        return -0.8;
      case 'chest':
      case 'deltoids':
      case 'upper-back':
        return -0.55;
      case 'biceps':
      case 'triceps':
      case 'forearm':
      case 'abs':
      case 'obliques':
      case 'lower-back':
        return -0.15;
      case 'gluteal':
      case 'hamstring':
      case 'quadriceps':
        return 0.35;
      case 'calves':
        return 0.85;
      default:
        return -0.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final slug = muscleGroupToSlug[muscleToken];
    final back = slug != null && _back.contains(slug);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: selected ? primary : Colors.white.withValues(alpha: 0.12),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // FittedBox scales the fixed-size figure to fill the circle's width;
      // the extra height overflows and is cropped to the focus region.
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment(0, _focusY(slug)),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: 120,
          height: 240,
          child: MuscleBody(
            intensity: slug != null ? {slug: 1.0} : const {},
            gender: gender,
            showFront: !back,
            showBack: back,
            height: 240,
          ),
        ),
      ),
    );
  }
}
