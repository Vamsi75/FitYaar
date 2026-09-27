import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _workoutReminders = true;
  bool _communityUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable all push notifications'),
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          SwitchListTile(
            title: const Text('Workout Reminders'),
            subtitle: const Text('Get notified when it\'s time to workout'),
            value: _workoutReminders,
            onChanged: (v) => setState(() => _workoutReminders = v),
          ),
          SwitchListTile(
            title: const Text('Community Updates'),
            subtitle: const Text('Get notified about new followers and likes'),
            value: _communityUpdates,
            onChanged: (v) => setState(() => _communityUpdates = v),
          ),
        ],
      ),
    );
  }
}
