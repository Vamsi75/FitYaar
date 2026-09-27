import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout_models.dart';
import '../workout_service.dart';
import 'personal_records_screen.dart';
import 'session_detail_screen.dart';

/// The "History" tab: past workout sessions, newest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<WorkoutSession>> _history;

  @override
  void initState() {
    super.initState();
    _history = context.read<WorkoutService>().getHistory();
  }

  void _reload() {
    setState(() {
      _history = context.read<WorkoutService>().getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Personal Records',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<WorkoutSession>>(
          future: _history,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _scrollable(const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Could not load history'),
                ),
              ));
            }
            final sessions = snap.data ?? [];
            sessions.sort((a, b) => (b.startTime ?? DateTime(0))
                .compareTo(a.startTime ?? DateTime(0)));
            if (sessions.isEmpty) {
              return _scrollable(const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No workouts yet.\nLog your first one from the Log tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              itemBuilder: (context, i) =>
                  _SessionCard(session: sessions[i], onChanged: _reload),
            );
          },
        ),
      ),
    );
  }

  Widget _scrollable(Widget child) => ListView(
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.7, child: child),
        ],
      );
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onChanged;
  const _SessionCard({required this.session, required this.onChanged});

  Future<void> _open(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
    );
    if (changed == true) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.startTime;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.name ?? 'Workout',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              if (date != null)
                Text(DateFormat('EEE, d MMM · h:mm a').format(date),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 10),
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
              if (session.exercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final ex in session.exercises.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '• ${ex.exerciseName ?? 'Exercise'} — ${ex.sets.length} ${ex.sets.length == 1 ? 'set' : 'sets'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                if (session.exercises.length > 4)
                  Text('+${session.exercises.length - 4} more',
                      style: TextStyle(
                          color: theme.colorScheme.primary, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
