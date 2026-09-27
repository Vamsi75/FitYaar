import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/accent_button.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_pill.dart';
import '../auth/auth_provider.dart';
import '../gym/widgets/gym_entry_card.dart';
import '../insights/insights_screen.dart';
import '../insights/widgets/neglected_muscle_card.dart';
import '../insights/widgets/strongest_lift_card.dart';
import '../insights/widgets/weekly_consistency_card.dart';
import '../workout/active_workout_model.dart';
import '../workout/models/workout_models.dart';
import '../workout/screens/active_workout_screen.dart';
import '../workout/workout_service.dart';

typedef HomeData = ({List<WorkoutSession> sessions, Map<int, Exercise> catalog});

/// Landing dashboard: greeting, quick start, headline stats and progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _data;

  ActiveWorkoutModel? _workout;
  bool _wasWorkoutActive = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<HomeData> _load() async {
    final svc = context.read<WorkoutService>();
    final results = await Future.wait([svc.getHistory(), svc.searchExercises('')]);
    final sessions = results[0] as List<WorkoutSession>;
    final exercises = results[1] as List<Exercise>;
    return (sessions: sessions, catalog: {for (final e in exercises) e.id: e});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = context.read<ActiveWorkoutModel>();
    if (!identical(model, _workout)) {
      _workout?.removeListener(_onWorkoutChanged);
      _workout = model;
      _wasWorkoutActive = model.isActive;
      _workout!.addListener(_onWorkoutChanged);
    }
  }

  /// Reload stats + progress once a workout finishes.
  void _onWorkoutChanged() {
    final active = _workout?.isActive ?? false;
    if (_wasWorkoutActive && !active && mounted) {
      setState(() {
        _data = _load();
      });
    }
    _wasWorkoutActive = active;
  }

  @override
  void dispose() {
    _workout?.removeListener(_onWorkoutChanged);
    super.dispose();
  }

  void _startWorkout() {
    context.read<ActiveWorkoutModel>().start(title: 'New Workout');
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = context.watch<AuthProvider>().user?.displayName;
    return Scaffold(
      appBar: AppBar(title: const Text('FitYaar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hey${name != null ? ', $name' : ''} 👋',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Ready to move? Log today\'s session.'),
                const SizedBox(height: 16),
                AccentButton(
                  onPressed: _startWorkout,
                  icon: Icons.add,
                  label: 'Start Workout',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GymEntryCard(),
          const SizedBox(height: 16),
          FutureBuilder<HomeData>(
            future: _data,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final sessions = snap.data?.sessions ?? const <WorkoutSession>[];
              final catalog = snap.data?.catalog ?? const <int, Exercise>{};
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: StatPill(value: '${sessions.length}', label: 'Workouts')),
                      const SizedBox(width: 10),
                      Expanded(child: StatPill(value: '${_thisWeek(sessions)}', label: 'This week')),
                      const SizedBox(width: 10),
                      Expanded(child: StatPill(value: _weekVolume(sessions), label: 'Vol · week')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StrongestLiftCard(sessions: sessions, catalog: catalog),
                  const SizedBox(height: 12),
                  WeeklyConsistencyCard(sessions: sessions),
                  const SizedBox(height: 12),
                  NeglectedMuscleCard(sessions: sessions, catalog: catalog),
                  const SizedBox(height: 12),
                  GlassButton(
                    icon: Icons.insights,
                    label: 'See all insights',
                    expand: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InsightsScreen()),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  int _thisWeek(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return sessions
        .where((s) => s.startTime != null && s.startTime!.isAfter(weekAgo))
        .length;
  }

  String _weekVolume(List<WorkoutSession> sessions) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final total = sessions
        .where((s) => s.startTime != null && s.startTime!.isAfter(weekAgo))
        .fold<int>(0, (sum, s) => sum + (s.totalVolume ?? 0));
    if (total >= 1000) return '${(total / 1000).toStringAsFixed(1)}t';
    return '$total kg';
  }
}
