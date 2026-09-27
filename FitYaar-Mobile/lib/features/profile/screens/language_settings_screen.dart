import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_models.dart';
import '../profile_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  final ProfileData current;
  const LanguageSettingsScreen({super.key, required this.current});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _language;
  bool _saving = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
  ];

  @override
  void initState() {
    super.initState();
    _language = widget.current.language ?? 'en';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateProfile(language: _language);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving language: $e')),
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
        title: const Text('Language'),
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
      body: ListView(
        children: _languages
            .map((lang) => RadioListTile<String>(
                  title: Text(lang['name']!),
                  value: lang['code']!,
                  groupValue: _language,
                  onChanged: (v) => setState(() => _language = v!),
                ))
            .toList(),
      ),
    );
  }
}
