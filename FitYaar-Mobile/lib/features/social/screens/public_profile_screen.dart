import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../social_models.dart';
import '../social_service.dart';
import 'compare_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<PublicProfile> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = context.read<SocialService>().profile(widget.userId);
    });
  }

  Future<void> _toggleFollow(PublicProfile p) async {
    setState(() => _busy = true);
    try {
      final s = context.read<SocialService>();
      if (p.followStatus == 'NONE') {
        await s.follow(p.userId);
      } else {
        await s.unfollow(p.userId);
      }
      _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _followLabel(String status) => switch (status) {
        'FOLLOWING' => 'Following',
        'PENDING' => 'Requested',
        _ => 'Follow',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<PublicProfile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Could not load profile'));
          }
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    _avatar(p.profilePictureUrl, p.displayName ?? 'Athlete'),
                    const SizedBox(height: 12),
                    Text(p.displayName ?? 'Athlete',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (p.bio != null && p.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.bio!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _count('${p.workoutsCount}', 'Workouts'),
                        _count('${p.followersCount}', 'Followers'),
                        _count('${p.followingCount}', 'Following'),
                      ],
                    ),
                    if (!p.self) ...[
                      const SizedBox(height: 16),
                      _busy
                          ? const CircularProgressIndicator()
                          : GlassButton(
                              icon: p.followStatus == 'FOLLOWING'
                                  ? Icons.check
                                  : Icons.person_add_alt,
                              label: _followLabel(p.followStatus),
                              onPressed: () => _toggleFollow(p)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (p.self)
                const SizedBox.shrink()
              else if (p.canView)
                GlassButton(
                  icon: Icons.compare_arrows,
                  label: 'Compare with me',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CompareScreen(userId: p.userId))),
                )
              else
                const GlassCard(
                  child: Row(children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('This account is private. Follow to see their workouts.')),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _count(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      );

  Widget _avatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: 40, backgroundImage: NetworkImage(url));
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(radius: 40, child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)));
  }
}
