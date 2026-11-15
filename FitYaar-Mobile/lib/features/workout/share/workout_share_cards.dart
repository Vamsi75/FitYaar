import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/health/health_sync_service.dart';
import '../../insights/analytics.dart' show PrEvent, muscleSlugLabel;
import '../../insights/widgets/muscle_body.dart';
import '../active_workout_model.dart' show fmtWeight;
import '../models/workout_models.dart';

/// Everything a share card needs about one finished workout.
class WorkoutShareData {
  final String name;
  final DateTime date;
  final Duration duration;
  final List<LoggedExercise> exercises;

  /// Body-map slug → 0..1 (how much each muscle was worked).
  final Map<String, double> muscleIntensity;
  final String? gender;
  final HealthMetrics? metrics;

  /// Personal records set in this workout.
  final List<PrEvent> prs;

  /// The month this workout belongs to (needs the user's history; null until loaded).
  final MonthRecap? recap;

  const WorkoutShareData({
    required this.name,
    required this.date,
    required this.duration,
    required this.exercises,
    required this.muscleIntensity,
    this.gender,
    this.metrics,
    this.prs = const [],
    this.recap,
  });

  WorkoutShareData copyWith({List<PrEvent>? prs, MonthRecap? recap}) =>
      WorkoutShareData(
        name: name,
        date: date,
        duration: duration,
        exercises: exercises,
        muscleIntensity: muscleIntensity,
        gender: gender,
        metrics: metrics,
        prs: prs ?? this.prs,
        recap: recap ?? this.recap,
      );

  int get prCount => prs.length;

  bool get hasHeartRateChart =>
      metrics?.avgHeartRate != null &&
      (metrics?.heartRateSamples.length ?? 0) >= 2;

  /// Designs that make sense for this workout, in carousel order.
  List<ShareCardKind> get availableKinds => [
        ShareCardKind.summary,
        ShareCardKind.muscles,
        ShareCardKind.volume,
        ShareCardKind.log,
        if (hasHeartRateChart) ShareCardKind.heartRate,
        if (prs.isNotEmpty) ShareCardKind.records,
        if (recap != null && recap!.workouts > 0) ShareCardKind.recap,
        ShareCardKind.sticker,
      ];

  Iterable<LoggedSet> get workingSets => exercises
      .expand((e) => e.sets)
      .where((s) => s.type != WorkoutSetType.warmup);

  int get setCount => workingSets.length;

  int get repCount => workingSets.fold(0, (a, s) => a + (s.reps ?? 0));

  double get volumeKg =>
      workingSets.fold(0.0, (a, s) => a + (s.weight ?? 0) * (s.reps ?? 0));

  String get durationLabel {
    final h = duration.inHours, m = duration.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    if (duration.inMinutes == 0) return '${duration.inSeconds}s';
    return '${m}m';
  }

  /// The most-worked muscles, readable ("Chest", "Lats"…).
  List<String> topMuscles([int n = 3]) {
    final e = muscleIntensity.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e
        .map((x) => muscleSlugLabel[x.key] ?? x.key)
        .toSet()
        .take(n)
        .toList();
  }

  int? get calories => metrics?.activeCalories ?? metrics?.totalCalories;
}

/// One month of training around the shared workout.
class MonthRecap {
  final DateTime month; // any day in the month
  final int workouts;
  final double volumeKg;
  final Duration time;

  /// Days of the month (1–31) with at least one workout.
  final Set<int> activeDays;

  /// Consecutive weeks (Mon–Sun) with ≥1 workout, ending with the shared workout's week.
  final int weekStreak;

  const MonthRecap({
    required this.month,
    required this.workouts,
    required this.volumeKg,
    required this.time,
    required this.activeDays,
    required this.weekStreak,
  });
}

/// The card designs offered in the share sheet.
enum ShareCardKind {
  summary('Summary'),
  muscles('Muscle map'),
  volume('Total lifted'),
  log('Workout log'),
  heartRate('Heart rate'),
  records('New PRs'),
  recap('Month recap'),
  sticker('Sticker · transparent');

  final String label;
  const ShareCardKind(this.label);
}

/// Output shape: square posts or 9:16 stories (Instagram / WhatsApp Status).
enum ShareFormat {
  square('Square', 1080, 1080),
  story('Story', 1080, 1920);

  final String label;
  final double widthPx, heightPx;
  const ShareFormat(this.label, this.widthPx, this.heightPx);

  double get aspect => widthPx / heightPx;
}

/// One share card. Laid out on a fixed design grid ([canvas] wide; 360 or 640 tall)
/// and scaled to whatever box it's given, so the preview and the exported PNG match.
///
/// The [ShareCardKind.sticker] is always square and has no background, so it can be
/// laid over your own photo.
class WorkoutShareCard extends StatelessWidget {
  static const double canvas = 360;

  final ShareCardKind kind;
  final WorkoutShareData data;
  final ShareFormat format;
  const WorkoutShareCard({
    super.key,
    required this.kind,
    required this.data,
    this.format = ShareFormat.square,
  });

  /// The format actually rendered (stickers ignore "story").
  static ShareFormat effectiveFormat(ShareCardKind kind, ShareFormat f) =>
      kind == ShareCardKind.sticker ? ShareFormat.square : f;

  @override
  Widget build(BuildContext context) {
    final f = effectiveFormat(kind, format);
    final story = f == ShareFormat.story;
    final Widget body = switch (kind) {
      ShareCardKind.summary => _SummaryCard(data, story),
      ShareCardKind.muscles => _MuscleCard(data, story),
      ShareCardKind.volume => _VolumeCard(data, story),
      ShareCardKind.log => _LogCard(data, story),
      ShareCardKind.heartRate => _HeartRateCard(data, story),
      ShareCardKind.records => _RecordsCard(data, story),
      ShareCardKind.recap => _RecapCard(data, story),
      ShareCardKind.sticker => _StickerCard(data),
    };
    return AspectRatio(
      aspectRatio: f.aspect,
      child: FittedBox(
        child: SizedBox(
          width: canvas,
          height: canvas / f.aspect,
          child: DefaultTextStyle(
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Colors.white),
            child: kind == ShareCardKind.sticker
                ? body
                : _Frame(story: story, child: body),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces

const _orange = Color(0xFFFF6A1A);
const _hr = Color(0xFFFF5A5F);
const _muted = Color(0xB3FFFFFF); // white 70%
const _faint = Color(0x66FFFFFF); // white 40%

/// Dark gradient background, soft orange glow, FitYaar wordmark footer.
class _Frame extends StatelessWidget {
  final Widget child;
  final bool story;
  const _Frame({required this.child, this.story = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1412), Color(0xFF0E0B0B), Color(0xFF140E0C)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _orange.withValues(alpha: 0.28),
                _orange.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
        if (story)
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _orange.withValues(alpha: 0.16),
                  _orange.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        Padding(
          // Stories: keep clear of Instagram/WhatsApp's top bar and reply box.
          padding: story
              ? const EdgeInsets.fromLTRB(24, 56, 24, 34)
              : const EdgeInsets.fromLTRB(22, 20, 22, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              SizedBox(height: story ? 16 : 8),
              Row(children: [
                Image.asset('assets/brand/wordmark.png',
                    height: story ? 28 : 22),
                const Spacer(),
                const Text('fityaar.com',
                    style: TextStyle(
                        fontSize: 9, color: _faint, letterSpacing: 0.5)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final WorkoutShareData data;
  final String? eyebrow;
  const _Header(this.data, {this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        (eyebrow ?? DateFormat('EEE, d MMM yyyy').format(data.date))
            .toUpperCase(),
        style: const TextStyle(
            fontSize: 9,
            color: _orange,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 3),
      Text(data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, height: 1.15)),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final double size;
  final Color? color;
  const _Stat(this.value, this.label, {this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              maxLines: 1,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 8, color: _faint, letterSpacing: 1.1)),
        ]);
  }
}

String _kg(double kg) {
  if (kg >= 10000) return '${(kg / 1000).toStringAsFixed(1)} t';
  return '${NumberFormat.decimalPattern('en_IN').format(kg.round())} kg';
}

String _topSet(LoggedExercise le) {
  final working =
      le.sets.where((s) => s.type != WorkoutSetType.warmup).toList();
  if (working.isEmpty) return '';
  LoggedSet? top;
  for (final s in working) {
    if (top == null || (s.weight ?? 0) > (top.weight ?? 0)) top = s;
  }
  final t = top!;
  if ((t.weight ?? 0) > 0) return '${fmtWeight(t.weight!)} kg × ${t.reps ?? 0}';
  if ((t.reps ?? 0) > 0) {
    final reps = working.map((s) => s.reps ?? 0).reduce(math.max);
    return '$reps reps';
  }
  if ((t.durationSeconds ?? 0) > 0) {
    final s = t.durationSeconds!;
    return s >= 60
        ? '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}'
        : '${s}s';
  }
  if ((t.distanceMeters ?? 0) > 0) {
    return '${(t.distanceMeters! / 1000).toStringAsFixed(2)} km';
  }
  return '';
}

/// Tiny heart-rate line (no axes) from [offsetSeconds, bpm] samples.
class _HrSpark extends StatelessWidget {
  final List<List<int>> samples;
  const _HrSpark(this.samples);

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HrSparkPainter(samples), size: Size.infinite);
}

class _HrSparkPainter extends CustomPainter {
  final List<List<int>> s;
  _HrSparkPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    if (s.length < 2) return;
    final t0 = s.first[0].toDouble(), t1 = s.last[0].toDouble();
    var lo = s.map((e) => e[1]).reduce(math.min).toDouble();
    var hi = s.map((e) => e[1]).reduce(math.max).toDouble();
    if (hi - lo < 10) {
      hi += 5;
      lo -= 5;
    }
    Offset pt(List<int> e) => Offset(
          t1 == t0 ? 0 : (e[0] - t0) / (t1 - t0) * size.width,
          size.height - (e[1] - lo) / (hi - lo) * size.height,
        );
    final line = Path()..moveTo(pt(s.first).dx, pt(s.first).dy);
    for (final e in s.skip(1)) {
      final p = pt(e);
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_hr.withValues(alpha: 0.35), _hr.withValues(alpha: 0)],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        line,
        Paint()
          ..color = _hr
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _HrSparkPainter old) => old.s != s;
}

// ---------------------------------------------------------------------------
// 1. Summary

class _SummaryCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _SummaryCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final m = d.metrics;
    final hasHr = m?.avgHeartRate != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _Stat(d.durationLabel, 'Time', size: 26)),
        Expanded(child: _Stat(_kg(d.volumeKg), 'Volume', size: 26)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Stat('${d.setCount}', 'Sets', size: 26)),
        Expanded(
            child: d.prCount > 0
                ? _Stat(
                    '${d.prCount} 🏆', d.prCount == 1 ? 'New PR' : 'New PRs',
                    size: 26, color: const Color(0xFFFFB020))
                : _Stat('${d.exercises.length}', 'Exercises', size: 26)),
      ]),
      if (story) ...[
        const SizedBox(height: 28),
        const Text('EXERCISES',
            style: TextStyle(fontSize: 8, color: _faint, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        for (final le in d.exercises.take(hasHr ? 7 : 11))
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Expanded(
                child: Text(le.exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
              Text(_topSet(le),
                  style: const TextStyle(fontSize: 11, color: _muted)),
            ]),
          ),
        if (d.exercises.length > (hasHr ? 7 : 11))
          Text('+ ${d.exercises.length - (hasHr ? 7 : 11)} more',
              style: const TextStyle(fontSize: 11, color: _faint)),
      ],
      const Spacer(),
      if (hasHr)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: _hr.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hr.withValues(alpha: 0.25)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.favorite, color: _hr, size: 13),
              const SizedBox(width: 6),
              Text('${m!.avgHeartRate} avg',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Text('${m.maxHeartRate ?? '—'} max',
                  style: const TextStyle(fontSize: 11, color: _muted)),
              if (d.calories != null) ...[
                const SizedBox(width: 10),
                Text('${d.calories} kcal',
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ],
              const Spacer(),
              if (m.sourceName != null)
                Text(HealthSyncService.friendlySourceName(m.sourceName!),
                    style: const TextStyle(fontSize: 9, color: _faint)),
            ]),
            if (m.heartRateSamples.length >= 2) ...[
              const SizedBox(height: 6),
              SizedBox(
                  height: story ? 70 : 40, child: _HrSpark(m.heartRateSamples)),
            ],
          ]),
        )
      else if (!story)
        Text(
          d.exercises.take(4).map((e) => e.exercise.name).join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _muted, height: 1.4),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 2. Muscle map

class _MuscleCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _MuscleCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final top = d.topMuscles();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d),
      const SizedBox(height: 4),
      if (top.isNotEmpty)
        Text(top.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _muted)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Theme(
            // The body map paints worked muscles in the theme's primary colour.
            data: Theme.of(context).copyWith(
                colorScheme:
                    Theme.of(context).colorScheme.copyWith(primary: _orange)),
            child: LayoutBuilder(
              builder: (context, c) => MuscleBody(
                intensity: d.muscleIntensity,
                gender: d.gender,
                height: c.maxHeight,
              ),
            ),
          ),
        ),
      ),
      Row(children: [
        Expanded(child: _Stat(d.durationLabel, 'Time', size: 16)),
        Expanded(child: _Stat(_kg(d.volumeKg), 'Volume', size: 16)),
        Expanded(child: _Stat('${d.setCount}', 'Sets', size: 16)),
        if (d.metrics?.avgHeartRate != null)
          Expanded(
              child: _Stat('${d.metrics!.avgHeartRate}', 'Avg bpm',
                  size: 16, color: _hr)),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 3. Total weight lifted

/// Everyday things to compare the volume with (approximate kg).
const _comparisons = <(String name, String plural, String emoji, double kg)>[
  ('golden retriever', 'golden retrievers', '🐕', 30),
  ('washing machine', 'washing machines', '🧺', 70),
  ('Royal Enfield', 'Royal Enfields', '🏍️', 195),
  ('auto-rickshaw', 'auto-rickshaws', '🛺', 350),
  ('buffalo', 'buffaloes', '🐃', 550),
  ('Maruti Alto', 'Maruti Altos', '🚗', 750),
  ('Mahindra Thar', 'Mahindra Thars', '🚙', 1750),
  ('elephant', 'elephants', '🐘', 4000),
  ('city bus', 'city buses', '🚌', 12000),
];

class _VolumeCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _VolumeCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final kg = d.volumeKg;
    // The biggest thing lifted at least once.
    final (String, String, String, double)? cmp = kg <= 0
        ? null
        : _comparisons.lastWhere((c) => kg >= c.$4,
            orElse: () => _comparisons.first);
    final times = cmp == null ? 0.0 : kg / cmp.$4;
    final timesLabel = times >= 10
        ? times.round().toString()
        : times.toStringAsFixed(1).replaceAll('.0', '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d),
      const Spacer(),
      const Text('TOTAL LIFTED',
          style: TextStyle(fontSize: 10, color: _faint, letterSpacing: 1.6)),
      FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFFFB020), _orange],
          ).createShader(r),
          child: Text(
            kg <= 0
                ? '—'
                : NumberFormat.decimalPattern('en_IN').format(kg.round()),
            style: const TextStyle(
                fontSize: 76,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: Colors.white),
          ),
        ),
      ),
      const Text('kilograms', style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 14),
      if (cmp != null)
        Row(children: [
          Text(cmp.$3, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'That\'s like lifting\n'),
                TextSpan(
                  text: '$timesLabel ${times > 1.05 ? cmp.$2 : cmp.$1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ]),
              style: const TextStyle(fontSize: 13, color: _muted, height: 1.3),
            ),
          ),
        ]),
      const Spacer(),
      Row(children: [
        Expanded(child: _Stat('${d.setCount}', 'Sets', size: 16)),
        Expanded(child: _Stat('${d.repCount}', 'Reps', size: 16)),
        Expanded(child: _Stat(d.durationLabel, 'Time', size: 16)),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 4. Workout log

class _LogCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _LogCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final rows = d.exercises.take(story ? 11 : 6).toList();
    final more = d.exercises.length - rows.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d,
          eyebrow:
              '${DateFormat('d MMM').format(d.date)}  ·  ${d.durationLabel}  ·  ${_kg(d.volumeKg)}'),
      const SizedBox(height: 14),
      for (final le in rows) ...[
        _logRow(le, detailed: rows.length <= (story ? 8 : 4)),
        const SizedBox(height: 8),
      ],
      if (more > 0)
        Text('+ $more more exercise${more == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11, color: _faint)),
      const Spacer(),
    ]);
  }

  /// "20×12 · 40×12 · 60×12" — every working set, for short workouts.
  static String _setList(LoggedExercise le) {
    final parts = <String>[];
    for (final s in le.sets.where((s) => s.type != WorkoutSetType.warmup)) {
      if ((s.weight ?? 0) > 0) {
        parts.add('${fmtWeight(s.weight!)}×${s.reps ?? 0}');
      } else if ((s.reps ?? 0) > 0) {
        parts.add('${s.reps}');
      } else if ((s.durationSeconds ?? 0) > 0) {
        final d = s.durationSeconds!;
        parts.add(d >= 60
            ? '${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}'
            : '${d}s');
      } else if ((s.distanceMeters ?? 0) > 0) {
        parts.add('${(s.distanceMeters! / 1000).toStringAsFixed(1)}km');
      }
    }
    final unit = le.sets.any((s) => (s.weight ?? 0) > 0)
        ? ' kg'
        : (parts.isNotEmpty &&
                le.sets.every((s) => (s.weight ?? 0) == 0 && (s.reps ?? 0) > 0)
            ? ' reps'
            : '');
    return parts.isEmpty ? '' : '${parts.join('  ·  ')}$unit';
  }

  Widget _logRow(LoggedExercise le, {bool detailed = false}) {
    final n = le.sets.where((s) => s.type != WorkoutSetType.warmup).length;
    final sets = detailed ? _setList(le) : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$n',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _orange)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(le.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (sets.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(sets,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _faint)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(_topSet(le), style: const TextStyle(fontSize: 11, color: _muted)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Heart rate

const _zoneColors = [
  Color(0xFF5B8DEF),
  Color(0xFF37E29A),
  Color(0xFFF5D547),
  Color(0xFFF5A623),
  Color(0xFFFF5A5F),
];
const _zoneNames = ['Warm-up', 'Easy', 'Aerobic', 'Threshold', 'Max'];

class _HeartRateCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _HeartRateCard(this.d, this.story);

  static String _mins(int secs) =>
      secs < 60 ? '${secs}s' : '${(secs / 60).round()}m';

  @override
  Widget build(BuildContext context) {
    final m = d.metrics!;
    final zones = m.zoneSeconds.take(5).toList();
    final zoneTotal = zones.fold<int>(0, (a, b) => a + b);
    final source = m.sourceName == null
        ? null
        : HealthSyncService.friendlySourceName(m.sourceName!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d),
      SizedBox(height: story ? 28 : 14),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Icon(Icons.favorite, color: _hr, size: 26),
        const SizedBox(width: 8),
        Text('${m.avgHeartRate}',
            style: TextStyle(
                fontSize: story ? 64 : 46,
                fontWeight: FontWeight.w800,
                height: 1)),
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 6),
          child: Text('avg bpm', style: TextStyle(fontSize: 12, color: _muted)),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _Stat('${m.maxHeartRate ?? '—'}', 'Max bpm',
                size: 16, color: _hr)),
        Expanded(child: _Stat('${m.minHeartRate ?? '—'}', 'Min bpm', size: 16)),
        Expanded(
            child: _Stat(
                d.calories?.toString() ?? '—',
                m.activeCalories == null && m.totalCalories != null
                    ? 'Total kcal'
                    : 'kcal',
                size: 16)),
        Expanded(child: _Stat(d.durationLabel, 'Time', size: 16)),
      ]),
      SizedBox(height: story ? 26 : 12),
      Expanded(child: _HrSpark(m.heartRateSamples)),
      SizedBox(height: story ? 22 : 10),
      if (zoneTotal > 0) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            for (var i = 0; i < zones.length; i++)
              if (zones[i] > 0)
                Expanded(
                    flex: zones[i],
                    child: Container(height: 8, color: _zoneColors[i])),
          ]),
        ),
        const SizedBox(height: 8),
        if (story) ...[
          for (var i = zones.length - 1; i >= 0; i--)
            if (zones[i] > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _zoneColors[i], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Z${i + 1}  ${_zoneNames[i]}',
                      style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text(_mins(zones[i]),
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ]),
              ),
        ] else
          Wrap(spacing: 10, runSpacing: 4, children: [
            for (var i = 0; i < zones.length; i++)
              if (zones[i] > 0)
                Text('Z${i + 1} ${_mins(zones[i])}',
                    style: TextStyle(fontSize: 10, color: _zoneColors[i])),
          ]),
      ],
      if (source != null) ...[
        const SizedBox(height: 6),
        Text('Recorded by $source',
            style: const TextStyle(fontSize: 9, color: _faint)),
      ],
    ]);
  }
}

// ---------------------------------------------------------------------------
// 6. New PRs

const _gold = Color(0xFFFFB020);

class _RecordsCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _RecordsCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final prs = d.prs.take(story ? 8 : 4).toList();
    final n = d.prs.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(d),
      const Spacer(),
      Center(child: Text('🏆', style: TextStyle(fontSize: story ? 84 : 52))),
      const SizedBox(height: 6),
      Center(
        child: ShaderMask(
          shaderCallback: (r) =>
              const LinearGradient(colors: [Color(0xFFFFE08A), _gold, _orange])
                  .createShader(r),
          child: Text(
            n == 1 ? 'NEW PERSONAL RECORD' : '$n NEW PERSONAL RECORDS',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: story ? 22 : 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white),
          ),
        ),
      ),
      SizedBox(height: story ? 28 : 14),
      for (final pr in prs)
        Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.30)),
          ),
          child: Row(children: [
            Expanded(
              child: Text(pr.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            Text('${fmtWeight(pr.weight)} kg × ${pr.reps}',
                style: const TextStyle(fontSize: 12, color: Colors.white)),
            const SizedBox(width: 8),
            Text('+${pr.deltaKg.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF37E29A),
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      if (n > prs.length)
        Text('+ ${n - prs.length} more',
            style: const TextStyle(fontSize: 11, color: _faint)),
      const SizedBox(height: 4),
      const Text('+kg = estimated 1-rep max gain',
          style: TextStyle(fontSize: 8, color: _faint)),
      const Spacer(),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 7. Month recap

class _RecapCard extends StatelessWidget {
  final WorkoutShareData d;
  final bool story;
  const _RecapCard(this.d, this.story);

  @override
  Widget build(BuildContext context) {
    final r = d.recap!;
    final first = DateTime(r.month.year, r.month.month, 1);
    final days = DateUtils.getDaysInMonth(r.month.year, r.month.month);
    final lead = first.weekday - 1; // Monday-first grid
    final today = d.date.day;
    final cells = lead + days;
    final rows = (cells / 7).ceil();
    final cell = story ? 34.0 : 22.0;
    final hours = r.time.inMinutes / 60;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(DateFormat('MMMM yyyy').format(r.month).toUpperCase(),
          style: const TextStyle(
              fontSize: 9,
              color: _orange,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text('${r.workouts} workout${r.workouts == 1 ? '' : 's'} this month',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, height: 1.15)),
      if (r.weekStreak >= 2) ...[
        const SizedBox(height: 4),
        Text('🔥 ${r.weekStreak}-week streak',
            style: const TextStyle(
                fontSize: 13, color: _gold, fontWeight: FontWeight.w600)),
      ],
      const Spacer(),
      Center(
        child: Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              SizedBox(
                width: cell + 6,
                child: Text(l,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: _faint)),
              ),
          ]),
          const SizedBox(height: 4),
          for (var row = 0; row < rows; row++)
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var col = 0; col < 7; col++)
                Builder(builder: (_) {
                  final day = row * 7 + col - lead + 1;
                  final inMonth = day >= 1 && day <= days;
                  final active = inMonth && r.activeDays.contains(day);
                  final isShared = inMonth && day == today;
                  return Container(
                    width: cell,
                    height: cell,
                    margin: const EdgeInsets.all(3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !inMonth
                          ? Colors.transparent
                          : active
                              ? _orange.withValues(alpha: isShared ? 1 : 0.75)
                              : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(story ? 9 : 6),
                      border: isShared
                          ? Border.all(color: Colors.white, width: 1.4)
                          : null,
                    ),
                    child: inMonth
                        ? Text('$day',
                            style: TextStyle(
                                fontSize: story ? 11 : 8,
                                color: active ? Colors.white : _faint,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w400))
                        : null,
                  );
                }),
            ]),
        ]),
      ),
      const Spacer(),
      Row(children: [
        Expanded(
            child: _Stat('${r.activeDays.length}', 'Active days', size: 16)),
        Expanded(child: _Stat(_kg(r.volumeKg), 'Volume', size: 16)),
        Expanded(
            child: _Stat(
                hours >= 1
                    ? '${hours.toStringAsFixed(1)} h'
                    : '${r.time.inMinutes}m',
                'Time',
                size: 16)),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 8. Transparent sticker — no background, for laying over your own photo.

class _StickerCard extends StatelessWidget {
  final WorkoutShareData d;
  const _StickerCard(this.d);

  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 8)];

  Widget _big(String value, String label) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.05,
                shadows: _shadow)),
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.4,
                color: Colors.white,
                shadows: _shadow)),
      ]);

  @override
  Widget build(BuildContext context) {
    final m = d.metrics;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(d.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                shadows: _shadow)),
        const SizedBox(height: 22),
        _big(_kg(d.volumeKg), 'Lifted'),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _big(d.durationLabel, 'Time'),
          _big('${d.setCount}', 'Sets'),
          if (m?.avgHeartRate != null) _big('${m!.avgHeartRate}', 'Avg bpm'),
        ]),
        const SizedBox(height: 26),
        // Logo on a soft dark pill so it reads on bright photos too.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset('assets/brand/wordmark.png', height: 22),
        ),
      ]),
    );
  }
}
