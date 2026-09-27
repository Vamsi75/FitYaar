import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_card.dart';
import '../social_models.dart';
import '../social_service.dart';
import 'public_profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<SocialUser>? _results; // null = not searching
  List<SocialUser> _requests = [];
  List<FeedItem> _feed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHome() async {
    setState(() => _loading = true);
    try {
      final s = context.read<SocialService>();
      final reqs = await s.requests();
      final feed = await s.feed();
      if (!mounted) return;
      setState(() {
        _requests = reqs;
        _feed = feed;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await context.read<SocialService>().search(q.trim());
        if (mounted) setState(() => _results = r);
      } catch (_) {}
    });
  }

  Future<void> _toggleFollow(SocialUser u) async {
    try {
      final s = context.read<SocialService>();
      if (u.followStatus == 'NONE') {
        await s.follow(u.userId);
      } else {
        await s.unfollow(u.userId);
      }
      if (_results != null) {
        _onSearch(_searchCtrl.text); // refresh search
      }
      _loadHome();
    } catch (_) {}
  }

  void _openUser(int userId) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Find people',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(child: _results != null ? _searchResults() : _home()),
        ],
      ),
    );
  }

  Widget _searchResults() {
    if (_results!.isEmpty) {
      return const Center(child: Text('No one found', style: TextStyle(color: Colors.white54)));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [for (final u in _results!) _userTile(u)],
    );
  }

  Widget _home() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadHome,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_requests.isNotEmpty) ...[
            Text('Follow requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final u in _requests) _requestTile(u),
            const SizedBox(height: 16),
          ],
          Text('Feed', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_feed.isEmpty)
            const GlassCard(
              child: Text('Follow people to see their workouts here.',
                  style: TextStyle(color: Colors.white70)),
            )
          else
            for (final f in _feed) _feedTile(f),
        ],
      ),
    );
  }

  Widget _userTile(SocialUser u) {
    return Card(
      child: ListTile(
        leading: _avatar(u.profilePictureUrl, u.displayName),
        title: Text(u.displayName),
        subtitle: u.isPublic ? null : const Text('Private'),
        trailing: u.isSelf
            ? const Text('You', style: TextStyle(color: Colors.white54))
            : OutlinedButton(
                onPressed: () => _toggleFollow(u),
                child: Text(switch (u.followStatus) {
                  'FOLLOWING' => 'Following',
                  'PENDING' => 'Requested',
                  _ => 'Follow',
                }),
              ),
        onTap: () => _openUser(u.userId),
      ),
    );
  }

  Widget _requestTile(SocialUser u) {
    return Card(
      child: ListTile(
        leading: _avatar(u.profilePictureUrl, u.displayName),
        title: Text(u.displayName),
        subtitle: const Text('wants to follow you'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () async {
                  await context.read<SocialService>().approve(u.userId);
                  _loadHome();
                }),
            IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                onPressed: () async {
                  await context.read<SocialService>().reject(u.userId);
                  _loadHome();
                }),
          ],
        ),
        onTap: () => _openUser(u.userId),
      ),
    );
  }

  Widget _feedTile(FeedItem f) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => _openUser(f.authorId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(null, f.authorName, radius: 16),
                const SizedBox(width: 8),
                Text(f.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (f.startTime != null)
                  Text(DateFormat('d MMM').format(f.startTime!),
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(f.name ?? 'Workout',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${f.exercisesCount} exercises · ${f.sets} sets · ${f.volume} kg',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? url, String name, {double radius = 20}) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(radius: radius, child: Text(initial));
  }
}
