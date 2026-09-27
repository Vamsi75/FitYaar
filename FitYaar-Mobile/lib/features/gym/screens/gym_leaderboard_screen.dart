import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_card.dart';
import '../gym_models.dart';
import '../gym_service.dart';

/// Weekly gym leaderboard (last 7 days) — workouts + volume across members.
class GymLeaderboardScreen extends StatefulWidget {
  final int gymId;
  final String gymName;
  const GymLeaderboardScreen({super.key, required this.gymId, required this.gymName});

  @override
  State<GymLeaderboardScreen> createState() => _GymLeaderboardScreenState();
}

class _GymLeaderboardScreenState extends State<GymLeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<GymService>().leaderboard(widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${widget.gymName} · this week',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data ?? const <LeaderboardEntry>[];
          final ranked = rows.where((r) => r.workouts > 0).toList();
          if (ranked.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No workouts logged at this gym this week.\nBe the first! 🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ranked.length,
            itemBuilder: (context, i) => _row(theme, i, ranked[i]),
          );
        },
      ),
    );
  }

  Widget _row(ThemeData theme, int i, LeaderboardEntry e) {
    final rank = i + 1;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
    final vol = e.volume >= 1000
        ? '${(e.volume / 1000).toStringAsFixed(1)}t'
        : '${e.volume} kg';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        tint: rank <= 3 ? theme.colorScheme.primary : null,
        child: Row(
          children: [
            SizedBox(
                width: 34,
                child: Text(medal,
                    style: TextStyle(
                        fontSize: rank <= 3 ? 20 : 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(e.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${e.workouts} ${e.workouts == 1 ? 'workout' : 'workouts'}',
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                Text(vol, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
