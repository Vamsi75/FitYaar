import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/glass_button.dart';
import '../workout_service.dart';
import 'share_launcher.dart';
import 'workout_share_cards.dart';

/// Swipe through the share-card designs, pick Square (posts) or Story (9:16), then
/// save the chosen one to Photos or send it to any app as a PNG.
class ShareWorkoutScreen extends StatefulWidget {
  final WorkoutShareData data;
  const ShareWorkoutScreen({super.key, required this.data});

  @override
  State<ShareWorkoutScreen> createState() => _ShareWorkoutScreenState();
}

class _ShareWorkoutScreenState extends State<ShareWorkoutScreen> {
  final _page = PageController(viewportFraction: 0.84);
  final _keys = {for (final k in ShareCardKind.values) k: GlobalKey()};
  late WorkoutShareData _data = widget.data;
  ShareFormat _format = ShareFormat.square;
  int _index = 0;
  bool _busy = false;

  List<ShareCardKind> get _kinds => _data.availableKinds;
  ShareCardKind get _kind => _kinds[_index.clamp(0, _kinds.length - 1)];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/brand/wordmark.png'), context);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  /// History unlocks the month recap (and PRs, when opened from a past workout).
  Future<void> _loadHistory() async {
    try {
      final history = await context.read<WorkoutService>().getHistory();
      if (!mounted) return;
      final current = _kind;
      setState(() {
        _data = _data.copyWith(
          recap: buildMonthRecap(history, _data.date),
          prs: _data.prs.isNotEmpty ? null : prsForWorkout(history, _data.date),
        );
        // Keep the card the user is looking at selected if new ones were inserted.
        final i = _kinds.indexOf(current);
        if (i >= 0 && i != _index) {
          _index = i;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_page.hasClients) _page.jumpToPage(i);
          });
        }
      });
    } catch (e) {
      debugPrint('Share: history load failed: $e');
    }
  }

  ShareFormat get _effective =>
      WorkoutShareCard.effectiveFormat(_kind, _format);

  /// Renders the visible card to PNG bytes at full resolution (1080 wide).
  Future<Uint8List?> _render() async {
    final boundary = _keys[_kind]!.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    final image = await boundary.toImage(
        pixelRatio: _effective.widthPx / boundary.size.width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  String get _baseName {
    final slug =
        _data.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final d = _data.date;
    final date =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final fmt = _effective == ShareFormat.story ? '-story' : '';
    return 'fityaar-$slug-${_kind.name}$fmt-$date';
  }

  Future<void> _save() => _run(() async {
        final bytes = await _render();
        if (bytes == null) throw 'render';
        if (!await Gal.hasPermission(toAlbum: true) &&
            !await Gal.requestPermission(toAlbum: true)) {
          _toast('Allow photo access to save images.');
          return;
        }
        await Gal.putImageBytes(bytes, album: 'FitYaar', name: _baseName);
        _toast('Saved to Photos › FitYaar');
      });

  Future<void> _share() {
    // iPad anchors the share popover to this box; read it before any await.
    final box = context.findRenderObject() as RenderBox?;
    return _run(() async {
      final bytes = await _render();
      if (bytes == null) throw 'render';
      final name = '$_baseName.png';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
        fileNameOverrides: [name],
        text: '${_data.name} on FitYaar 💪',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    });
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      debugPrint('Share card export failed: $e');
      _toast('Couldn\'t create the image. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _preview(ShareCardKind kind) {
    final card = ClipRRect(
      borderRadius:
          BorderRadius.circular(kind == ShareCardKind.sticker ? 0 : 18),
      child: RepaintBoundary(
        key: _keys[kind],
        child: WorkoutShareCard(kind: kind, data: _data, format: _format),
      ),
    );
    if (kind != ShareCardKind.sticker) return card;
    // Show the transparent sticker over a stand-in "photo" (not part of the PNG).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A6073), Color(0xFF16222A), Color(0xFF5A3F37)],
        ),
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kinds = _kinds;
    final storyAspect = _format == ShareFormat.story;
    return Scaffold(
      appBar: AppBar(title: const Text('Share workout')),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 4),
          SegmentedButton<ShareFormat>(
            segments: const [
              ButtonSegment(
                  value: ShareFormat.square,
                  icon: Icon(Icons.crop_square, size: 18),
                  label: Text('Square')),
              ButtonSegment(
                  value: ShareFormat.story,
                  icon: Icon(Icons.crop_portrait, size: 18),
                  label: Text('Story')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: kinds.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: i == _index ? 1 : 0.92,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio:
                          WorkoutShareCard.effectiveFormat(kinds[i], _format)
                              .aspect,
                      child: _preview(kinds[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(_kind.label, style: theme.textTheme.titleMedium),
          if (_kind == ShareCardKind.sticker)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('No background — place it on your own photo',
                  style: TextStyle(fontSize: 12, color: Colors.white54)),
            )
          else if (storyAspect)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('1080 × 1920 · Instagram & WhatsApp Status',
                  style: TextStyle(fontSize: 12, color: Colors.white54)),
            ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < kinds.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      i == _index ? theme.colorScheme.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(
                child: GlassButton(
                  icon: Icons.download,
                  label: 'Save',
                  expand: true,
                  onPressed: _busy ? null : _save,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassButton(
                  icon: Icons.ios_share,
                  label: _busy ? 'Working…' : 'Share',
                  expand: true,
                  onPressed: _busy ? null : _share,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
