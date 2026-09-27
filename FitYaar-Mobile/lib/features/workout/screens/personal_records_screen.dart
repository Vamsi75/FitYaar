import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_models.dart';
import '../workout_service.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  late Future<List<PersonalRecord>> _prs;

  @override
  void initState() {
    super.initState();
    _prs = context.read<WorkoutService>().getPersonalRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Records')),
      body: FutureBuilder<List<PersonalRecord>>(
        future: _prs,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Could not load records'));
          }
          final prs = snap.data ?? [];
          if (prs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No personal records yet.\nComplete sets to start setting PRs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: prs.length,
            itemBuilder: (context, i) {
              final pr = prs[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                  title: Text(pr.exerciseName ?? 'Exercise'),
                  subtitle: Text(
                      '${_fmt(pr.weight)} kg × ${pr.reps ?? 0} reps'),
                  trailing: pr.oneRepMaxEstimate == null
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${pr.oneRepMaxEstimate!.round()} kg',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('est. 1RM',
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '0';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
}
