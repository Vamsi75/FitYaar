import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_card.dart';
import '../social_models.dart';
import '../social_service.dart';

class CompareScreen extends StatefulWidget {
  final int userId;
  const CompareScreen({super.key, required this.userId});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late final Future<CompareStats> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SocialService>().compare(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: FutureBuilder<CompareStats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Could not load comparison'));
          }
          final c = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Row(
                  children: [
                    Expanded(child: Text(c.meName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    const Text('vs', style: TextStyle(color: Colors.white54)),
                    Expanded(child: Text(c.themName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _row(context, 'Workouts', c.me.workouts, c.them.workouts),
              _row(context, 'Sets', c.me.sets, c.them.sets),
              _row(context, 'Volume (kg)', c.me.volume, c.them.volume),
              _row(context, 'Hours', (c.me.minutes / 60).round(), (c.them.minutes / 60).round()),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, int me, int them) {
    final primary = Theme.of(context).colorScheme.primary;
    final meWins = me > them;
    final themWins = them > me;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('$me',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: meWins ? primary : Colors.white)),
                ),
                Expanded(
                  child: Text('$them',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themWins ? primary : Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
