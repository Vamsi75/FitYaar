import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_models.dart';
import '../workout_service.dart';
import 'equipment_icon.dart';
import 'muscle_thumb.dart';

/// Result of a filter screen. `null` return = dismissed (no change);
/// a [FilterResult] = applied (its [value] may be null → "no filter").
class FilterResult {
  final String? value;
  const FilterResult(this.value);
}

// Muscle groups organised like Hevy's picker.
const _muscleSections = <String, List<String>>{
  'Upper Body': [
    'CHEST', 'UPPER_CHEST', 'LOWER_CHEST', 'FRONT_DELTS', 'SIDE_DELTS',
    'REAR_DELTS', 'BICEPS', 'TRICEPS', 'FOREARMS', 'LATS', 'UPPER_BACK',
    'TRAPS', 'NECK',
  ],
  'Core': ['ABS', 'OBLIQUES', 'LOWER_BACK'],
  'Lower Body': ['QUADRICEPS', 'HAMSTRINGS', 'GLUTES', 'CALVES'],
};

const _equipmentTypes = [
  'BARBELL', 'DUMBBELL', 'MACHINE', 'CABLE', 'KETTLEBELL', 'PLATE', 'BAND',
  'NO_EQUIPMENT', 'OTHER',
];

Future<FilterResult?> showMuscleFilter(
  BuildContext context, {
  String? current,
  required String query,
  String? equipment,
}) {
  return Navigator.of(context).push<FilterResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FilterScreen(
        title: 'Muscle group',
        initial: current,
        query: query,
        isMuscle: true,
        lockedEquipment: equipment,
      ),
    ),
  );
}

Future<FilterResult?> showEquipmentFilter(
  BuildContext context, {
  String? current,
  required String query,
  String? muscle,
}) {
  return Navigator.of(context).push<FilterResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FilterScreen(
        title: 'Equipment',
        initial: current,
        query: query,
        isMuscle: false,
        lockedMuscle: muscle,
      ),
    ),
  );
}

class _FilterScreen extends StatefulWidget {
  final String title;
  final String? initial;
  final String query;
  final bool isMuscle;
  final String? lockedMuscle; // active muscle filter (equipment screen)
  final String? lockedEquipment; // active equipment filter (muscle screen)

  const _FilterScreen({
    required this.title,
    required this.initial,
    required this.query,
    required this.isMuscle,
    this.lockedMuscle,
    this.lockedEquipment,
  });

  @override
  State<_FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<_FilterScreen> {
  String? _pending;
  int? _count;
  bool _counting = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pending = widget.initial;
    _refreshCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _refreshCount() {
    setState(() => _counting = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final muscle = widget.isMuscle ? _pending : widget.lockedMuscle;
      final equipment = widget.isMuscle ? widget.lockedEquipment : _pending;
      try {
        final r = await context.read<WorkoutService>().searchExercises(
              widget.query,
              muscle: muscle,
              equipment: equipment,
            );
        if (!mounted) return;
        setState(() {
          _count = r.length;
          _counting = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _count = null;
          _counting = false;
        });
      }
    });
  }

  void _pick(String token) {
    setState(() => _pending = _pending == token ? null : token);
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.isMuscle ? _muscleGrid() : _equipmentGrid(),
      bottomNavigationBar: _footer(Theme.of(context)),
    );
  }

  Widget _muscleGrid() {
    return CustomScrollView(
      slivers: [
        for (final entry in _muscleSections.entries) ...[
          SliverToBoxAdapter(child: _sectionHeader(entry.key)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 112,
                childAspectRatio: 0.82,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _muscleCard(entry.value[i]),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _equipmentGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 112,
        childAspectRatio: 0.9,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _equipmentTypes.length,
      itemBuilder: (context, i) => _equipmentCard(_equipmentTypes[i]),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6),
        ),
      );

  Widget _muscleCard(String token) {
    final selected = _pending == token;
    return _cell(
      token: token,
      selected: selected,
      child: MuscleThumb(token, size: 54, selected: selected),
    );
  }

  Widget _equipmentCard(String token) {
    final selected = _pending == token;
    return _cell(
      token: token,
      selected: selected,
      child: EquipmentIcon(token, size: 50, selected: selected),
    );
  }

  Widget _cell({
    required String token,
    required bool selected,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(token),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  prettyEnum(token),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: selected ? theme.colorScheme.primary : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    final label = _counting || _count == null
        ? 'Show results'
        : 'Show $_count ${_count == 1 ? 'result' : 'results'}';
    return Material(
      color: const Color(0xFF16100F),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pending == null
                      ? null
                      : () {
                          setState(() => _pending = null);
                          _refreshCount();
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, FilterResult(_pending)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: _counting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
