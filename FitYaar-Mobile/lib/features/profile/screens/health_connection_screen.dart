import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/health/health_sync_service.dart';
import '../../../core/widgets/glass_card.dart';

/// Settings → Integrations → Health Connect / Apple Health.
class HealthConnectionScreen extends StatefulWidget {
  const HealthConnectionScreen({super.key});

  @override
  State<HealthConnectionScreen> createState() => _HealthConnectionScreenState();
}

class _HealthConnectionScreenState extends State<HealthConnectionScreen> {
  HealthAvailability? _availability;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final health = context.read<HealthSyncService>();
    await health.load();
    final a = await health.availability();
    if (mounted) setState(() => _availability = a);
  }

  Future<void> _toggle(bool connect) async {
    final health = context.read<HealthSyncService>();
    setState(() => _busy = true);
    if (connect) {
      final ok = await health.connect();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${health.storeName} access wasn\'t granted.')));
      }
    } else {
      await health.disconnect();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthSyncService>();
    final theme = Theme.of(context);
    final ios = health.storeName == 'Apple Health';

    return Scaffold(
      appBar: AppBar(title: Text(health.storeName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!health.isSupported)
            const GlassCard(
              child: Text('Watch sync works in the Android and iOS apps.',
                  style: TextStyle(color: Colors.white70)),
            )
          else if (_availability == null)
            const Center(child: CircularProgressIndicator())
          else if (_availability != HealthAvailability.available)
            GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _availability == HealthAvailability.updateRequired
                      ? 'Health Connect needs an update'
                      : 'Health Connect isn\'t installed',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                    'Health Connect is Google\'s on-phone health store. Your watch\'s app '
                    'writes to it and FitYaar reads from it.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    await health.installHealthConnect();
                  },
                  icon: const Icon(Icons.download),
                  label: Text(_availability == HealthAvailability.updateRequired
                      ? 'Update Health Connect'
                      : 'Install Health Connect'),
                ),
                TextButton(onPressed: _refresh, child: const Text('I\'ve installed it')),
              ]),
            )
          else
            GlassCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: health.isConnected,
                onChanged: _busy ? null : _toggle,
                title: Text('Connect ${health.storeName}'),
                subtitle: Text(
                  health.isConnected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                      color: health.isConnected ? const Color(0xFF37E29A) : Colors.white54),
                ),
              ),
            ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('What FitYaar uses', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _bullet(Icons.favorite, 'Reads heart rate and active calories during your '
                  'workouts, for the heart-rate card on your workout summary.'),
              _bullet(Icons.fitness_center,
                  'Saves finished workouts to ${health.storeName} so they count toward your activity.'),
              _bullet(Icons.lock_outline,
                  'Nothing else is read. Only the summary (average/max heart rate, zones, '
                  'calories) is stored with your workout.'),
            ]),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Works with', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                ios
                    ? 'Apple Watch, plus any watch whose app writes to Apple Health — '
                        'Fitbit / Fitbit Air (Google Health app), Garmin, and more.'
                    : 'Any watch whose app syncs to Health Connect — Fitbit, Pixel Watch and '
                        'Fitbit Air (Google Health app), Galaxy Watch (Samsung Health), '
                        'Garmin (Garmin Connect), and more. Turn on Health Connect sync in '
                        'your watch\'s app.',
                style: const TextStyle(color: Colors.white70),
              ),
              if (!ios) ...[
                const SizedBox(height: 8),
                const Text(
                    'Data shows up after your watch syncs, which can take a few minutes '
                    'after a workout.',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
              if (ios && health.isConnected) ...[
                const SizedBox(height: 8),
                const Text(
                    'To stop sharing, also turn FitYaar off in the Health app → '
                    'Sharing → Apps.',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ]),
      );
}
