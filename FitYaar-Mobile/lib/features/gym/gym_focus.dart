import 'package:flutter/material.dart';

import '../workout/models/workout_models.dart';

/// Gym check-in focus is **auto-derived** from the member's active workout as a
/// Push / Pull / Legs split — members no longer pick it by hand. The gym crowd
/// card then reads it back as "10 pushing · 3 pulling · 1 leg day".

/// Push/Pull/Legs bucket for a single muscle-group token, or null for
/// core/neck tokens that don't map onto the PPL split.
String? _ppl(String token) {
  switch (token.toUpperCase()) {
    case 'UPPER_CHEST':
    case 'CHEST':
    case 'LOWER_CHEST':
    case 'FRONT_DELTS':
    case 'SIDE_DELTS':
    case 'TRICEPS':
      return 'Push';
    case 'LATS':
    case 'UPPER_BACK':
    case 'TRAPS':
    case 'LOWER_BACK':
    case 'REAR_DELTS':
    case 'BICEPS':
    case 'FOREARMS':
      return 'Pull';
    case 'QUADRICEPS':
    case 'HAMSTRINGS':
    case 'GLUTES':
    case 'CALVES':
      return 'Legs';
    default:
      return null;
  }
}

/// Dominant Push/Pull/Legs label across [exercises]; 'Full body' when it's a
/// mix, or null when nothing is classifiable yet (e.g. an empty workout).
String? classifyFocus(Iterable<Exercise> exercises) {
  final tally = <String, int>{'Push': 0, 'Pull': 0, 'Legs': 0};
  for (final ex in exercises) {
    String? cat;
    for (final m in ex.primaryMuscleGroups) {
      cat = _ppl(m);
      if (cat != null) break;
    }
    if (cat == null) {
      for (final m in ex.secondaryMuscleGroups) {
        cat = _ppl(m);
        if (cat != null) break;
      }
    }
    if (cat != null) tally[cat] = tally[cat]! + 1;
  }
  final total = tally.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return null;
  final top = tally.entries.reduce((a, b) => b.value > a.value ? b : a);
  // A clear winner needs >half the classified exercises; else it's a mix.
  return top.value * 2 > total ? top.key : 'Full body';
}

/// Fun verb phrasing for the crowd breakdown: "pushing", "leg day", etc.
String focusVerb(String label) => switch (label) {
      'Push' => 'pushing',
      'Pull' => 'pulling',
      'Legs' => 'leg day',
      _ => label.toLowerCase(),
    };

/// Which gym zone one exercise belongs to, from its equipment/category.
String? _zoneOf(Exercise ex) {
  final cat = (ex.category ?? '').toUpperCase();
  final type = (ex.exerciseType ?? '').toUpperCase();
  if (cat == 'CARDIO' || type.contains('DURATION') || type.contains('DISTANCE')) {
    return 'Cardio';
  }
  switch ((ex.equipment ?? '').toUpperCase()) {
    case 'BARBELL':
      return 'Racks';
    case 'DUMBBELL':
    case 'KETTLEBELL':
    case 'PLATE':
      return 'Free weights';
    case 'MACHINE':
    case 'CABLE':
      return 'Machines';
    case 'BODYWEIGHT':
    case 'BAND':
    case 'SUSPENSION_BAND':
    case 'NO_EQUIPMENT':
      return 'Functional';
    default:
      return null;
  }
}

/// Dominant gym zone across [exercises] (Free weights / Racks / Cardio /
/// Machines / Functional), or null when nothing is classifiable.
String? classifyZone(Iterable<Exercise> exercises) {
  final tally = <String, int>{};
  for (final ex in exercises) {
    final z = _zoneOf(ex);
    if (z != null) tally[z] = (tally[z] ?? 0) + 1;
  }
  if (tally.isEmpty) return null;
  return tally.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// Emoji for a gym zone, used in the zone hologram.
String gymZoneEmoji(String label) => switch (label) {
      'Free weights' => '🏋️',
      'Racks' => '🔩',
      'Cardio' => '🏃',
      'Machines' => '⚙️',
      'Functional' => '🤸',
      _ => '📍',
    };

/// Unified line-art icon for a focus tag (consistent stroke style, no emoji).
IconData focusIcon(String label) => switch (label) {
      'Push' => Icons.arrow_upward_rounded,
      'Pull' => Icons.arrow_downward_rounded,
      'Legs' => Icons.directions_run_rounded,
      'Full body' => Icons.all_inclusive_rounded,
      'Cardio' => Icons.favorite_border_rounded,
      _ => Icons.bolt_outlined,
    };

String gymFocusEmoji(String label) => switch (label) {
      'Push' => '🔥',
      'Pull' => '🎯',
      'Legs' => '🦵',
      'Full body' => '💪',
      'Cardio' => '🏃',
      // Legacy manual labels older check-ins may still carry.
      'Chest' => '💪',
      'Back' => '🔙',
      'Shoulders' => '🏋️',
      'Arms' => '💪',
      'Core' => '🧱',
      _ => '⚡',
    };
