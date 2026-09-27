import 'package:flutter/material.dart';

import 'glass_button.dart';

/// Primary call-to-action. Kept visually identical to [GlassButton] (frosted
/// glass, not a bright solid fill) so every button across the app reads
/// uniformly — the same look as the "See all insights" style. Full-width by
/// default (hero CTAs); pass `expand: false` for inline buttons.
class AccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;

  const AccentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      expand: expand,
      loading: loading,
    );
  }
}
