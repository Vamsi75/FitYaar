import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/goal_options.dart';
import '../profile/measurement_service.dart';
import '../profile/profile_service.dart';
import '../profile/screens/go_pro_screen.dart';

/// Placeholder calorie/TDEE calculator (future FitYaar web tool).
const _calculatorUrl = 'https://fityaar.app/calculator';

/// Quick, 3-step post-signup onboarding: about you → goal → daily targets.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;
  bool _saving = false;

  String _gender = 'Male';
  double _age = 25;
  double _height = 170; // cm
  double _weight = 70; // kg
  double _targetWeight = 65; // kg
  String? _goal;
  final _calories = TextEditingController();

  bool get _isWeightGoal => _goal == 'Lose weight' || _goal == 'Build muscle';

  @override
  void dispose() {
    _pager.dispose();
    _calories.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pager.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final profileSvc = context.read<ProfileService>();
    final measureSvc = context.read<MeasurementService>();
    final now = DateTime.now();
    final birthday = DateTime(now.year - _age.round(), now.month, now.day);
    try {
      await profileSvc.updateProfile(
        gender: _gender,
        birthday: birthday,
        currentWeight: _weight,
        targetWeight: _isWeightGoal ? _targetWeight : null,
        height: _height,
        fitnessGoal: _goal,
        dailyCalorieGoal: double.tryParse(_calories.text.trim()),
      );
      // Seed the first body-weight point so the tracker starts populated.
      await measureSvc.upsert(weightKg: _weight);
    } catch (_) {
      // Non-fatal — the user can fill these in later from Profile.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You\'re all set! 💪')));
  }

  void _skip() => Navigator.of(context).pop();

  Future<void> _openCalculator() async {
    final uri = Uri.parse(_calculatorUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Calculator opens soon — enter your number below.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress + skip.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? theme.colorScheme.primary
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  TextButton(onPressed: _skip, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _aboutYou(theme),
                  _goalPage(theme),
                  _targetsPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _pager.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut),
                      child: const Text('Back'),
                    ),
                  Expanded(
                    child: GlassButton(
                      label: _page < 2 ? 'Continue' : 'Finish',
                      icon: _page < 2 ? Icons.arrow_forward : Icons.check,
                      expand: true,
                      loading: _saving,
                      onPressed: _saving ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageScaffold(ThemeData theme, String emoji, String title, String sub,
      List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _aboutYou(ThemeData theme) {
    return _pageScaffold(theme, '👋', 'About you',
        'This tailors your stats and muscle map.', [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gender', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Row(
              children: [
                _genderChip(theme, 'Male', Icons.male),
                const SizedBox(width: 8),
                _genderChip(theme, 'Female', Icons.female),
                const SizedBox(width: 8),
                _genderChip(theme, 'Other', Icons.transgender),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _sliderCard(theme, 'Age', _age, 12, 90, 'yrs', true,
          (v) => setState(() => _age = v)),
      const SizedBox(height: 14),
      _sliderCard(theme, 'Height', _height, 120, 220, 'cm', true,
          (v) => setState(() => _height = v)),
      const SizedBox(height: 14),
      _sliderCard(theme, 'Weight', _weight, 30, 200, 'kg', false,
          (v) => setState(() => _weight = v)),
    ]);
  }

  Widget _genderChip(ThemeData theme, String g, IconData icon) {
    final active = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active ? Colors.orange.shade200 : Colors.white70),
              const SizedBox(height: 4),
              Text(g,
                  style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.orange.shade200 : Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderCard(ThemeData theme, String label, double value, double min,
      double max, String unit, bool isInt, ValueChanged<double> onChanged) {
    final display = isInt ? value.round().toString() : value.toStringAsFixed(1);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              // Tap the number to type an exact value.
              GestureDetector(
                onTap: () =>
                    _editValue(label, value, min, max, unit, isInt, onChanged),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(display,
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(color: Colors.white54)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 13, color: Colors.white38),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              thumbColor: theme.colorScheme.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editValue(String label, double current, double min, double max,
      String unit, bool isInt, ValueChanged<double> onChanged) async {
    final ctrl = TextEditingController(
        text: isInt ? current.round().toString() : current.toStringAsFixed(1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label ($unit)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Set')),
        ],
      ),
    );
    if (ok == true) {
      final v = double.tryParse(ctrl.text.trim());
      if (v != null) onChanged(v.clamp(min, max));
    }
  }

  Widget _goalPage(ThemeData theme) {
    return _pageScaffold(theme, '🎯', 'What\'s your goal?',
        'We\'ll shape your insights around it.', [
      GoalPillGrid(
        selected: _goal,
        isPro: context.read<AuthProvider>().isPro,
        onSelect: (l) => setState(() {
          _goal = l;
          if (l == 'Lose weight') {
            _targetWeight = (_weight - 5).clamp(30, 200);
          } else if (l == 'Build muscle') {
            _targetWeight = (_weight + 5).clamp(30, 200);
          }
        }),
        onPremiumTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GoProScreen())),
      ),
      if (_isWeightGoal) ...[
        const SizedBox(height: 16),
        _sliderCard(theme, 'Target weight', _targetWeight, 30, 200, 'kg', false,
            (v) => setState(() => _targetWeight = v)),
        const SizedBox(height: 8),
        Text(
            'Current ${_weight.toStringAsFixed(1)} kg  →  target ${_targetWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    ]);
  }

  Widget _targetsPage(ThemeData theme) {
    return _pageScaffold(theme, '🍽️', 'Your daily calories',
        'Fuel your goal. Know your daily target (TDEE)? Add it — or use our calculator.', [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Your TDEE is the calories you burn per day. We\'ll base your daily target on it, your goal and stats.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            GlassButton(
              icon: Icons.calculate_outlined,
              label: 'Open calculator (web)',
              onPressed: _openCalculator,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      GlassCard(
        child: TextField(
          controller: _calories,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily calorie target (kcal) — optional',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text('You can change all of this later in Profile.',
          style: TextStyle(color: Colors.white38, fontSize: 12)),
    ]);
  }
}
