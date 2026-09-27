// Maps an exercise's ExerciseType to the set-logging fields it uses, and
// formats set values per type. Single source of truth for the active logger,
// the "Previous" column, and history/summary displays.

enum MetricKind { weight, reps, duration, distance }

class MetricField {
  final MetricKind kind;
  final String label; // header label: KG / REPS / TIME / KM
  final int sign; // -1 for assisted (shows as "-kg")
  const MetricField(this.kind, this.label, {this.sign = 1});
}

/// Ordered input fields for an exercise type. Defaults to weight × reps.
List<MetricField> metricFieldsFor(String? exerciseType) {
  switch (exerciseType) {
    case 'BODYWEIGHT_REPS':
      return const [MetricField(MetricKind.reps, 'REPS')];
    case 'WEIGHTED_BODYWEIGHT_REPS':
      return const [
        MetricField(MetricKind.weight, '+KG'),
        MetricField(MetricKind.reps, 'REPS'),
      ];
    case 'ASSISTED_BODYWEIGHT_REPS':
      return const [
        MetricField(MetricKind.weight, '-KG', sign: -1),
        MetricField(MetricKind.reps, 'REPS'),
      ];
    case 'DURATION':
      return const [MetricField(MetricKind.duration, 'TIME')];
    case 'DURATION_WEIGHT':
      return const [
        MetricField(MetricKind.weight, 'KG'),
        MetricField(MetricKind.duration, 'TIME'),
      ];
    case 'DISTANCE_DURATION':
      return const [
        MetricField(MetricKind.distance, 'KM'),
        MetricField(MetricKind.duration, 'TIME'),
      ];
    case 'WEIGHT_DISTANCE':
      return const [
        MetricField(MetricKind.weight, 'KG'),
        MetricField(MetricKind.distance, 'KM'),
      ];
    case 'WEIGHT_REPS':
    default:
      return const [
        MetricField(MetricKind.weight, 'KG'),
        MetricField(MetricKind.reps, 'REPS'),
      ];
  }
}

// ── value formatters ─────────────────────────────────────────────────────────
String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Seconds → "m:ss".
String fmtDuration(int? seconds) {
  if (seconds == null) return '';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// "h:mm:ss" / "m:ss" / plain seconds → seconds. Parses colon groups
/// positionally in base-60 so extra groups don't get silently dropped.
int? parseDuration(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  if (t.contains(':')) {
    var total = 0;
    for (final p in t.split(':')) {
      total = total * 60 + (int.tryParse(p.trim()) ?? 0);
    }
    return total;
  }
  return int.tryParse(t);
}

/// Metres → km display value (no unit). Keeps up to 3 decimals (1 m precision)
/// so an edit round-trip (m → km text → m) doesn't lose distance.
String fmtDistanceKm(double? meters) {
  if (meters == null) return '';
  final km = meters / 1000;
  if (km == km.roundToDouble()) return km.toInt().toString();
  return km
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

/// km text → metres.
double? parseDistanceKmToMeters(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final km = double.tryParse(t);
  return km == null ? null : km * 1000;
}

/// Format a set from whichever values are present (no type needed) — for history
/// where the exercise type isn't loaded. e.g. "62kg × 7", "1:30", "2km · 12:30".
String formatSetByValues({
  double? weight,
  int? reps,
  int? durationSeconds,
  double? distanceMeters,
}) {
  final parts = <String>[];
  if (distanceMeters != null) parts.add('${fmtDistanceKm(distanceMeters)}km');
  if (durationSeconds != null) parts.add(fmtDuration(durationSeconds));
  if (weight != null && reps != null) {
    parts.add('${_num(weight)}kg × $reps');
  } else {
    if (weight != null) parts.add('${_num(weight)}kg');
    if (reps != null) parts.add('× $reps');
  }
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// Compact one-line summary of a set for a given type — used by the Previous
/// column and history/summary rows. e.g. "62kg × 7", "1:30", "2km · 12:30".
String formatSetSummary({
  double? weight,
  int? reps,
  int? durationSeconds,
  double? distanceMeters,
  String? exerciseType,
}) {
  final parts = <String>[];
  for (final f in metricFieldsFor(exerciseType)) {
    switch (f.kind) {
      case MetricKind.weight:
        if (weight != null) parts.add('${f.sign < 0 ? '-' : ''}${_num(weight)}kg');
        break;
      case MetricKind.reps:
        if (reps != null) parts.add('× $reps');
        break;
      case MetricKind.duration:
        if (durationSeconds != null) parts.add(fmtDuration(durationSeconds));
        break;
      case MetricKind.distance:
        if (distanceMeters != null) parts.add('${fmtDistanceKm(distanceMeters)}km');
        break;
    }
  }
  return parts.join(' · ');
}
