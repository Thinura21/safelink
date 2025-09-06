// lib/screens/profile_page/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  const ProfileScreen({super.key, required this.api});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();

  // common
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _nic = TextEditingController();

  // guardian 
  final _gName = TextEditingController();
  final _gContact = TextEditingController();
  final _gAddress = TextEditingController();

  // officer fields
  final _department = TextEditingController();
  final _badgeNumber = TextEditingController();
  final _specializations = TextEditingController(); 

  String _role = 'user';
  String? _avatarUrl;
  String? _nicUrl;

  bool _busy = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await widget.api.profileMe();

      _role = (u['role'] ?? 'user').toString();

      _fullName.text = (u['fullName'] ?? '').toString();
      _email.text = (u['email'] ?? '').toString();
      _contact.text = (u['contact'] ?? u['phone'] ?? '').toString();
      _address.text = (u['address'] ?? '').toString();
      _nic.text = (u['nic'] ?? '').toString();

      _avatarUrl = ((u['profileImage'] ?? '') as String).isEmpty
          ? null
          : (u['profileImage'] as String);
      _nicUrl =
          ((u['nicImage'] ?? '') as String).isEmpty ? null : (u['nicImage'] as String);

      final g = (u['guardian'] is Map) ? (u['guardian'] as Map) : {};
      _gName.text = (g['name'] ?? '').toString();
      _gContact.text = (g['contact'] ?? g['phone'] ?? '').toString();
      _gAddress.text = (g['address'] ?? '').toString();

      _department.text = (u['department'] ?? '').toString();
      _badgeNumber.text = (u['badgeNumber'] ?? '').toString();
      _specializations.text = ((u['specializations'] as List?)?.join(', ') ?? '');

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'fullName': _fullName.text.trim(),
        'contact': _contact.text.trim(),
        'address': _address.text.trim(),
        'nic': _nic.text.trim(),
        if (_avatarUrl != null) 'profileImage': _avatarUrl,
        if (_nicUrl != null) 'nicImage': _nicUrl,
        if (_role == 'officer')
          ...{
            'department': _department.text.trim(),
            'badgeNumber': _badgeNumber.text.trim(),
            'specializations': _specializations.text
                .trim(), // backend will split by comma
          }
        else
          'guardian': {
            'name': _gName.text.trim(),
            'contact': _gContact.text.trim(),
            'address': _gAddress.text.trim(),
          },
      };

      await widget.api.profileUpdate(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      _editing = false;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final url = await widget.api.uploadAvatar(File(x.path));
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickNic() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final url = await widget.api.uploadNic(File(x.path));
      setState(() => _nicUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _contact.dispose();
    _address.dispose();
    _nic.dispose();
    _gName.dispose();
    _gContact.dispose();
    _gAddress.dispose();
    _department.dispose();
    _badgeNumber.dispose();
    _specializations.dispose();
    super.dispose();
  }

  Widget _nicPreview() {
    return Row(
      children: [
        Container(
          width: 140,
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: (_nicUrl != null && _nicUrl!.isNotEmpty)
              ? Image.network(_nicUrl!, fit: BoxFit.cover)
              : const Center(child: Text('No NIC')),
        ),
        const SizedBox(width: 8),
        if (_editing)
          TextButton.icon(
            onPressed: _busy ? null : _pickNic,
            icon: const Icon(Icons.upload),
            label: const Text('Upload NIC'),
          ),
      ],
    );
  }

  // --- small helpers for styled sections ---
  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: _editing ? 'Cancel' : 'Edit',
            onPressed: () => setState(() => _editing = !_editing),
            icon: Icon(_editing ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with avatar + quick meta
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundImage: (_avatarUrl != null &&
                                      _avatarUrl!.isNotEmpty)
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 42)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullName.text.isEmpty
                                        ? '—'
                                        : _fullName.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          _role,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            AppTheme.primaryRed.withOpacity(.85),
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _email.text,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_editing)
                              FilledButton.icon(
                                onPressed: _busy ? null : _pickAvatar,
                                icon: const Icon(Icons.photo),
                                label: const Text('Change'),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Contact section
                    _section(title: 'Contact information', children: [
                      AppTextField(
                        controller: _fullName,
                        label: 'Full name',
                        readOnly: !_editing,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _contact,
                        label: 'Contact',
                        readOnly: !_editing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _address,
                        label: 'Address',
                        readOnly: !_editing,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _nic,
                        label: 'NIC',
                        readOnly: !_editing,
                      ),
                    ]),

                    // Role-specific sections
                    if (_role == 'officer')
                      _section(title: 'Officer details', children: [
                        AppTextField(
                          controller: _department,
                          label: 'Department',
                          readOnly: !_editing,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _badgeNumber,
                          label: 'Badge number',
                          readOnly: !_editing,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _specializations,
                          label: 'Specializations (comma-separated)',
                          readOnly: !_editing,
                        ),
                      ])
                    else
                      _section(title: 'Guardian details', children: [
                        AppTextField(
                          controller: _gName,
                          label: 'Guardian name',
                          readOnly: !_editing,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _gContact,
                          label: 'Guardian contact',
                          readOnly: !_editing,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _gAddress,
                          label: 'Guardian address',
                          readOnly: !_editing,
                        ),
                        const SizedBox(height: 12),
                        _nicPreview(),
                      ]),

                    if (_editing) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _save,
                              icon: const Icon(Icons.save_rounded),
                              label: Text(_busy ? 'Saving...' : 'Save changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_busy)
              Container(
                color: Colors.black.withOpacity(.04),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
