import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../models/workout_models.dart';
import '../widgets/equipment_icon.dart';
import '../widgets/filter_sheets.dart';
import '../widgets/muscle_thumb.dart';
import '../workout_service.dart';

/// Search + filter + multi-select exercises. Pops with the selected List<Exercise>.
class ExercisePickerScreen extends StatefulWidget {
  /// Pre-select a muscle-group filter (e.g. from the "Train Legs" nudge).
  final String? initialMuscle;

  const ExercisePickerScreen({super.key, this.initialMuscle});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final _search = TextEditingController();
  final _selected = <int, Exercise>{};
  Timer? _debounce;

  String? _muscle;
  String? _equipment;
  List<Exercise> _results = [];
  bool _loading = true;
  String? _error;
  int _loadSeq = 0; // guards against out-of-order search responses

  @override
  void initState() {
    super.initState();
    _muscle = widget.initialMuscle;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await context.read<WorkoutService>().searchExercises(
            _search.text.trim(),
            muscle: _muscle,
            equipment: _equipment,
          );
      if (!mounted || seq != _loadSeq) return; // a newer search superseded this one
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _error = 'Could not load exercises';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  bool get _hasFilters => _muscle != null || _equipment != null;

  Future<void> _pickMuscle() async {
    FocusScope.of(context).unfocus();
    final r = await showMuscleFilter(
      context,
      current: _muscle,
      query: _search.text.trim(),
      equipment: _equipment,
    );
    if (r != null && mounted) {
      setState(() => _muscle = r.value);
      _load();
    }
  }

  Future<void> _pickEquipment() async {
    FocusScope.of(context).unfocus();
    final r = await showEquipmentFilter(
      context,
      current: _equipment,
      query: _search.text.trim(),
      muscle: _muscle,
    );
    if (r != null && mounted) {
      setState(() => _equipment = r.value);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercises')),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: GlassButton(
                  icon: Icons.add,
                  expand: true,
                  label:
                      'Add ${_selected.length} ${_selected.length == 1 ? 'exercise' : 'exercises'}',
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(_selected.values.toList());
                  },
                ),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              // Dismiss focus when tapping elsewhere — avoids a Flutter-web
              // pointer assertion when tapping a result while the field is focused.
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Muscle',
                  value: _muscle,
                  leading: _muscle == null
                      ? null
                      : MuscleThumb(_muscle!, size: 22),
                  onTap: _pickMuscle,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Equipment',
                  value: _equipment,
                  leading: _equipment == null
                      ? null
                      : EquipmentIcon(_equipment!, size: 22),
                  onTap: _pickEquipment,
                ),
                if (_hasFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _muscle = null;
                        _equipment = null;
                      });
                      _load();
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_results.isEmpty) {
      return const Center(child: Text('No exercises match'));
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final ex = _results[i];
        final selected = _selected.containsKey(ex.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Drop keyboard focus before mutating — sidesteps the web pointer
                // assertion when tapping a tile while the search field is focused.
                FocusScope.of(context).unfocus();
                setState(() {
                  if (selected) {
                    _selected.remove(ex.id);
                  } else {
                    _selected[ex.id] = ex;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (ex.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(ex.subtitle,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A pill that shows the picked filter (with its thumbnail/icon) and opens a
/// visual filter sheet on tap.
class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? leading;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = value != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(active && leading != null ? 6 : 12, 6, 8, 6),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border:
                active ? Border.all(color: theme.colorScheme.primary) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active && leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ],
              Text(active ? prettyEnum(value!) : label,
                  style: TextStyle(
                      color: active ? theme.colorScheme.primary : null,
                      fontSize: 13)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
