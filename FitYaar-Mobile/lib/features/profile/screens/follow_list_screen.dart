import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../social/social_models.dart';
import '../../social/social_service.dart';
import '../../social/screens/public_profile_screen.dart';

/// Real followers / following list for a user.
class FollowListScreen extends StatefulWidget {
  final int userId;
  final bool showFollowers;
  const FollowListScreen({super.key, required this.userId, required this.showFollowers});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late Future<List<SocialUser>> _future;

  @override
  void initState() {
    super.initState();
    final s = context.read<SocialService>();
    _future = widget.showFollowers ? s.followers(widget.userId) : s.following(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.showFollowers ? 'Followers' : 'Following')),
      body: FutureBuilder<List<SocialUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text(widget.showFollowers ? 'No followers yet' : 'Not following anyone yet',
                  style: const TextStyle(color: Colors.white54)),
            );
          }
          return ListView(
            children: [
              for (final u in users)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(u.displayName.isEmpty
                            ? '?'
                            : u.displayName[0].toUpperCase())),
                    title: Text(u.displayName),
                    subtitle: u.isPublic ? null : const Text('Private'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: u.userId))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
