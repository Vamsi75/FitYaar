import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../gym_models.dart';
import '../gym_service.dart';
import '../widgets/glow_avatar.dart';
import 'plan_builder_screen.dart';

/// A member's full gym record for trainers/owners: contact, membership expiry,
/// personal-training status. Editing sends an email to the owner + the member.
class MemberDetailScreen extends StatefulWidget {
  final int gymId;
  final int membershipId;
  final bool viewerIsAdmin;
  const MemberDetailScreen({
    super.key,
    required this.gymId,
    required this.membershipId,
    required this.viewerIsAdmin,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  MemberDetail? _m;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await context.read<GymService>().memberDetail(widget.membershipId);
      if (mounted) setState(() { _m = m; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guard(Future<MemberDetail> Function() action, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final m = await action();
      _changed = true;
      if (!mounted) return;
      setState(() => _m = m);
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Action failed')));
    }
  }

  /// Mirrors the backend rank rule (AuthorizationService.requireCanManage):
  /// owners manage non-owners; trainers manage members only.
  bool _canManage(MemberDetail m) =>
      widget.viewerIsAdmin ? m.role != 'OWNER' : m.role == 'MEMBER';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = _m;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(m?.displayName ?? 'Member')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : m == null
                ? const Center(child: Text('Member not found'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileCard(theme, m),
                      const SizedBox(height: 14),
                      _recordCard(theme, m),
                      const SizedBox(height: 14),
                      _ptCard(theme, m),
                      if (_canManage(m)) ...[
                        const SizedBox(height: 20),
                        GlassButton(
                          icon: Icons.assignment_ind_outlined,
                          label: 'Assign a workout plan',
                          expand: true,
                          onPressed: () => _assignPlan(m),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () => _remove(m),
                          icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                          label: const Text('Remove from gym',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _profileCard(ThemeData theme, MemberDetail m) {
    return GlassCard(
      child: Row(children: [
        GlowAvatar(name: m.displayName, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(m.email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                _pill(theme, m.role == 'OWNER'
                    ? 'Owner'
                    : m.role == 'TRAINER'
                        ? 'Trainer'
                        : 'Member'),
                if (m.isClient) _pill(theme, 'PT client'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _recordCard(ThemeData theme, MemberDetail m) {
    final svc = context.read<GymService>();
    final (statusValue, statusWarn) = _membershipStatus(m);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.badge_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Membership record', style: theme.textTheme.titleMedium),
            const Spacer(),
            if (_canManage(m))
              TextButton.icon(
                onPressed: () => _edit(m),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
          ]),
          const SizedBox(height: 4),
          _kv('Joined', m.joinedAt == null ? '—' : _fmtDate(m.joinedAt!)),
          _kv('Role',
              m.role == 'OWNER' ? 'Owner' : m.role == 'TRAINER' ? 'Trainer' : 'Member'),
          _kv('Personal trainer', m.isClient ? (m.trainerName ?? '—') : 'None'),
          _kv('Phone', m.phone == null || m.phone!.isEmpty ? '—' : m.phone!),
          _kv('Membership', statusValue, warn: statusWarn),
          if (widget.viewerIsAdmin) ...[
            const Divider(height: 20),
            Row(children: [
              const Expanded(child: Text('Trainer access', style: TextStyle(color: Colors.white70))),
              Switch(
                value: m.role == 'TRAINER' || m.role == 'OWNER',
                onChanged: m.role == 'OWNER'
                    ? null // don't demote an owner from here
                    : (v) => _guard(
                          () async {
                            await svc.changeRole(m.membershipId, v ? 'TRAINER' : 'MEMBER');
                            return svc.memberDetail(m.membershipId);
                          },
                          v ? 'Promoted to trainer' : 'Set back to member',
                        ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _ptCard(ThemeData theme, MemberDetail m) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.fitness_center, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Personal training', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 6),
          if (m.isClient)
            Text('Taking PT with ${m.trainerName}',
                style: const TextStyle(color: Colors.white70))
          else
            const Text('No personal trainer.', style: TextStyle(color: Colors.white54)),
          if (m.ptNotes != null && m.ptNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(m.ptNotes!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (_canManage(m)) ...[
            const SizedBox(height: 10),
            m.isClient
                ? OutlinedButton.icon(
                    onPressed: () => _guard(
                        () => context.read<GymService>().unsetClient(m.membershipId),
                        'Removed as PT client'),
                    icon: const Icon(Icons.link_off, size: 18),
                    label: const Text('Remove PT'))
                : GlassButton(
                    dense: true,
                    icon: Icons.person_add_alt,
                    label: 'Take on as my client',
                    onPressed: () => _guard(
                        () => context.read<GymService>().setClient(m.membershipId),
                        'Added as your PT client'),
                  ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(MemberDetail m) async {
    final phoneCtrl = TextEditingController(text: m.phone ?? '');
    final notesCtrl = TextEditingController(text: m.ptNotes ?? '');
    DateTime? expiry = m.expiresAt;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit member record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Membership expires', border: OutlineInputBorder()),
                  child: Row(children: [
                    Expanded(child: Text(expiry == null ? 'Not set' : _fmtDate(expiry!))),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: expiry ?? now.add(const Duration(days: 30)),
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (d != null) setLocal(() => expiry = d);
                      },
                      child: const Text('Pick'),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Training notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save & notify')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _guard(
      () => context.read<GymService>().updateMember(
            m.membershipId,
            phone: phoneCtrl.text.trim(),
            expiresAt: expiry,
            ptNotes: notesCtrl.text.trim(),
          ),
      'Saved — owner & member notified',
    );
  }

  Future<void> _assignPlan(MemberDetail m) async {
    final res = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PlanBuilderScreen(
          gymId: widget.gymId, clientId: m.userId, clientName: m.displayName),
    ));
    if (res == true) _changed = true;
  }

  Future<void> _remove(MemberDetail m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${m.displayName}?'),
        content: const Text('They will lose access to this gym.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<GymService>().remove(m.membershipId);
      messenger.showSnackBar(const SnackBar(content: Text('Removed from gym')));
      navigator.pop(true);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not remove')));
    }
  }

  Widget _kv(String k, String v, {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 150, child: Text(k, style: const TextStyle(color: Colors.white54))),
        Expanded(
          child: Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: warn ? Colors.redAccent : Colors.white)),
        ),
      ]),
    );
  }

  Widget _pill(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Human membership status + whether it should read as a warning (red).
  (String, bool) _membershipStatus(MemberDetail m) {
    final e = m.expiresAt;
    if (e == null) return ('Active · no end date', false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = e.difference(today).inDays;
    if (days < 0) return ('Expired ${_fmtDate(e)}', true);
    if (days <= 14) {
      return ('Expires ${_fmtDate(e)} · in $days ${days == 1 ? 'day' : 'days'}', true);
    }
    return ('Active · expires ${_fmtDate(e)}', false);
  }
}
