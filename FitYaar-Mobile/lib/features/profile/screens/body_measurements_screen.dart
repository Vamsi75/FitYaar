import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../insights/goal_progress.dart';
import '../../insights/widgets/mini_line_chart.dart';
import '../../workout/models/workout_models.dart';
import '../../workout/workout_service.dart';
import '../measurement_models.dart';
import '../measurement_service.dart';
import '../profile_models.dart';
import '../profile_service.dart';

/// Log & track body measurements (weight, waist, body fat) with a trend chart.
class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  List<BodyMeasurement> _items = [];
  GoalProgress? _goal;
  bool _loading = true;
  BodyMetric _metric = BodyMetric.weight;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final measureSvc = context.read<MeasurementService>();
    final profileSvc = context.read<ProfileService>();
    final workoutSvc = context.read<WorkoutService>();
    try {
      final items = await measureSvc.list();
      ProfileData? profile;
      try {
        profile = await profileSvc.getProfile();
      } catch (_) {}
      List<WorkoutSession> sessions = const [];
      try {
        sessions = await workoutSvc.getHistory();
      } catch (_) {}
      final goal = profile == null
          ? null
          : buildGoalProgress(
              goal: profile.fitnessGoal,
              profileCurrentWeight: profile.currentWeight,
              targetWeight: profile.targetWeight,
              measurements: items,
              sessions: sessions,
            );
      if (mounted) {
        setState(() {
          _items = items;
          _goal = goal;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withMetric = _items.where((m) => m.metric(_metric) != null).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurements'),
        actions: [
          IconButton(
              onPressed: _logDialog, icon: const Icon(Icons.add), tooltip: 'Log entry'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_goal != null) ...[
                    GoalProgressCard(progress: _goal!),
                    const SizedBox(height: 16),
                  ],
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _metricSelector(theme),
                        const SizedBox(height: 6),
                        Text('${bodyMetricLabel(_metric)} · ${bodyMetricUnit(_metric)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 12),
                        if (withMetric.length < 2)
                          SizedBox(
                            height: 140,
                            child: Center(
                              child: Text(
                                  'Log your ${bodyMetricLabel(_metric).toLowerCase()} to see the trend',
                                  style: const TextStyle(color: Colors.white54)),
                            ),
                          )
                        else
                          MiniLineChart(
                            values: withMetric.map((m) => m.metric(_metric)!).toList(),
                            labels: withMetric.map((m) => DateFormat('d MMM').format(m.date)).toList(),
                            color: theme.colorScheme.primary,
                            height: 180,
                            formatY: (v) =>
                                v.toStringAsFixed(_metric == BodyMetric.weight ? 0 : 1),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassButton(
                    icon: Icons.add,
                    label: 'Log today',
                    expand: true,
                    onPressed: _logDialog,
                  ),
                  const SizedBox(height: 20),
                  Text('History', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const GlassCard(
                        child: Text('No entries yet.',
                            style: TextStyle(color: Colors.white70)))
                  else
                    for (final m in _items.reversed) _entryTile(theme, m),
                ],
              ),
            ),
    );
  }

  Widget _metricSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in BodyMetric.values)
            GestureDetector(
              onTap: () => setState(() => _metric = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: m == _metric
                      ? theme.colorScheme.primary.withValues(alpha: 0.9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(bodyMetricLabel(m),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: m == _metric ? FontWeight.w600 : FontWeight.normal,
                        color: m == _metric ? Colors.white : Colors.white70)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryTile(ThemeData theme, BodyMeasurement m) {
    final parts = <String>[
      if (m.weightKg != null) '${m.weightKg} kg',
      if (m.waistCm != null) '${m.waistCm} cm',
      if (m.bodyFatPct != null) '${m.bodyFatPct}%',
    ];
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEE, d MMM yyyy').format(m.date),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (parts.isNotEmpty)
                  Text(parts.join(' · '),
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
            onPressed: () => _delete(m),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BodyMeasurement m) async {
    final svc = context.read<MeasurementService>();
    try {
      await svc.delete(m.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _logDialog() async {
    final latest = _items.isNotEmpty ? _items.last : null;
    final w = TextEditingController(text: latest?.weightKg?.toString() ?? '');
    final waist = TextEditingController(text: latest?.waistCm?.toString() ?? '');
    final bf = TextEditingController(text: latest?.bodyFatPct?.toString() ?? '');
    final svc = context.read<MeasurementService>();
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log today'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(w, 'Weight (kg)'),
            const SizedBox(height: 12),
            _field(waist, 'Waist (cm) — optional'),
            const SizedBox(height: 12),
            _field(bf, 'Body fat (%) — optional'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    try {
      await svc.upsert(
        weightKg: double.tryParse(w.text.trim()),
        waistCm: double.tryParse(waist.text.trim()),
        bodyFatPct: double.tryParse(bf.text.trim()),
      );
      await _load();
      if (mounted && _goal != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_goal!.message}  ${_goal!.cheer}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not save entry.')));
      }
    }
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
