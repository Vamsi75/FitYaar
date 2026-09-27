import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';

class SettingsItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const SettingsItem(this.label, {this.icon, this.onTap});
}

/// A settings sub-page listing the individual options of a category.
class SettingsSectionScreen extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;
  const SettingsSectionScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          for (final it in items)
            ListTile(
              leading: it.icon != null ? Icon(it.icon) : null,
              title: Text(it.label),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: it.onTap ??
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ComingSoonScreen(title: it.label))),
            ),
        ],
      ),
    );
  }
}
