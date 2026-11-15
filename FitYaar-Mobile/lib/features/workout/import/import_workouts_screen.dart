import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/profile_service.dart';
import '../workout_service.dart';
import 'import_models.dart';

/// Settings → Data → Import workouts: upload a Hevy or Strong CSV export.
/// Flow: pick file → server preview (dry run) → confirm → import.
class ImportWorkoutsScreen extends StatefulWidget {
  const ImportWorkoutsScreen({super.key});

  @override
  State<ImportWorkoutsScreen> createState() => _ImportWorkoutsScreenState();
}

class _ImportWorkoutsScreenState extends State<ImportWorkoutsScreen> {
  String _unit = 'KG';
  List<int>? _bytes;
  String? _filename;
  WorkoutImportResult? _preview;
  WorkoutImportResult? _done;
  bool _busy = false;
  String? _error;

  static final _date = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    // Default the unit to the user's preference (only used when the file doesn't say).
    context.read<ProfileService>().getProfile().then((p) {
      final u = p.weightUnit?.toLowerCase() ?? '';
      if (mounted && (u.startsWith('lb') || u == 'imperial')) setState(() => _unit = 'LBS');
    }).catchError((_) {});
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
      );
    } catch (_) {
      // Some Android file providers reject extension filters — fall back to any file.
      res = await FilePicker.platform.pickFiles(withData: true);
    }
    final file = res?.files.single;
    if (file == null) return;
    if (file.bytes == null) {
      setState(() => _error = 'Couldn\'t read that file.');
      return;
    }
    setState(() {
      _bytes = file.bytes;
      _filename = file.name;
      _preview = null;
      _done = null;
    });
    await _run(dryRun: true);
  }

  Future<void> _run({required bool dryRun}) async {
    final bytes = _bytes, name = _filename;
    if (bytes == null || name == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await context.read<WorkoutService>().importCsv(
            bytes: bytes,
            filename: name,
            dryRun: dryRun,
            weightUnit: _unit,
          );
      if (!mounted) return;
      setState(() => dryRun ? _preview = r : _done = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Upload failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import workouts')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_done != null) ..._doneView(theme, _done!) else ...[
            Text('Bring your history from Hevy or Strong',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Your workouts, sets and PRs come across. Importing the same file again '
                'won\'t create duplicates.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            _howTo(theme),
            const SizedBox(height: 16),
            GlassCard(
              child: Row(children: [
                const Expanded(
                  child: Text('Weight unit in the file',
                      style: TextStyle(color: Colors.white70)),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'KG', label: Text('kg')),
                    ButtonSegment(value: 'LBS', label: Text('lb')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: _busy
                      ? null
                      : (s) {
                          setState(() => _unit = s.first);
                          if (_preview != null) _run(dryRun: true);
                        },
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text('Only used if the file doesn\'t say (Hevy files always do).',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            const SizedBox(height: 16),
            GlassButton(
              icon: Icons.upload_file,
              label: _filename == null ? 'Choose CSV file' : 'Choose a different file',
              expand: true,
              onPressed: _busy ? null : _pick,
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            if (_preview != null && !_busy) ..._previewView(theme, _preview!),
          ],
        ],
      ),
    );
  }

  Widget _howTo(ThemeData theme) => GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Export your data first', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _step('Hevy', 'Profile → Settings → Export & Import Data → Export Workouts'),
          _step('Strong', 'Settings → Export Strong Data'),
          const SizedBox(height: 4),
          const Text('Save the CSV to your phone, then choose it below.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      );

  Widget _step(String app, String path) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RichText(
          text: TextSpan(style: const TextStyle(color: Colors.white70, fontSize: 13), children: [
            TextSpan(text: '$app  ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: path),
          ]),
        ),
      );

  List<Widget> _previewView(ThemeData theme, WorkoutImportResult r) {
    final range = r.firstWorkout != null && r.lastWorkout != null
        ? '${_date.format(r.firstWorkout!)} – ${_date.format(r.lastWorkout!)}'
        : null;
    final matched = r.exercises.where((e) => !e.isNewCustom).toList();
    final custom = r.exercises.where((e) => e.isNewCustom).toList();
    return [
      const SizedBox(height: 20),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r.appName} export', style: theme.textTheme.titleMedium),
          if (range != null)
            Text(range, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            _num(theme, r.workoutsImported, 'new workouts'),
            _num(theme, r.setsImported, 'sets'),
            _num(theme, r.duplicatesSkipped, 'already here'),
          ]),
          if (r.rowsSkipped > 0) ...[
            const SizedBox(height: 10),
            Text('${r.rowsSkipped} rows couldn\'t be read and will be skipped.',
                style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exercises', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
              '${matched.length} matched to FitYaar exercises'
              '${custom.isEmpty ? '' : ' · ${custom.length} added as your custom exercises'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          for (final e in r.exercises.take(40)) _mappingRow(e),
          if (r.exercises.length > 40)
            Text('+ ${r.exercises.length - 40} more',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
      if (r.warnings.isNotEmpty) ...[
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('${r.warnings.length} warnings',
              style: const TextStyle(color: Colors.amber, fontSize: 14)),
          children: [
            for (final w in r.warnings)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(w, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      if (r.workoutsImported == 0)
        const Text('Everything in this file is already in FitYaar.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))
      else
        GlassButton(
          icon: Icons.download_done,
          label: 'Import ${r.workoutsImported} workout${r.workoutsImported == 1 ? '' : 's'}',
          expand: true,
          onPressed: _busy ? null : () => _run(dryRun: false),
        ),
    ];
  }

  Widget _mappingRow(ImportExerciseMapping e) {
    final same = e.sourceName.toLowerCase() == e.exerciseName.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(e.isNewCustom ? Icons.add_circle_outline : Icons.check_circle,
            size: 16, color: e.isNewCustom ? Colors.white38 : const Color(0xFF37E29A)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (!e.isNewCustom && !same)
              Text('→ ${e.exerciseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (e.isNewCustom)
              const Text('new custom exercise',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
        Text('${e.sets} set${e.sets == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  List<Widget> _doneView(ThemeData theme, WorkoutImportResult r) => [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, size: 64, color: Color(0xFF37E29A)),
        const SizedBox(height: 12),
        Text('Imported ${r.workoutsImported} workouts',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
            '${r.setsImported} sets from ${r.appName}'
            '${r.duplicatesSkipped > 0 ? ' · ${r.duplicatesSkipped} already here' : ''}'
            '${r.newCustomCount > 0 ? ' · ${r.newCustomCount} custom exercises added' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        GlassButton(
          icon: Icons.check,
          label: 'Done',
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ];

  Widget _num(ThemeData theme, int v, String label) => Expanded(
        child: Column(children: [
          Text('$v', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      );
}
