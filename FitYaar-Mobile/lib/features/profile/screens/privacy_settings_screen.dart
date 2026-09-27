import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_models.dart';
import '../profile_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final ProfileData current;
  const PrivacySettingsScreen({super.key, required this.current});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late bool _isPublic;
  late bool _gymVisible;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.current.isPublic;
    _gymVisible = widget.current.gymVisible;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateProfile(
            isPublic: _isPublic,
            gymVisible: _gymVisible,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving privacy settings: $e')),
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
        title: const Text('Privacy'),
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
        children: [
          SwitchListTile(
            title: const Text('Public Profile'),
            subtitle: const Text('Allow everyone to see your workouts and progress'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          SwitchListTile(
            title: const Text('Gym Visibility'),
            subtitle: const Text('Show your presence in the gym active-now list'),
            value: _gymVisible,
            onChanged: (v) => setState(() => _gymVisible = v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Placeholder for blocked accounts list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Blocked accounts list coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}
