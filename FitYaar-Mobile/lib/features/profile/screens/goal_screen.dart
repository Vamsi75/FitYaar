import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../insights/analytics.dart';
import '../../insights/goal_progress.dart';
import '../widgets/goal_visuals.dart';
import '../../workout/models/workout_models.dart';
import '../../workout/workout_service.dart';
import '../goal_options.dart';
import '../measurement_models.dart';
import '../measurement_service.dart';
import '../profile_models.dart';
import '../profile_service.dart';
import 'go_pro_screen.dart';

const Map<String, String> _tips = {
  'Lose weight':
      'Stay in a small calorie deficit, keep protein high, and lift to preserve muscle. Slow and steady wins.',
  'Build muscle':
      'Eat in a slight surplus, hit each muscle 2× a week, and add weight or reps over time (progressive overload).',
  'Get stronger':
      'Focus on a few main lifts, add weight or a rep each week, and rest 2–3 min on heavy sets.',
  'Improve endurance':
      'Build your weekly minutes gradually, mix steady cardio with intervals, and prioritise recovery.',
};

typedef _GoalData = ({
  ProfileData? profile,
  List<BodyMeasurement> measurements,
  List<WorkoutSession> sessions,
});

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late Future<_GoalData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GoalData> _load() async {
    final profileSvc = context.read<ProfileService>();
    final measureSvc = context.read<MeasurementService>();
    final workoutSvc = context.read<WorkoutService>();
    ProfileData? profile;
    try {
      profile = await profileSvc.getProfile();
    } catch (_) {}
    List<BodyMeasurement> ms = const [];
    try {
      ms = await measureSvc.list();
    } catch (_) {}
    List<WorkoutSession> ss = const [];
    try {
      ss = await workoutSvc.getHistory();
    } catch (_) {}
    return (profile: profile, measurements: ms, sessions: ss);
  }

  void _reload() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Goal'),
        actions: [
          IconButton(
              onPressed: () => _editGoal(null),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit goal'),
        ],
      ),
      body: FutureBuilder<_GoalData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          final profile = data?.profile;
          if (profile == null || (profile.fitnessGoal ?? '').isEmpty) {
            return _noGoal(context);
          }
          return _content(context, profile, data!.measurements, data.sessions);
        },
      ),
    );
  }

  Widget _noGoal(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('No goal set yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Pick a goal and we\'ll track your progress toward it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            GlassButton(
                icon: Icons.flag, label: 'Set a goal', onPressed: () => _editGoal(null)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ProfileData profile,
      List<BodyMeasurement> ms, List<WorkoutSession> sessions) {
    final theme = Theme.of(context);
    final goal = profile.fitnessGoal!;
    final isLoss = goal.toLowerCase().contains('lose') || goal.toLowerCase().contains('loss');
    final isGain = goal.toLowerCase().contains('muscle') || goal.toLowerCase().contains('gain');
    final isWeight = isLoss || isGain;

    final progress = buildGoalProgress(
      goal: goal,
      profileCurrentWeight: profile.currentWeight,
      targetWeight: profile.targetWeight,
      measurements: ms,
      sessions: sessions,
    );

    final weights = ms.where((m) => m.weightKg != null).toList();
    final latest = weights.isNotEmpty ? weights.last.weightKg : profile.currentWeight;
    final eta = isWeight
        ? weightEta(
            isLoss: isLoss,
            latest: latest,
            target: profile.targetWeight,
            measurements: ms)
        : null;
    final reached = eta?.reached ?? (progress?.fraction != null && progress!.fraction! >= 1.0);

    // Neon visual data.
    final consistency = weeklyConsistency(sessions);
    final trendPct = strengthTrendPct(sessions);
    final volSeries = weeklyVolumeSeries(sessions, weeks: 12);
    final daySeries = dailyVolumeSeries(sessions, days: 14);
    final weightVals = weights.map((m) => m.weightKg!).toList();
    final chartIsWeight = isWeight && weightVals.length >= 2;
    final hasVolume = volSeries.any((v) => v > 0);
    final trendBadge = trendPct.abs() >= 1
        ? '${trendPct > 0 ? '+' : ''}${trendPct.round()}% vol'
        : null;

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (reached) _reachedBanner(theme),
          if (progress != null) GoalProgressCard(progress: progress),
          const SizedBox(height: 16),
          _ringCard(theme, consistency, progress?.fraction ?? 0, trendBadge),
          const SizedBox(height: 16),
          if (chartIsWeight) ...[
            _chartCard(theme, 'Weight trend', weightVals,
                (v) => '${v.toStringAsFixed(0)} kg'),
            const SizedBox(height: 16),
          ] else if (hasVolume) ...[
            _chartCard(theme, 'Weekly volume', volSeries, _fmtVol),
            const SizedBox(height: 16),
          ],
          _streakCard(theme, daySeries),
          const SizedBox(height: 16),
          if (isWeight) ...[
            _etaCard(theme, eta, profile),
            const SizedBox(height: 16),
            _milestones(theme, progress?.fraction ?? 0),
            const SizedBox(height: 16),
          ],
          if (profile.dailyCalorieGoal != null && profile.dailyCalorieGoal! > 0) ...[
            _calorieCard(theme, profile.dailyCalorieGoal!.round()),
            const SizedBox(height: 16),
          ],
          _tipCard(theme, goal),
          const SizedBox(height: 20),
          GlassButton(
            icon: Icons.edit,
            label: reached ? 'Set a new goal' : 'Edit goal',
            expand: true,
            onPressed: () => _editGoal(profile),
          ),
        ],
      ),
    );
  }

  Widget _reachedBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.amber.withValues(alpha: 0.25),
          theme.colorScheme.primary.withValues(alpha: 0.20),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goal reached!',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Amazing work. Ready for the next challenge?',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _etaCard(ThemeData theme, WeightEta? eta, ProfileData profile) {
    String title = 'Estimated time';
    String body;
    IconData icon = Icons.schedule;
    if (eta == null) {
      body = 'Log your weight a couple of times so we can estimate your finish date.';
    } else if (eta.reached) {
      icon = Icons.emoji_events;
      body = 'You\'ve hit your target weight of ${profile.targetWeight} kg!';
    } else if (!eta.onTrack) {
      icon = Icons.trending_flat;
      body =
          'No progress toward your target in the last 30 days. Small consistent changes add up — you\'ve got this.';
    } else {
      final weeks = eta.weeks!;
      final wLabel = weeks < 1
          ? 'under a week'
          : '${weeks.round()} ${weeks.round() == 1 ? 'week' : 'weeks'}';
      final date = DateFormat('d MMM yyyy').format(eta.date!);
      body =
          'At ~${eta.ratePerWeek.toStringAsFixed(1)} kg/week, you\'ll reach ${profile.targetWeight} kg in about $wLabel — around $date.';
    }
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtVol(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}t' : '${v.round()} kg';

  Widget _ringCard(ThemeData theme, ({int done, int target}) c,
      double goalFrac, String? badge) {
    final primary = c.target == 0 ? 0.0 : c.done / c.target;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Center(
            child: BuddyRing(
              primary: primary,
              secondary: goalFrac,
              centerValue: '${c.done}/${c.target}',
              centerLabel: 'WORKOUTS',
              badge: badge,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              c.done >= c.target
                  ? 'Weekly target smashed 🔥'
                  : '${c.target - c.done} to go this week',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(ThemeData theme, String title, List<double> values,
      String Function(double) fmt) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: theme.textTheme.titleMedium),
            const Spacer(),
            const Text('tap points',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 14),
          MoltenAreaChart(values: values, height: 170, formatValue: fmt),
        ],
      ),
    );
  }

  Widget _streakCard(ThemeData theme, List<DayVolume> days) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 14 days', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          StreakSparkline(days: days),
        ],
      ),
    );
  }

  Widget _milestones(ThemeData theme, double fraction) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Milestones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final pct in [0.25, 0.5, 0.75, 1.0])
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: fraction >= pct
                            ? theme.colorScheme.primary
                            : Colors.white.withValues(alpha: 0.08),
                        child: Icon(
                          fraction >= pct ? Icons.check : Icons.flag_outlined,
                          size: 16,
                          color: fraction >= pct ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${(pct * 100).round()}%',
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieCard(ThemeData theme, int kcal) {
    return GlassCard(
      child: Row(children: [
        Icon(Icons.local_fire_department, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily calorie target', style: theme.textTheme.titleMedium),
              Text('$kcal kcal / day',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tipCard(ThemeData theme, String goal) {
    final tip = _tips[goal] ?? 'Keep showing up — progress compounds.';
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(ProfileData? profile) async {
    var goal = profile?.fitnessGoal ?? 'Lose weight';
    final targetCtrl = TextEditingController(
        text: profile?.targetWeight != null ? '${profile!.targetWeight}' : '');
    final calCtrl = TextEditingController(
        text: profile?.dailyCalorieGoal != null
            ? '${profile!.dailyCalorieGoal!.round()}'
            : '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1214),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final isWeight = goal == 'Lose weight' || goal == 'Build muscle';
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set your goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                GoalPillGrid(
                  selected: goal,
                  isPro: context.read<AuthProvider>().isPro,
                  onSelect: (l) => setSheet(() => goal = l),
                  onPremiumTap: () => Navigator.of(ctx).push(
                      MaterialPageRoute(builder: (_) => const GoProScreen())),
                ),
                if (isWeight) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Target weight (kg)',
                        border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: calCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Daily calorie target (kcal) — optional',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                GlassButton(
                  icon: Icons.check,
                  label: 'Save goal',
                  expand: true,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );

    if (saved != true || !mounted) return;
    final isWeight = goal == 'Lose weight' || goal == 'Build muscle';
    final messenger = ScaffoldMessenger.of(context);
    final profileSvc = context.read<ProfileService>();
    var ok = true;
    try {
      await profileSvc.updateProfile(
        fitnessGoal: goal,
        targetWeight: isWeight ? double.tryParse(targetCtrl.text.trim()) : null,
        dailyCalorieGoal: double.tryParse(calCtrl.text.trim()),
      );
    } catch (_) {
      // The write often applies even when the response trips a transient error;
      // verify before reporting failure.
      try {
        ok = (await profileSvc.getProfile()).fitnessGoal == goal;
      } catch (_) {
        ok = false;
      }
    }
    if (!mounted) return;
    _reload();
    messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'Goal updated 🎯' : 'Could not save goal.')));
  }
}
