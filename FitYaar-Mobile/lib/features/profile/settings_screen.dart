import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_button.dart';
import '../../core/health/health_sync_service.dart';
import '../auth/auth_provider.dart';
import '../workout/import/import_workouts_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_service.dart';
import 'screens/change_password_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/go_pro_screen.dart';
import 'screens/health_connection_screen.dart';
import 'screens/language_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/settings_section_screen.dart';
import 'screens/unit_settings_screen.dart';
import 'screens/update_email_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

  void _soon(BuildContext c, String t, {String? note}) =>
      _push(c, ComingSoonScreen(title: t, note: note));

  void _section(BuildContext c, String t, List<SettingsItem> items) =>
      _push(c, SettingsSectionScreen(title: t, items: items));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _header(context, 'Subscription'),
          _tile(context, Icons.workspace_premium, 'FitYaar Pro',
              () => _push(context, const GoProScreen())),

          _header(context, 'Account'),
          _tile(context, Icons.person_outline, 'Account', () async {
            final profile = await context.read<ProfileService>().getProfile();
            if (!context.mounted) return;
            _section(context, 'Account', [
              SettingsItem('Edit profile',
                  icon: Icons.edit_outlined,
                  onTap: () => _push(context, EditProfileScreen(current: profile))),
              SettingsItem(
                  (context.read<AuthProvider>().user?.hasPassword ?? true)
                      ? 'Change password'
                      : 'Set a password',
                  icon: Icons.password,
                  onTap: () => _push(context, const ChangePasswordScreen())),
              SettingsItem('Update email',
                  icon: Icons.mail_outline,
                  onTap: () => _push(
                      context, UpdateEmailScreen(currentEmail: profile.email ?? ''))),
              SettingsItem('Update username',
                  icon: Icons.alternate_email,
                  onTap: () => _push(context, EditProfileScreen(current: profile))),
              SettingsItem('Delete account',
                  icon: Icons.delete_outline,
                  onTap: () => _push(context, const DeleteAccountScreen())),
            ]);
          }),
          _tile(context, Icons.notifications_none, 'Notifications',
              () => _push(context, const NotificationSettingsScreen())),

          _header(context, 'Preferences'),
          _tile(context, Icons.lock_outline, 'Privacy', () async {
            final profile = await context.read<ProfileService>().getProfile();
            if (!context.mounted) return;
            _push(context, PrivacySettingsScreen(current: profile));
          }),
          _tile(context, Icons.straighten, 'Units', () async {
            final profile = await context.read<ProfileService>().getProfile();
            if (!context.mounted) return;
            _push(context, UnitSettingsScreen(current: profile));
          }),
          _tile(context, Icons.language, 'Language', () async {
            final profile = await context.read<ProfileService>().getProfile();
            if (!context.mounted) return;
            _push(context, LanguageSettingsScreen(current: profile));
          }),
          _tile(context, Icons.extension_outlined, 'Integrations', () {
            final health = context.read<HealthSyncService>();
            _section(context, 'Integrations', [
              SettingsItem(health.storeName,
                  icon: Icons.favorite_border,
                  onTap: () => _push(context, const HealthConnectionScreen())),
              // Fitbit (incl. Pixel Watch / Fitbit Air) reaches FitYaar through the phone's
              // health store, so it routes to the same screen.
              SettingsItem('Fitbit / smartwatch',
                  icon: Icons.watch,
                  onTap: () => _push(context, const HealthConnectionScreen())),
              SettingsItem('Import from Hevy / Strong',
                  icon: Icons.upload_file,
                  onTap: () => _push(context, const ImportWorkoutsScreen())),
              SettingsItem('Strava',
                  icon: Icons.directions_run,
                  onTap: () => _soon(context, 'Strava',
                      note: 'Sync your Strava runs and rides automatically.')),
            ]);
          }),
          _tile(context, Icons.import_export, 'Data', () {
            _section(context, 'Data', [
              SettingsItem('Export data',
                  icon: Icons.download,
                  onTap: () =>
                      _soon(context, 'Export Data', note: 'Download all your workout and nutrition history.')),
              SettingsItem('Import workouts (Hevy / Strong)',
                  icon: Icons.upload,
                  onTap: () => _push(context, const ImportWorkoutsScreen())),
            ]);
          }),

          _header(context, 'Support'),
          _tile(context, Icons.menu_book_outlined, 'Guide', () {
            _section(context, 'Guide', [
              SettingsItem('Getting started',
                  icon: Icons.rocket_launch_outlined,
                  onTap: () => _soon(context, 'Getting Started',
                      note: 'Learn the basics of using FitYaar.')),
              SettingsItem('How to log a workout',
                  icon: Icons.edit_note,
                  onTap: () => _soon(context, 'Workout Logging',
                      note: 'A step-by-step guide to tracking your sets.')),
              SettingsItem('Build a routine',
                  icon: Icons.list_alt,
                  onTap: () => _soon(context, 'Routine Builder',
                      note: 'How to create and save custom workout routines.')),
            ]);
          }),
          _tile(context, Icons.help_outline, 'Help', () {
            _section(context, 'Help', [
              SettingsItem('FAQ',
                  icon: Icons.quiz_outlined,
                  onTap: () => _soon(context, 'FAQ', note: 'Frequently asked questions.')),
              SettingsItem('Contact us',
                  icon: Icons.mail_outline,
                  onTap: () => _soon(context, 'Contact Us',
                      note: 'Email us at support@fityaar.com')),
              SettingsItem('Rate on the store',
                  icon: Icons.star_border,
                  onTap: () => _soon(context, 'Rate FitYaar',
                      note: 'Share your feedback on the app store.')),
              SettingsItem('About',
                  icon: Icons.info_outline,
                  onTap: () => _soon(context, 'About', note: 'FitYaar version 1.0.0')),
            ]);
          }),
          _tile(context, Icons.groups_outlined, 'Community',
              () => _soon(context, 'Community', note: 'Join challenges and connect with other members.')),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassButton(
              icon: Icons.logout,
              label: 'Log out',
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext c, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.6)),
      );

  Widget _tile(BuildContext c, IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      );
}
