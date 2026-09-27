import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../active_workout_model.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';
import 'active_workout_screen.dart';
import 'session_detail_screen.dart';

/// A history entry with a ⋮ menu: Share, Copy workout, Edit, Delete.
class SessionTile extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onChanged;
  const SessionTile({super.key, required this.session, required this.onChanged});

  List<PrefilledExercise> _prefill({required bool keepCompleted}) {
    return session.exercises
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
                        completed: keepCompleted && s.isCompleted,
                      ))
                  .toList(),
            ))
        .toList();
  }

  Future<void> _open(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
    );
    if (changed == true) onChanged();
  }

  Future<void> _edit(BuildContext context) async {
    context.read<ActiveWorkoutModel>().start(
          title: session.name ?? 'Workout',
          editingSessionId: session.id,
          prefill: _prefill(keepCompleted: true),
        );
    final r = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
    if (r == true) onChanged();
  }

  Future<void> _copy(BuildContext context) async {
    context.read<ActiveWorkoutModel>().start(
          title: session.name ?? 'Workout',
          prefill: _prefill(keepCompleted: false),
        );
    final r = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
    if (r == true) onChanged();
  }

  Future<void> _share(BuildContext context) async {
    final b = StringBuffer()
      ..writeln(session.name ?? 'Workout')
      ..writeln(
          '${session.exercises.length} exercises · ${session.setCount} sets · ${session.totalVolume ?? 0} kg');
    for (final e in session.exercises) {
      b.writeln('• ${e.exerciseName ?? 'Exercise'} — ${e.sets.length} sets');
    }
    b.write('— via FitYaar');
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout copied to clipboard')),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This permanently removes the session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    try {
      await context.read<WorkoutService>().deleteSession(session.id);
      onChanged();
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
    final date = session.startTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.name ?? 'Workout',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (date != null)
                        Text(DateFormat('EEE, d MMM · h:mm a').format(date),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    switch (v) {
                      case 'share':
                        _share(context);
                      case 'copy':
                        _copy(context);
                      case 'edit':
                        _edit(context);
                      case 'delete':
                        _delete(context);
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                            leading: Icon(Icons.ios_share), title: Text('Share'))),
                    PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                            leading: Icon(Icons.copy_all),
                            title: Text('Copy workout'))),
                    PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'))),
                    PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            title: Text('Delete',
                                style: TextStyle(color: Colors.redAccent)))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(context, Icons.timer_outlined,
                    formatSessionDuration(session.startTime, session.endTime)),
                const SizedBox(width: 8),
                _chip(context, Icons.repeat, '${session.setCount} sets'),
                const SizedBox(width: 8),
                _chip(context, Icons.fitness_center,
                    '${session.totalVolume ?? 0} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
