import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import 'profile_models.dart';
import 'profile_service.dart';

const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

class EditProfileScreen extends StatefulWidget {
  final ProfileData current;
  const EditProfileScreen({super.key, required this.current});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _pic;
  late final TextEditingController _instagram;
  late final TextEditingController _website;
  String? _gender;
  DateTime? _birthday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _name = TextEditingController(text: c.displayName ?? '');
    _bio = TextEditingController(text: c.bio ?? '');
    _pic = TextEditingController(text: c.profilePictureUrl ?? '');
    _instagram = TextEditingController(text: c.instagram ?? '');
    _website = TextEditingController(text: c.website ?? '');
    _gender = _genders.contains(c.gender) ? c.gender : null;
    _birthday = c.birthday;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _pic.dispose();
    _instagram.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateProfile(
            displayName: _name.text.trim(),
            bio: _bio.text.trim(),
            profilePictureUrl: _pic.text.trim(),
            instagram: _instagram.text.trim(),
            website: _website.text.trim(),
            gender: _gender,
            birthday: _birthday,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save profile.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _avatarHeader(context),
          const SizedBox(height: 20),
          _glassField(_name, 'Display name',
              capitalization: TextCapitalization.words),
          const SizedBox(height: 16),
          _glassField(_bio, 'Bio', maxLines: 3),
          const SizedBox(height: 24),
          _sectionLabel(context, 'Links'),
          const SizedBox(height: 10),
          _glassField(_instagram, 'Instagram', hint: '@handle'),
          const SizedBox(height: 16),
          _glassField(_website, 'Website',
              hint: 'https://…', keyboard: TextInputType.url),
          const SizedBox(height: 24),
          _sectionLabel(context, 'Private (not shown publicly)'),
          const SizedBox(height: 10),
          _label('Gender'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: _glassDecoration(context),
            items: [
              for (final g in _genders)
                DropdownMenuItem(value: g, child: Text(g)),
            ],
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          _label('Birthday'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickBirthday,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                Text(
                  _birthday == null
                      ? 'Tap to set'
                      : DateFormat('d MMM yyyy').format(_birthday!),
                  style: TextStyle(color: _birthday == null ? Colors.white54 : Colors.white),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white54),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _avatarHeader(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = _pic.text.trim();
    return Center(
      child: GestureDetector(
        onTap: _changePhoto,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: primary.withValues(alpha: 0.2),
                  backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                  child: url.isEmpty
                      ? Text(_initials(),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold))
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF150F12), width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Change photo',
                style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto() async {
    final ctrl = TextEditingController(text: _pic.text);
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1214),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste image URL'),
              onTap: () async {
                final u = await showDialog<String>(
                  context: ctx,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Image URL'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(hintText: 'https://...'),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(dctx, ctrl.text.trim()), child: const Text('Set')),
                    ],
                  ),
                );
                if (u != null && ctx.mounted) Navigator.pop(ctx, u);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from gallery'),
              subtitle: const Text('Coming soon (simulated)'),
              onTap: () {
                // Mock image upload
                Navigator.pop(ctx, 'https://i.pravatar.cc/300?u=${widget.current.displayName}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              subtitle: const Text('Coming soon (simulated)'),
              onTap: () {
                Navigator.pop(ctx, 'https://i.pravatar.cc/300?u=camera');
              },
            ),
            if (_pic.text.trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Remove photo', style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(ctx, ''),
              ),
          ],
        ),
      ),
    );
    if (url != null) setState(() => _pic.text = url);
  }

  String _initials() {
    final n = _name.text.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(text.toUpperCase(),
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.6));

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  InputDecoration _glassDecoration(BuildContext context, {String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4)),
      );

  Widget _glassField(TextEditingController c, String label,
      {String? hint,
      int maxLines = 1,
      TextInputType? keyboard,
      TextCapitalization capitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: maxLines,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          decoration: _glassDecoration(context, hint: hint),
        ),
      ],
    );
  }
}
