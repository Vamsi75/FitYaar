import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Equipment glyph rendered from a bundled MIT line-icon SVG (Tabler /
/// Hugeicons — see assets/equipment/ATTRIBUTION.md), tinted to the brand palette
/// and set in a warm glass circle so the whole set matches the app theme.
class EquipmentIcon extends StatelessWidget {
  final String token; // backend Equipment enum token
  final double size;
  final Color? color; // overrides the icon tint (e.g. orange when selected)
  final bool selected;
  const EquipmentIcon(
    this.token, {
    super.key,
    this.size = 48,
    this.color,
    this.selected = false,
  });

  static const _asset = {
    'BARBELL': 'barbell',
    'DUMBBELL': 'dumbbell',
    'MACHINE': 'machine',
    'CABLE': 'cable',
    'KETTLEBELL': 'kettlebell',
    'PLATE': 'plate',
    'BAND': 'band',
    'NO_EQUIPMENT': 'bodyweight',
    'OTHER': 'other',
  };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final on = selected || color != null;
    // Warm, on-brand: light-peach glyph by default, orange when selected.
    final tint = color ?? (on ? primary : const Color(0xFFFFCC80));
    final name = _asset[token] ?? 'other';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withValues(alpha: on ? 0.18 : 0.10),
        border: Border.all(color: primary.withValues(alpha: on ? 0.55 : 0.22)),
      ),
      padding: EdgeInsets.all(size * 0.26),
      child: SvgPicture.asset(
        'assets/equipment/$name.svg',
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      ),
    );
  }
}
