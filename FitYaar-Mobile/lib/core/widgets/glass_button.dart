import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted light-orange button matching the glass UI.
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final bool dense;

  /// Stretch to the parent's width and center the content (for primary CTAs).
  final bool expand;

  /// Show a spinner instead of the label and ignore taps.
  final bool loading;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.dense = false,
    this.expand = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fg = Colors.orange.shade200;
    final radius = BorderRadius.circular(14);
    final disabled = loading || onPressed == null;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: primary.withValues(alpha: disabled ? 0.10 : 0.16),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: primary.withValues(alpha: 0.45)),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: dense ? 14 : 18, vertical: dense ? 8 : 12),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment:
                    expand ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  if (loading)
                    SizedBox(
                      height: dense ? 16 : 18,
                      width: dense ? 16 : 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: dense ? 18 : 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: dense ? 14 : 15)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
