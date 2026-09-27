import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_models.dart';
import '../profile_service.dart';

class UnitSettingsScreen extends StatefulWidget {
  final ProfileData current;
  const UnitSettingsScreen({super.key, required this.current});

  @override
  State<UnitSettingsScreen> createState() => _UnitSettingsScreenState();
}

class _UnitSettingsScreenState extends State<UnitSettingsScreen> {
  late String _weightUnit;
  late String _distanceUnit;
  late String _measurementUnit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightUnit = widget.current.weightUnit ?? 'kg';
    _distanceUnit = widget.current.distanceUnit ?? 'km';
    _measurementUnit = widget.current.measurementUnit ?? 'cm';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateProfile(
            weightUnit: _weightUnit,
            distanceUnit: _distanceUnit,
            measurementUnit: _measurementUnit,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving units: $e')),
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
        title: const Text('Units'),
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
          _buildRadioSection('Weight', ['kg', 'lb'], _weightUnit, (v) => setState(() => _weightUnit = v!)),
          _buildRadioSection('Distance', ['km', 'mi'], _distanceUnit, (v) => setState(() => _distanceUnit = v!)),
          _buildRadioSection('Body measurements', ['cm', 'in'], _measurementUnit, (v) => setState(() => _measurementUnit = v!)),
        ],
      ),
    );
  }

  Widget _buildRadioSection(String title, List<String> options, String current, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...options.map((opt) => RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: current,
              onChanged: onChanged,
            )),
        const Divider(),
      ],
    );
  }
}
