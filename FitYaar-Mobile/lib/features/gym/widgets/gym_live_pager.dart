import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../gym_alert_prefs.dart';
import '../gym_focus.dart';
import '../gym_models.dart';
import '../gym_notifications.dart';
import 'glow_avatar.dart';
import 'orbit_dial.dart';
import 'trend_orbit.dart';
import 'zone_rings.dart';

/// The gym "live" section as a single swipeable card: page 1 = live occupancy
/// (default), page 2 = zone occupancy, page 3 = today's rhythm. A bell opens the
/// density-alert settings. Replaces the old separate GymLiveScreen.
class GymLivePager extends StatefulWidget {
  final GymSummary gym;
  final List<GymActivityItem> activity; // focus (Push/Pull/Legs)
  final List<GymActivityItem> zones;
  final List<HourlyBucket> trends;
  final List<ActiveMember> active;
  const GymLivePager({
    super.key,
    required this.gym,
    required this.activity,
    required this.zones,
    required this.trends,
    required this.active,
  });

  @override
  State<GymLivePager> createState() => _GymLivePagerState();
}

class _GymLivePagerState extends State<GymLivePager> {
  final _controller = PageController();
  int _page = 0;

  static const _titles = ['Live now', 'Zones right now', "Today's rhythm"];
  static const _icons = [Icons.blur_circular, Icons.hub_outlined, Icons.access_time];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_icons[_page], size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(_titles[_page], style: theme.textTheme.titleMedium),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Density alert',
              icon: Icon(Icons.notifications_active_outlined,
                  size: 20, color: theme.colorScheme.primary),
              onPressed: () => _openAlerts(context),
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            height: 320,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _scroll(_livePage(theme)),
                _scroll(ZoneRings(zones: widget.zones)),
                _scroll(TrendOrbit(buckets: widget.trends)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? theme.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _scroll(Widget child) =>
      SingleChildScrollView(physics: const ClampingScrollPhysics(), child: child);

  Widget _livePage(ThemeData theme) {
    return Column(
      children: [
        Center(
            child: OrbitDial(
                liveCount: widget.gym.liveCount, capacity: widget.gym.capacity, size: 184)),
        if (widget.active.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final a in widget.active.take(8))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GlowAvatar(name: a.displayName),
              ),
            if (widget.active.length > 8)
              Text('+${widget.active.length - 8}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ],
        if (widget.activity.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final a in widget.activity)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(focusIcon(a.label), size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('${a.count} ${focusVerb(a.label)}', style: const TextStyle(fontSize: 13)),
                ]),
              ),
          ]),
        ],
      ],
    );
  }

  void _openAlerts(BuildContext context) {
    final hasCap = (widget.gym.capacity ?? 0) > 0;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1214),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AlertSheet(gym: widget.gym, hasCapacity: hasCap),
    );
  }

}

/// Density-alert settings bottom sheet (toggle + threshold), persisted per gym.
class _AlertSheet extends StatefulWidget {
  final GymSummary gym;
  final bool hasCapacity;
  const _AlertSheet({required this.gym, required this.hasCapacity});

  @override
  State<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<_AlertSheet> {
  bool _on = false;
  int _threshold = 50;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    GymAlertPrefs.load(widget.gym.gymId).then((p) {
      if (mounted) {
        setState(() {
          _on = p.enabled;
          _threshold = p.thresholdPct;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _save() =>
      GymAlertPrefs.save(widget.gym.gymId, enabled: _on, thresholdPct: _threshold);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Density alert',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _on,
                activeThumbColor: theme.colorScheme.primary,
                title: Text('Notify me when under $_threshold%'),
                subtitle: Text(
                    widget.hasCapacity
                        ? 'A heads-up when the crowd drops below your threshold.'
                        : 'This gym has no capacity set yet, so alerts can\'t be calculated.',
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
                onChanged: widget.hasCapacity
                    ? (v) async {
                        setState(() => _on = v);
                        if (v) await GymNotifications.instance.requestPermission();
                        await _save();
                      }
                    : null,
              ),
              if (_on && widget.hasCapacity)
                Slider(
                  value: _threshold.toDouble(),
                  min: 10,
                  max: 90,
                  divisions: 8,
                  label: '$_threshold%',
                  onChanged: (v) => setState(() => _threshold = v.round()),
                  onChangeEnd: (_) => _save(),
                ),
              Text(
                'Alerts fire while FitYaar is open and watching this gym. '
                'Always-on background push arrives with notifications (Phase 5).',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
