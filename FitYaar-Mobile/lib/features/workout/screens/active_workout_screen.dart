import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/accent_button.dart';
import '../../../core/widgets/anim_icon.dart';
import '../../../core/widgets/glass_button.dart';
import '../active_workout_model.dart';
import '../metric_spec.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';
import 'exercise_picker_screen.dart';
import 'workout_summary_screen.dart';

/// Full-screen view over [ActiveWorkoutModel]. The workout state lives in the
/// model so it survives navigation (see the minimized banner in the home shell).
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _saving = false;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) {
      setState(() => _restRemaining = 0);
      return;
    }
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_restRemaining <= 1) {
        t.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  void _bumpRest(int delta) {
    setState(() => _restRemaining = (_restRemaining + delta).clamp(0, 3599));
    if (_restRemaining == 0) _restTimer?.cancel();
  }

  Future<void> _editTimer(ActiveWorkoutModel model) async {
    final e = model.elapsed;
    final mm = TextEditingController(text: e.inMinutes.toString());
    final ss = TextEditingController(text: (e.inSeconds % 60).toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust workout time'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: mm,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Min', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ss,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Sec', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Set')),
        ],
      ),
    );
    if (ok == true) {
      final m = int.tryParse(mm.text.trim()) ?? 0;
      final s = int.tryParse(ss.text.trim()) ?? 0;
      model.setElapsed(Duration(minutes: m, seconds: s));
    }
    mm.dispose();
    ss.dispose();
  }

  Future<void> _addExercises(ActiveWorkoutModel model) async {
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked != null && picked.isNotEmpty) model.addExercises(picked);
  }

  Future<void> _pickRest(ActiveWorkoutModel model, ActiveExercise entry) async {
    const options = [0, 30, 45, 60, 90, 120, 180];
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Rest timer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final o in options)
              ListTile(
                title: Text(o == 0 ? 'Off' : _restLabel(o)),
                trailing: entry.restSeconds == o ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) model.setRest(entry, chosen);
  }

  void _editSetType(ActiveWorkoutModel model, ActiveExercise entry, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typeOption(ctx, model, entry, index, WorkoutSetType.normal, 'Normal set',
                'Your main working sets — these drive strength and muscle.'),
            _typeOption(ctx, model, entry, index, WorkoutSetType.warmup, 'Warm-up set',
                "Lighter prep sets to ready your body to lift heavy. They don't count as working sets."),
            _typeOption(ctx, model, entry, index, WorkoutSetType.failure, 'Failure set',
                'Taken to failure — you could not complete the last rep. e.g. fail on the 11th → log 10 reps.'),
            _typeOption(ctx, model, entry, index, WorkoutSetType.drop, 'Drop set',
                'Right after failure, drop the weight and keep repping with no rest.'),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Remove set', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                model.removeSet(entry, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeOption(BuildContext ctx, ActiveWorkoutModel model, ActiveExercise entry,
      int index, WorkoutSetType type, String title, String info) {
    final selected = entry.sets[index].type == type;
    return ListTile(
      leading: _SetBadge(
          label: setTypeBadge(type).isEmpty ? '1' : setTypeBadge(type), type: type),
      title: Text(title),
      subtitle: Text(info, style: const TextStyle(fontSize: 12)),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        Navigator.pop(ctx);
        model.setType(entry, index, type);
      },
    );
  }

  Future<void> _finish(ActiveWorkoutModel model) async {
    final logged = model.buildLogged();
    if (logged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mark at least one set as done (✓) before finishing.'),
      ));
      return;
    }
    final service = context.read<WorkoutService>();
    final name = await _askName(model.defaultName(), model.isEditing);
    if (name == null) return;

    setState(() => _saving = true);
    final editingId = model.editingSessionId;
    final elapsed = model.elapsed;
    final startedAt = editingId != null
        ? (model.startedAt ?? DateTime.now())
        : DateTime.now().subtract(elapsed);
    final routineId = model.sourceRoutineId;
    final addedCount = model.addedExerciseIds().length;
    final currentIds = model.currentExerciseIds();
    final routineName = model.title;
    try {
      if (editingId != null) {
        await service.updateSession(
            sessionId: editingId, name: name, startTime: startedAt, exercises: logged);
      } else {
        await service.finishSession(
            name: name, startTime: startedAt, exercises: logged);
      }

      // Started from a routine and added exercises? Offer to sync the routine.
      if (routineId != null && addedCount > 0 && mounted) {
        final update = await _askUpdateRoutine(addedCount);
        if (update == true) {
          try {
            await service.updateRoutine(
                routineId: routineId, name: routineName, exerciseIds: currentIds);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Workout saved; routine could not be updated.'),
              ));
            }
          }
        }
      }

      model.finishAndClear();
      if (!mounted) return;
      if (editingId != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout updated ✅')));
      } else {
        // Replace the active screen with the celebration/recap.
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
              name: name, duration: elapsed, exercises: logged),
        ));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save workout.')));
    }
  }

  Future<String?> _askName(String defaultName, bool editing) async {
    final controller = TextEditingController(text: defaultName);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Name your workout'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(ctx, t.isEmpty ? defaultName : t);
              },
              child: Text(editing ? 'Update' : 'Save'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool?> _askUpdateRoutine(int count) {
    final noun = count == 1 ? 'exercise' : 'exercises';
    final it = count == 1 ? 'it' : 'them';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update routine?'),
        content: Text(
            'You added $count new $noun that aren\'t in this routine. '
            'Update the routine to include $it? Your workout is already saved either way.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep original')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update routine')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ActiveWorkoutModel>();
    if (!model.isActive) return const Scaffold(body: SizedBox.shrink());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.isEditing ? 'Edit Workout' : model.title,
                style: const TextStyle(fontSize: 16)),
            GestureDetector(
              onTap: () => _editTimer(model),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 11, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(_elapsedLabel(model.elapsed),
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
                  if (model.paused)
                    const Text('  · Paused',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: model.paused ? 'Resume' : 'Pause',
            icon: Icon(model.paused
                ? Icons.play_circle_outline
                : Icons.pause_circle_outline),
            onPressed: () =>
                model.paused ? model.resumeTimer() : model.pauseTimer(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : GlassButton(
                    dense: true,
                    onPressed: () => _finish(model),
                    label: model.isEditing ? 'Update' : 'Finish',
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: model.entries.isEmpty
                ? _EmptyState(onAdd: () => _addExercises(model))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                    children: [
                      for (var i = 0; i < model.entries.length; i++)
                        _ExerciseCard(
                          entry: model.entries[i],
                          onRemoveExercise: () => model.removeExercise(i),
                          onEditType: (idx) => _editSetType(model, model.entries[i], idx),
                          onToggleSet: (row, v) {
                            model.toggleComplete(row, v);
                            if (v) _startRest(model.entries[i].restSeconds);
                          },
                          onAddSet: () => model.addSet(model.entries[i]),
                          onPickRest: () => _pickRest(model, model.entries[i]),
                        ),
                      const SizedBox(height: 8),
                      GlassButton(
                        onPressed: () => _addExercises(model),
                        icon: Icons.add,
                        label: 'Add exercise',
                      ),
                    ],
                  ),
          ),
          if (_restRemaining > 0) _restBar(theme),
        ],
      ),
    );
  }

  Widget _restBar(ThemeData theme) {
    final m = _restRemaining ~/ 60;
    final s = (_restRemaining % 60).toString().padLeft(2, '0');
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.timer, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Rest  $m:$s',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton(onPressed: () => _bumpRest(-15), child: const Text('-15s')),
            TextButton(onPressed: () => _bumpRest(15), child: const Text('+15s')),
            TextButton(
              onPressed: () {
                _restTimer?.cancel();
                setState(() => _restRemaining = 0);
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  String _elapsedLabel(Duration d) {
    final h = d.inHours;
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

String _restLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m > 0 ? '${m}m ' : ''}${s > 0 ? '${s}s' : ''}'.trim();
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: primary.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: -2),
              ],
            ),
            child: AnimIcon(
                asset: 'assets/anim/dumbbell.json',
                fallback: Icons.fitness_center,
                size: 56,
                color: primary),
          ),
          const SizedBox(height: 16),
          const Text('No exercises yet', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Add your first exercise to start logging.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 18),
          SizedBox(
            width: 220,
            child: AccentButton(onPressed: onAdd, icon: Icons.add, label: 'Add exercise'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ActiveExercise entry;
  final VoidCallback onRemoveExercise;
  final ValueChanged<int> onEditType;
  final void Function(ActiveSetRow row, bool value) onToggleSet;
  final VoidCallback onAddSet;
  final VoidCallback onPickRest;

  const _ExerciseCard({
    required this.entry,
    required this.onRemoveExercise,
    required this.onEditType,
    required this.onToggleSet,
    required this.onAddSet,
    required this.onPickRest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var normalCount = 0;
    final beats = entry.beatsPrevious;
    final fields = metricFieldsFor(entry.exercise.exerciseType);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(entry.exercise.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (beats) const _MedalBadge(),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickRest,
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(entry.restSeconds == 0 ? 'Rest off' : _restLabel(entry.restSeconds)),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 20), onPressed: onRemoveExercise),
              ],
            ),
            _SetHeaderRow(fields: fields),
            for (var i = 0; i < entry.sets.length; i++)
              _SetRowWidget(
                label: entry.sets[i].type == WorkoutSetType.normal
                    ? '${++normalCount}'
                    : setTypeBadge(entry.sets[i].type),
                row: entry.sets[i],
                fields: fields,
                exerciseType: entry.exercise.exerciseType,
                onTapBadge: () => onEditType(i),
                onToggle: (v) => onToggleSet(entry.sets[i], v),
              ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated "new best vs last time" medal.
class _MedalBadge extends StatelessWidget {
  const _MedalBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('medal'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            const SizedBox(width: 2),
            Text('PR', style: TextStyle(color: Colors.amber.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SetHeaderRow extends StatelessWidget {
  final List<MetricField> fields;
  const _SetHeaderRow({required this.fields});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, color: Colors.grey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 30, child: Text('SET', style: style)),
          const SizedBox(width: 4),
          const SizedBox(
              width: 60,
              child: Text('PREVIOUS', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          for (final f in fields)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(f.label, style: style, textAlign: TextAlign.center),
              ),
            ),
          const SizedBox(
              width: 40, child: Text('✓', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _SetRowWidget extends StatelessWidget {
  final String label;
  final ActiveSetRow row;
  final List<MetricField> fields;
  final String? exerciseType;
  final VoidCallback onTapBadge;
  final ValueChanged<bool> onToggle;

  const _SetRowWidget({
    required this.label,
    required this.row,
    required this.fields,
    required this.exerciseType,
    required this.onTapBadge,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final done = row.completed;
    final prevText = formatSetSummary(
      weight: row.prevWeight,
      reps: row.prevReps,
      durationSeconds: row.prevDurationSeconds,
      distanceMeters: row.prevDistanceMeters,
      exerciseType: exerciseType,
    );
    final hasPrev = prevText.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          // Completed sets glow green for clear "done" feedback.
          color: done ? AppColors.live.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: done ? AppColors.live.withValues(alpha: 0.55) : Colors.transparent),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onTapBadge,
                  child: _SetBadge(label: label, type: row.type),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 60,
              // Tap the previous value to copy it into the inputs (Hevy-style).
              child: GestureDetector(
                onTap: hasPrev ? _fillFromPrevious : null,
                child: Text(
                  hasPrev ? prevText : '—',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: hasPrev
                          ? Colors.grey.shade400
                          : Colors.grey.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            for (final f in fields)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _field(f),
                ),
              ),
            SizedBox(
              width: 40,
              child: Checkbox(
                value: row.completed,
                onChanged: (v) => onToggle(v ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fillFromPrevious() {
    if (row.weight.text.trim().isEmpty && row.prevWeight != null) {
      row.weight.text = fmtWeight(row.prevWeight!);
    }
    if (row.reps.text.trim().isEmpty && row.prevReps != null) {
      row.reps.text = row.prevReps!.toString();
    }
    if (row.duration.text.trim().isEmpty && row.prevDurationSeconds != null) {
      row.duration.text = fmtDuration(row.prevDurationSeconds!);
    }
    if (row.distance.text.trim().isEmpty && row.prevDistanceMeters != null) {
      row.distance.text = fmtDistanceKm(row.prevDistanceMeters!);
    }
  }

  Widget _field(MetricField f) {
    switch (f.kind) {
      case MetricKind.weight:
        return _numField(row.weight,
            row.prevWeight != null ? fmtWeight(row.prevWeight!) : null);
      case MetricKind.reps:
        return _numField(row.reps, row.prevReps?.toString(), decimal: false);
      case MetricKind.duration:
        return _DurationField(
          row: row,
          hint: row.prevDurationSeconds != null
              ? fmtDuration(row.prevDurationSeconds!)
              : null,
        );
      case MetricKind.distance:
        return _numField(row.distance,
            row.prevDistanceMeters != null ? fmtDistanceKm(row.prevDistanceMeters!) : null);
    }
  }

  Widget _numField(TextEditingController controller, String? hint,
      {bool decimal = true, bool duration = false}) {
    return TextField(
      controller: controller,
      keyboardType: duration
          ? TextInputType.datetime
          : TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(duration
            ? RegExp(r'[0-9:]')
            : (decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')))
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        border: const OutlineInputBorder(),
        hintText: hint ?? (duration ? '0:00' : '0'),
        // Lighter placeholder shows last time's numbers.
        hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Time input for duration exercises: tap Start to run a live timer, tap Stop to
/// capture the elapsed time into the field — which then stays editable (clear it
/// to time again).
class _DurationField extends StatefulWidget {
  final ActiveSetRow row;
  final String? hint;
  const _DurationField({required this.row, this.hint});

  @override
  State<_DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<_DurationField> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.row.duration.addListener(_onText);
  }

  void _onText() => setState(() {}); // swap Start pill ↔ editable field as text changes

  // Run a local 1s repaint ticker only while the model says this timer is live.
  // Start/stop state lives on the set model so completing the set can capture it.
  void _syncTicker() {
    if (widget.row.durationRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.row.durationRunning && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.row.duration.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTicker();
    final theme = Theme.of(context);
    final model = context.read<ActiveWorkoutModel>();
    if (widget.row.durationRunning) {
      return _pill(AppColors.live, Icons.stop,
          fmtDuration(widget.row.durationElapsed),
          () => model.stopDurationTimer(widget.row));
    }
    if (widget.row.duration.text.trim().isEmpty) {
      return _pill(theme.colorScheme.primary, Icons.play_arrow, 'Start',
          () => model.startDurationTimer(widget.row));
    }
    // Captured value — editable (clear to re-time).
    return TextField(
      controller: widget.row.duration,
      keyboardType: TextInputType.datetime,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        border: const OutlineInputBorder(),
        hintText: widget.hint ?? '0:00',
        hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _pill(Color color, IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  final String label;
  final WorkoutSetType type;
  const _SetBadge({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (type) {
      WorkoutSetType.normal => theme.colorScheme.surfaceContainerHighest,
      WorkoutSetType.warmup => Colors.amber.shade700,
      WorkoutSetType.drop => Colors.blueAccent,
      WorkoutSetType.failure => Colors.redAccent,
    };
    final fg = type == WorkoutSetType.normal ? theme.colorScheme.onSurface : Colors.white;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
    );
  }
}
