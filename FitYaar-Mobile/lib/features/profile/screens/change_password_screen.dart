import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/auth_provider.dart';
import '../profile_service.dart';

/// Change password — or, for accounts created with Google sign-in that don't have a
/// password yet, set one (no "current password" step).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _minLength = 8;

  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false, _showNew = false;
  bool _loading = false;
  String? _error;

  /// False for Google sign-ups that never chose a password.
  bool get _hasPassword => context.read<AuthProvider>().user?.hasPassword ?? true;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final hasPassword = _hasPassword;
    String? error;
    if (hasPassword && _current.text.isEmpty) {
      error = 'Enter your current password.';
    } else if (_new.text.length < _minLength) {
      error = 'Use at least $_minLength characters for the new password.';
    } else if (_new.text != _confirm.text) {
      error = 'The new passwords don\'t match.';
    } else if (hasPassword && _new.text == _current.text) {
      error = 'Choose a password different from your current one.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final profiles = context.read<ProfileService>();
    final auth = context.read<AuthProvider>();
    try {
      if (hasPassword) {
        await profiles.changePassword(_current.text, _new.text);
      } else {
        await profiles.setPassword(_new.text);
        await auth.refreshUser(); // now has a password → screen shows "Change" next time
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasPassword ? 'Password changed' : 'Password set')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = context.watch<AuthProvider>().user?.hasPassword ?? true;
    final title = hasPassword ? 'Change password' : 'Set a password';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!hasPassword)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: GlassCard(
                child: Text(
                    'You signed up with Google. Set a password to also sign in with '
                    'your email, change your email or delete your account.',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          if (hasPassword) ...[
            _field(_current, 'Current password', _showCurrent,
                () => setState(() => _showCurrent = !_showCurrent),
                autofill: AutofillHints.password),
            const SizedBox(height: 14),
          ],
          _field(_new, hasPassword ? 'New password' : 'Password', _showNew,
              () => setState(() => _showNew = !_showNew),
              autofill: AutofillHints.newPassword),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text('At least $_minLength characters.',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
          ),
          const SizedBox(height: 14),
          _field(_confirm, 'Confirm password', _showNew, null,
              autofill: AutofillHints.newPassword),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(height: 24),
          GlassButton(
            label: hasPassword ? 'Update password' : 'Set password',
            icon: Icons.lock_outline,
            expand: true,
            loading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, bool visible, VoidCallback? toggle,
      {String? autofill}) {
    return TextField(
      controller: c,
      obscureText: !visible,
      autofillHints: autofill == null ? null : [autofill],
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        suffixIcon: toggle == null
            ? null
            : IconButton(
                tooltip: visible ? 'Hide password' : 'Show password',
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: toggle,
              ),
      ),
    );
  }
}
