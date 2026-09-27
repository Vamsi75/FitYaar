import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../gym_models.dart';
import '../gym_service.dart';
import '../widgets/glow_avatar.dart';
import '../widgets/gym_live_pager.dart';
import 'gym_leaderboard_screen.dart';
import 'members_screen.dart';

/// Trainer / owner dashboard: manage people, post gym updates, run classes.
/// Members get the separate arena-style [GymScreen]; this is the back-of-house.
class TrainerGymScreen extends StatefulWidget {
  final int gymId;
  const TrainerGymScreen({super.key, required this.gymId});

  @override
  State<TrainerGymScreen> createState() => _TrainerGymScreenState();
}

class _TrainerGymScreenState extends State<TrainerGymScreen> {
  GymSummary? _g;
  List<GymMember> _requests = [];
  List<GymMember> _members = [];
  List<GymEventItem> _events = [];
  List<GymClass> _classes = [];
  // Live status (shown inline in this screen so staff don't switch screens).
  List<GymActivityItem> _activity = [];
  List<GymActivityItem> _zones = [];
  List<HourlyBucket> _trends = [];
  List<ActiveMember> _active = [];
  List<GymTrainer> _trainers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isAdmin => _g?.admin ?? false;

  Future<void> _load() async {
    final svc = context.read<GymService>();
    try {
      final gyms = await svc.myGyms();
      final match = gyms.where((x) => x.gymId == widget.gymId).toList();
      final summary = match.isNotEmpty ? match.first : (gyms.isNotEmpty ? gyms.first : null);
      List<GymMember> requests = [];
      List<GymMember> members = [];
      List<GymEventItem> events = [];
      List<GymClass> classes = [];
      List<GymActivityItem> activity = [];
      List<GymActivityItem> zones = [];
      List<HourlyBucket> trends = [];
      List<ActiveMember> active = [];
      List<GymTrainer> trainers = [];
      if (summary != null && summary.isActive) {
        requests = await svc.requests(summary.gymId);
        members = await svc.members(summary.gymId);
        events = await svc.events(summary.gymId);
        classes = await svc.classes(summary.gymId);
        activity = await svc.activity(summary.gymId);
        zones = await svc.zones(summary.gymId);
        trends = await svc.trends(summary.gymId);
        active = await svc.activeMembers(summary.gymId);
        trainers = await svc.trainers(summary.gymId);
      }
      if (!mounted) return;
      setState(() {
        _g = summary;
        _requests = requests;
        _members = members;
        _events = events;
        _classes = classes;
        _activity = activity;
        _zones = zones;
        _trends = trends;
        _active = active;
        _trainers = trainers;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = _g;
    return Scaffold(
      appBar: AppBar(title: Text(g?.name ?? 'Manage gym')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : g == null
              ? const Center(child: Text('Gym not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerCard(theme, g),
                      const SizedBox(height: 16),
                      _sectionTitle(theme, 'Live status', null),
                      const SizedBox(height: 8),
                      GymLivePager(
                        gym: g,
                        activity: _activity,
                        zones: _zones,
                        trends: _trends,
                        active: _active,
                      ),
                      const SizedBox(height: 12),
                      _trainersLiveCard(theme),
                      const SizedBox(height: 16),
                      _sectionTitle(theme, 'Actions', null),
                      const SizedBox(height: 8),
                      _actions(theme, g),
                      const SizedBox(height: 16),
                      if (_requests.isNotEmpty) ...[
                        _sectionTitle(theme, 'Join requests', '${_requests.length}'),
                        const SizedBox(height: 8),
                        for (final m in _requests) _requestTile(m),
                        const SizedBox(height: 16),
                      ],
                      _updatesCard(theme),
                      const SizedBox(height: 16),
                      _classesCard(theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _headerCard(ThemeData theme, GymSummary g) {
    return GlassCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.stadium, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isAdmin ? 'Owner dashboard' : 'Trainer dashboard',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text('${g.liveCount} training now · ${_members.length} members',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }

  /// Which trainers/owners are checked in right now, vs the full roster.
  Widget _trainersLiveCard(ThemeData theme) {
    final here = _trainers.where((t) => t.activeNow).length;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.sports_gymnastics, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Trainers', style: theme.textTheme.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: here > 0
                      ? Colors.greenAccent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$here of ${_trainers.length} here now',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: here > 0 ? Colors.greenAccent : Colors.white70)),
            ),
          ]),
          const SizedBox(height: 10),
          if (_trainers.isEmpty)
            const Text('No trainers yet.', style: TextStyle(color: Colors.white60))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in _trainers) _trainerChip(t)]),
        ],
      ),
    );
  }

  Widget _trainerChip(GymTrainer t) {
    final active = t.activeNow;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
          color: active
              ? Colors.greenAccent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: active
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Stack(children: [
          GlowAvatar(name: t.displayName, size: 28),
          if (active)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1b1518), width: 1.5)),
              ),
            ),
        ]),
        const SizedBox(width: 8),
        Text(t.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        if (t.isOwner) ...[
          const SizedBox(width: 6),
          const Icon(Icons.star, size: 12, color: Colors.amber),
        ],
        if (active) ...[
          const SizedBox(width: 6),
          const Text('Now',
              style: TextStyle(
                  fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, String? count, {Widget? action}) {
    return Row(children: [
      Text(title, style: theme.textTheme.titleMedium),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Text(count, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
      ],
      const Spacer(),
      if (action != null) action,
    ]);
  }

  /// Primary gym-management actions, surfaced in the panel body (not the app bar).
  Widget _actions(ThemeData theme, GymSummary g) {
    final pending = _requests.length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        GlassButton(
            dense: true,
            icon: Icons.group_outlined,
            label: pending > 0 ? 'Manage people ($pending)' : 'Manage people',
            onPressed: _openPeople),
        GlassButton(
            dense: true,
            icon: Icons.person_add_alt,
            label: 'Add member',
            onPressed: _addMember),
        GlassButton(
            dense: true,
            icon: Icons.campaign_outlined,
            label: 'Post update',
            onPressed: () => _editUpdate(null)),
        GlassButton(
            dense: true,
            icon: Icons.event_available_outlined,
            label: 'Add class',
            onPressed: _addClass),
        GlassButton(
            dense: true,
            icon: Icons.leaderboard_outlined,
            label: 'Leaderboard',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GymLeaderboardScreen(gymId: g.gymId, gymName: g.name)))),
      ],
    );
  }

  Future<void> _openPeople() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GymMembersScreen(
          gymId: widget.gymId, viewerIsAdmin: _isAdmin, gymName: _g?.name ?? 'Members'),
    ));
    _load();
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
              Text(m.displayName ?? m.email, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(m.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _act(() => context.read<GymService>().approve(m.membershipId), 'Approved')),
        IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => _act(() => context.read<GymService>().reject(m.membershipId), 'Rejected')),
      ]),
    ),
    );
  }

  Widget _updatesCard(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.campaign_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Gym updates', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _editUpdate(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Post'),
            ),
          ]),
          const SizedBox(height: 4),
          if (_events.isEmpty)
            const _EmptyLine('No announcements yet.')
          else
            for (final e in _events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.event_note, size: 16, color: Colors.white38),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (e.body != null && e.body!.isNotEmpty)
                            Text(e.body!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.white38),
                      onSelected: (v) {
                        if (v == 'edit') _editUpdate(e);
                        if (v == 'delete') {
                          _act(() => context.read<GymService>().deleteEvent(e.id), 'Update deleted');
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _classesCard(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Classes', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _addClass,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 4),
          if (_classes.isEmpty)
            const _EmptyLine('No classes scheduled.')
          else
            for (final c in _classes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (c.schedule != null && c.schedule!.isNotEmpty)
                            Text(c.schedule!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                      onPressed: () => _act(() => context.read<GymService>().deleteClass(c.id), 'Class removed'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ---- actions ----

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

  Future<void> _addMember() async {
    final ctrl = TextEditingController();
    var role = 'MEMBER';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'User email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                  // Only an owner can add a trainer (backend enforces via assignableRole).
                  if (_isAdmin) const DropdownMenuItem(value: 'TRAINER', child: Text('Trainer')),
                ],
                onChanged: (v) => setLocal(() => role = v ?? 'MEMBER'),
              ),
              const SizedBox(height: 8),
              const Text('They must already have a FitYaar account.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    await _act(
        () => context.read<GymService>().addMember(widget.gymId, ctrl.text.trim(), role: role).then((_) {}),
        'Member added');
  }

  Future<void> _editUpdate(GymEventItem? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Post gym update' : 'Edit update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Details (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? 'Post' : 'Save')),
        ],
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    if (!mounted) return;
    final svc = context.read<GymService>();
    if (existing == null) {
      await _act(() => svc.createEvent(widget.gymId, titleCtrl.text.trim(), bodyCtrl.text.trim()),
          'Update posted');
    } else {
      await _act(() => svc.updateEvent(existing.id, titleCtrl.text.trim(), bodyCtrl.text.trim()),
          'Update saved');
    }
  }

  Future<void> _addClass() async {
    final titleCtrl = TextEditingController();
    final schedCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Class name (e.g. HIIT)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schedCtrl,
              decoration: const InputDecoration(
                  labelText: 'When (e.g. Mon & Wed 7 PM)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Details (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    await _act(
        () => context
            .read<GymService>()
            .addClass(widget.gymId, titleCtrl.text.trim(), schedCtrl.text.trim(), descCtrl.text.trim()),
        'Class added');
  }

}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(color: Colors.white54)),
      );
}
