import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_screen.dart';
import '../social/screens/social_screen.dart';
import '../workout/active_workout_model.dart';
import '../workout/screens/active_workout_screen.dart';
import '../workout/screens/workout_log_screen.dart';
import 'home_screen.dart';

/// Authenticated shell. Workout/History/Social are placeholders for upcoming
/// milestones; Profile is live (shows the signed-in user + logout).
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    WorkoutLogScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWorkoutActive =
        context.select<ActiveWorkoutModel, bool>((m) => m.isActive);
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _tabs[_selectedIndex]),
          if (isWorkoutActive) const _MiniWorkoutBanner(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

/// Persistent bar shown while a workout is in progress but minimized.
class _MiniWorkoutBanner extends StatelessWidget {
  const _MiniWorkoutBanner();

  Future<void> _confirmDiscard(BuildContext context, ActiveWorkoutModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Your unsaved sets will be lost.'),
        actions: [
          GlassButton(
              dense: true,
              label: 'Keep',
              onPressed: () => Navigator.pop(ctx, false)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok == true) model.discard();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ActiveWorkoutModel>();
    final theme = Theme.of(context);
    final d = model.elapsed;
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    void expand() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: GlassCard(
        onTap: expand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.fitness_center, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.isEditing ? 'Editing workout' : 'Workout in progress',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$mm:$ss · ${model.totalSets} sets · tap to expand',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Discard',
              onPressed: () => _confirmDiscard(context, model),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

