import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/measurement_models.dart';
import '../profile/measurement_service.dart';
import '../profile/profile_service.dart';
import '../workout/models/workout_models.dart';
import '../workout/workout_service.dart';
import 'widgets/body_insight_card.dart';
import 'widgets/monthly_recap_card.dart';
import 'widgets/muscle_distribution_card.dart';
import 'widgets/muscle_map_card.dart';
import 'widgets/pr_timeline_card.dart';
import 'widgets/strongest_lift_card.dart';
import 'widgets/top_exercises_card.dart';
import 'widgets/weekly_consistency_card.dart';

typedef InsightsData = ({
  List<WorkoutSession> sessions,
  Map<int, Exercise> catalog,
  List<BodyMeasurement> measurements,
  String? gender,
});

/// Full analytics dashboard — the "See all insights" destination.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<InsightsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InsightsData> _load() async {
    final svc = context.read<WorkoutService>();
    final measureSvc = context.read<MeasurementService>();
    final profileSvc = context.read<ProfileService>();
    final history = await svc.getHistory();
    final exercises = await svc.searchExercises('');
    final measurements = await measureSvc.list();
    String? gender;
    try {
      gender = (await profileSvc.getProfile()).gender;
    } catch (_) {
      gender = null; // gender is optional — map just defaults to male
    }
    return (
      sessions: history,
      catalog: {for (final e in exercises) e.id: e},
      measurements: measurements,
      gender: gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: FutureBuilder<InsightsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
                child: Text('Could not load insights',
                    style: TextStyle(color: Colors.white54)));
          }
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = _load();
            }),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StrongestLiftCard(sessions: d.sessions, catalog: d.catalog),
                const SizedBox(height: 16),
                WeeklyConsistencyCard(sessions: d.sessions),
                const SizedBox(height: 16),
                MuscleMapCard(
                    sessions: d.sessions, catalog: d.catalog, gender: d.gender),
                const SizedBox(height: 16),
                MuscleDistributionCard(sessions: d.sessions, catalog: d.catalog),
                const SizedBox(height: 16),
                TopExercisesCard(sessions: d.sessions, catalog: d.catalog),
                const SizedBox(height: 16),
                BodyInsightCard(sessions: d.sessions, measurements: d.measurements),
                const SizedBox(height: 16),
                MonthlyRecapCard(sessions: d.sessions, catalog: d.catalog),
                const SizedBox(height: 16),
                PrTimelineCard(sessions: d.sessions),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
