import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/google_config.dart';
import '../auth_provider.dart';

/// "Continue with Google" with an "or" divider above it. Renders nothing until
/// Google sign-in is configured (see [GoogleConfig]).
class GoogleSignInSection extends StatelessWidget {
  const GoogleSignInSection({super.key});

  Future<void> _signIn(BuildContext context, AuthProvider auth) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.loginWithGoogle();
    if (!ok && auth.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleConfig.enabled) return const SizedBox.shrink();
    final auth = context.watch<AuthProvider>();
    return Column(children: [
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child:
              Text('or', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
      ]),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: auth.loading ? null : () => _signIn(context, auth),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
                width: 20, height: 20, child: CustomPaint(painter: _GoogleG())),
            SizedBox(width: 12),
            Text('Continue with Google',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }
}

/// The four-colour Google "G".
class _GoogleG extends CustomPainter {
  const _GoogleG();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = math.pi / 180;
    canvas.drawArc(rect, -40 * deg, -100 * deg, false,
        p(const Color(0xFFEA4335))); // red, top
    canvas.drawArc(rect, -140 * deg, -90 * deg, false,
        p(const Color(0xFFFBBC05))); // yellow, left
    canvas.drawArc(rect, -230 * deg, -95 * deg, false,
        p(const Color(0xFF34A853))); // green, bottom
    canvas.drawArc(rect, 35 * deg, -75 * deg, false,
        p(const Color(0xFF4285F4))); // blue, right
    canvas.drawRect(
        Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
        Paint()..color = const Color(0xFF4285F4)); // the bar
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
