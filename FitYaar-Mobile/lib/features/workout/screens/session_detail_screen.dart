import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../active_workout_model.dart';
import '../metric_spec.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';
import 'active_workout_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final WorkoutSession session;
  const SessionDetailScreen({super.key, required this.session});

  Future<void> _edit(BuildContext context) async {
    final prefill = session.exercises
        .map((we) => PrefilledExercise(
              Exercise(
                  id: we.exerciseId,
                  name: we.exerciseName ?? 'Exercise',
                  exerciseType: we.exerciseType),
              we.sets
                  .map((s) => PrefilledSet(
                        weight: s.weight,
                        reps: s.reps,
                        durationSeconds: s.durationSeconds,
                        distanceMeters: s.distanceMeters,
                        type: s.type,
                        completed: s.isCompleted,
                      ))
                  .toList(),
            ))
        .toList();

    context.read<ActiveWorkoutModel>().start(
          title: session.name ?? 'Workout',
          editingSessionId: session.id,
          prefill: prefill,
        );
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
    if (updated == true && context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete(BuildContext context) async {
    final service = context.read<WorkoutService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This permanently removes the session.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.deleteSession(session.id);
      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Workout deleted')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(session.name ?? 'Workout'),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _edit(context)),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _delete(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session.startTime != null)
            Text(
              DateFormat('EEEE, d MMM yyyy · h:mm a').format(session.startTime!),
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, 'Duration',
                  formatSessionDuration(session.startTime, session.endTime)),
              _stat(context, 'Sets', '${session.setCount}'),
              _stat(context, 'Volume', '${session.totalVolume ?? 0} kg'),
            ],
          ),
          const SizedBox(height: 16),
          for (final ex in session.exercises)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.exerciseName ?? 'Exercise',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < ex.sets.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 40,
                                child: Text(_setLabel(ex.sets, i),
                                    style: const TextStyle(color: Colors.grey))),
                            Expanded(
                              child: Text(
                                formatSetByValues(
                                  weight: ex.sets[i].weight,
                                  reps: ex.sets[i].reps,
                                  durationSeconds: ex.sets[i].durationSeconds,
                                  distanceMeters: ex.sets[i].distanceMeters,
                                ),
                              ),
                            ),
                            if (ex.sets[i].isCompleted)
                              const Icon(Icons.check_circle,
                                  size: 18, color: Colors.green),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Numbers only the normal sets; warm-up/drop/failure show W/D/F.
  String _setLabel(List<SetEntryModel> sets, int index) {
    final type = sets[index].type;
    if (type != WorkoutSetType.normal) return setTypeBadge(type);
    var n = 0;
    for (var i = 0; i <= index; i++) {
      if (sets[i].type == WorkoutSetType.normal) n++;
    }
    return '$n';
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

}

String formatSessionDuration(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  final d = end.difference(start);
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}
