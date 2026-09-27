import 'package:flutter/material.dart';

/// Generic placeholder for settings/guide/help destinations not built yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String? note;
  const ComingSoonScreen({super.key, required this.title, this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 56, color: Colors.white38),
              const SizedBox(height: 12),
              Text(note ?? 'Coming soon',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
