import 'package:flutter/material.dart';

/// Frosted input decoration used by the login / register forms so the text
/// fields read as glass over the app's dark gradient.
InputDecoration glassField(
  BuildContext context, {
  required String label,
  required IconData icon,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: border(Colors.white.withValues(alpha: 0.14)),
    focusedBorder: border(primary.withValues(alpha: 0.7)),
    errorBorder: border(Colors.redAccent.withValues(alpha: 0.6)),
    focusedErrorBorder: border(Colors.redAccent),
    border: border(Colors.white.withValues(alpha: 0.14)),
  );
}

/// The FitYaar app-icon mark — the header of the auth screens.
class AuthLogoBadge extends StatelessWidget {
  const AuthLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Transparent icon (glow baked in) — blends straight onto the gradient.
    return Image.asset(
      'assets/brand/app_icon.png',
      height: 116,
      width: 116,
      filterQuality: FilterQuality.medium,
    );
  }
}
