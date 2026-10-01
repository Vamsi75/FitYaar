import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_models.dart';
import '../profile_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final ProfileData current;
  const ThemeSettingsScreen({super.key, required this.current});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late String _theme;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _theme = widget.current.theme ?? 'system';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateProfile(theme: _theme);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving theme: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        actions: [
          if (_saving)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: RadioGroup<String>(
        groupValue: _theme,
        onChanged: (value) {
          if (value != null) setState(() => _theme = value);
        },
        child: ListView(
          children: const [
            RadioListTile<String>(
              title: Text('Light'),
              value: 'light',
            ),
            RadioListTile<String>(
              title: Text('Dark'),
              value: 'dark',
            ),
            RadioListTile<String>(
              title: Text('System Default'),
              value: 'system',
            ),
          ],
        ),
      ),
    );
  }
}
