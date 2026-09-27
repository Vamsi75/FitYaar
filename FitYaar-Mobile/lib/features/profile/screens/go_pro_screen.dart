import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/auth_provider.dart';

/// Subscription upsell. Individual checkout happens on the **web** (Razorpay) to
/// avoid app-store fees; this opens the web checkout page and reflects live Pro state.
class GoProScreen extends StatefulWidget {
  const GoProScreen({super.key});

  @override
  State<GoProScreen> createState() => _GoProScreenState();
}

class _GoProScreenState extends State<GoProScreen> {
  @override
  void initState() {
    super.initState();
    // Pick up a freshly-granted entitlement (super-admin / gym plan) on landing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refreshEntitlements();
    });
  }

  Future<void> _checkout(String plan) async {
    final uri = Uri.parse('${ApiConfig.webBaseUrl}/checkout.html?plan=$plan');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the checkout page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('FitYaar Pro')),
      body: auth.isPro ? _proState(theme, auth) : _plansState(theme),
    );
  }

  Widget _proState(ThemeData theme, AuthProvider auth) {
    final until = auth.proUntil;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          tint: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text("You're on FitYaar Pro",
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(auth.proPlan == null
                  ? 'All Pro features are unlocked.'
                  : 'Plan: ${auth.proPlan}'),
              const SizedBox(height: 4),
              Text(
                until == null
                    ? 'Lifetime / gym-sponsored — never expires.'
                    : 'Valid until ${until.toLocal().toString().split(' ').first}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _plansState(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          tint: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Unlock FitYaar Pro',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Longer progress history (1 year & all-time), advanced '
                  'analytics, premium goals, and more.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _plan('Monthly', '₹199 / mo', false, 'MONTHLY'),
        _plan('Yearly', '₹1,499 / yr', true, 'YEARLY'),
        _plan('Lifetime', '₹4,999 once', false, 'LIFETIME'),
        const SizedBox(height: 16),
        GlassButton(
          icon: Icons.workspace_premium,
          label: 'Continue to secure checkout',
          onPressed: () => _checkout('YEARLY'),
        ),
        const SizedBox(height: 8),
        const Text('Payments are handled securely on the web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _plan(String name, String price, bool best, String planCode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _checkout(planCode),
        child: GlassCard(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      if (best) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Best value',
                              style: TextStyle(fontSize: 11, color: Colors.amber)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(price, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
