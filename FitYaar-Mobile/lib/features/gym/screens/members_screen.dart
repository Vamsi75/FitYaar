import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../gym_models.dart';
import '../gym_service.dart';
import '../widgets/glow_avatar.dart';
import 'member_detail_screen.dart';

/// People management for trainers/owners: pending join requests to approve or
/// reject, plus a searchable roster. Tap a member to open their full record.
class GymMembersScreen extends StatefulWidget {
  final int gymId;
  final bool viewerIsAdmin;
  final String gymName;
  const GymMembersScreen({
    super.key,
    required this.gymId,
    required this.viewerIsAdmin,
    required this.gymName,
  });

  @override
  State<GymMembersScreen> createState() => _GymMembersScreenState();
}

class _GymMembersScreenState extends State<GymMembersScreen> {
  List<GymMember> _requests = [];
  List<GymMember> _members = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<GymService>();
    try {
      final requests = await svc.requests(widget.gymId);
      final members = await svc.members(widget.gymId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _members = members;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<GymMember> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _members;
    return _members
        .where((m) =>
            (m.displayName ?? '').toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_requests.isNotEmpty) ...[
                    _sectionTitle(theme, 'Join requests', '${_requests.length}'),
                    const SizedBox(height: 8),
                    for (final m in _requests) _requestTile(m),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(theme, 'Members', '${_members.length}'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search members',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                          _members.isEmpty ? 'No members yet.' : 'No matches.',
                          style: const TextStyle(color: Colors.white54)),
                    )
                  else
                    for (final m in members) _memberTile(theme, m),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, String count) {
    return Row(children: [
      Text(title, style: theme.textTheme.titleMedium),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Text(count, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ),
    ]);
  }

  Widget _requestTile(GymMember m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          const Icon(Icons.hourglass_top, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.displayName ?? m.email,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(m.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () =>
                  _act(() => context.read<GymService>().approve(m.membershipId), 'Approved')),
          IconButton(
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () =>
                  _act(() => context.read<GymService>().reject(m.membershipId), 'Rejected')),
        ]),
      ),
    );
  }

  Widget _memberTile(ThemeData theme, GymMember m) {
    final isStaff = m.role == 'TRAINER' || m.role == 'OWNER';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => _openMember(m),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          GlowAvatar(name: m.displayName ?? m.email, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.displayName ?? m.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                    m.joinedAt != null ? 'Joined ${_monthYear(m.joinedAt!)}' : m.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (isStaff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(m.role == 'OWNER' ? 'Owner' : 'Trainer',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ]),
      ),
    );
  }

  Future<void> _act(Future<void> Function() action, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Action failed')));
    }
  }

  Future<void> _openMember(GymMember m) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => MemberDetailScreen(
          gymId: widget.gymId,
          membershipId: m.membershipId,
          viewerIsAdmin: widget.viewerIsAdmin),
    ));
    if (changed == true) _load();
  }

  String _monthYear(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }
}
