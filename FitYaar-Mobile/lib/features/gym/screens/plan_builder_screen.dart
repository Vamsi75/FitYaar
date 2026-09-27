import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../../workout/screens/exercise_picker_screen.dart';
import '../gym_models.dart';
import '../gym_service.dart';

/// Trainer builds a structured plan for one client: pick exercises, set the
/// sets×reps for each, then assign. The client sees it as a read-only checklist.
class PlanBuilderScreen extends StatefulWidget {
  final int gymId;
  final int clientId;
  final String clientName;
  const PlanBuilderScreen({
    super.key,
    required this.gymId,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _Row {
  final String name;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController note;
  _Row(this.name)
      : sets = TextEditingController(),
        reps = TextEditingController(),
        note = TextEditingController();
  void dispose() {
    sets.dispose();
    reps.dispose();
    note.dispose();
  }
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<_Row> _rows = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercises() async {
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      final existing = _rows.map((r) => r.name.toLowerCase()).toSet();
      for (final ex in picked) {
        if (existing.contains(ex.name.toLowerCase())) continue;
        _rows.add(_Row(ex.name));
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Give the plan a title.')));
      return;
    }
    if (_rows.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Add at least one exercise.')));
      return;
    }
    final items = _rows
        .map((r) => PlanItem(
              exerciseName: r.name,
              sets: int.tryParse(r.sets.text.trim()),
              reps: int.tryParse(r.reps.text.trim()),
              note: r.note.text.trim().isEmpty ? null : r.note.text.trim(),
            ))
        .toList();
    setState(() => _saving = true);
    try {
      await context.read<GymService>().assignPlan(
            widget.gymId,
            widget.clientId,
            title,
            note: _noteCtrl.text.trim(),
            items: items,
          );
      messenger.showSnackBar(SnackBar(content: Text('Plan assigned to ${widget.clientName} 📋')));
      navigator.pop(true);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not assign plan.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Plan · ${widget.clientName}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _saving
              ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              : GlassButton(
                  icon: Icons.check,
                  label: 'Assign plan',
                  expand: true,
                  onPressed: _save,
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Plan title (e.g. Push Day)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Overall note (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('Exercises', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _addExercises,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 4),
          if (_rows.isEmpty)
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No exercises yet — tap Add to pick from the library.',
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            for (int i = 0; i < _rows.length; i++) _rowCard(theme, i),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _rowCard(ThemeData theme, int i) {
    final r = _rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(r.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                onPressed: () => setState(() => _rows.removeAt(i).dispose()),
              ),
            ]),
            Row(children: [
              Expanded(child: _numField(r.sets, 'Sets')),
              const SizedBox(width: 10),
              Expanded(child: _numField(r.reps, 'Reps')),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: r.note,
              decoration: const InputDecoration(
                  labelText: 'Note (e.g. slow tempo)', isDense: true, border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
    );
  }
}
