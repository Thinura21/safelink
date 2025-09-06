import 'package:flutter/material.dart';
import '../../../core/api_client.dart';

class CreateUserDialog extends StatefulWidget {
  final ApiClient api;
  const CreateUserDialog({super.key, required this.api});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _nic = TextEditingController();

  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianRelation = TextEditingController();

  final _department = TextEditingController();
  final _badgeNumber = TextEditingController();
  final _specializations = TextEditingController();

  final _verifierNote = TextEditingController();
  final _profileImageUrl = TextEditingController();
  final _nicImageUrl = TextEditingController();

  String _roleCreate = 'user';
  bool _isVerifiedCreate = false;
  String _nicVerifiedCreate = 'pending';
  bool _profileCompleteCreate = false;
  bool _isActiveCreate = true;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final guardian = (_guardianName.text.isNotEmpty ||
              _guardianPhone.text.isNotEmpty ||
              _guardianRelation.text.isNotEmpty)
          ? {
              'name': _guardianName.text.trim(),
              'phone': _guardianPhone.text.trim(),
              'relation': _guardianRelation.text.trim(),
            }
          : null;

      final body = {
        'email': _email.text.trim(),
        'password': _password.text.trim().isEmpty ? null : _password.text,
        'fullName': _fullName.text.trim(),
        'contact': _contact.text.trim(),
        'address': _address.text.trim(),
        'nic': _nic.text.trim(),
        'guardian': guardian,
        'role': _roleCreate,
        'department': _roleCreate == 'officer' ? _department.text.trim() : null,
        'badgeNumber': _roleCreate == 'officer' ? _badgeNumber.text.trim() : null,
        'specializations': _roleCreate == 'officer' ? _specializations.text.trim() : null,
        'isVerified': _isVerifiedCreate,
        'nicVerified': _nicVerifiedCreate,
        'verifierNote': _verifierNote.text.trim(),
        'profileComplete': _profileCompleteCreate,
        'isActive': _isActiveCreate,
        'profileImage': _profileImageUrl.text.trim().isEmpty ? null : _profileImageUrl.text.trim(),
        'nicImage': _nicImageUrl.text.trim().isEmpty ? null : _nicImageUrl.text.trim(),
      };

      await widget.api.adminCreateUser(body);

      if (!mounted) return;
      Navigator.pop(context, true); // success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created')));
    } on ApiException catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${e.code}')));
    } catch (_) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NETWORK')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create user'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 760,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(width: 260, child: TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email *'))),
              SizedBox(width: 240, child: TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full name *'))),
              SizedBox(width: 180, child: TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (optional)'))),
              SizedBox(width: 160, child: TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact'))),
              SizedBox(width: 260, child: TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address'))),
              SizedBox(width: 160, child: TextField(controller: _nic, decoration: const InputDecoration(labelText: 'NIC'))),

              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Role: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _roleCreate,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('user')),
                    DropdownMenuItem(value: 'officer', child: Text('officer')),
                    DropdownMenuItem(value: 'authority', child: Text('authority')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                  ],
                  onChanged: (v) => setState(() => _roleCreate = v ?? 'user'),
                ),
              ]),
              if (_roleCreate == 'officer') ...[
                SizedBox(width: 200, child: TextField(controller: _department, decoration: const InputDecoration(labelText: 'Department'))),
                SizedBox(width: 200, child: TextField(controller: _badgeNumber, decoration: const InputDecoration(labelText: 'Badge number'))),
                SizedBox(width: 320, child: TextField(controller: _specializations, decoration: const InputDecoration(labelText: 'Specializations (comma-separated)'))),
              ],

              const Divider(),
              const Text('Guardian'),
              SizedBox(width: 220, child: TextField(controller: _guardianName, decoration: const InputDecoration(labelText: 'Name'))),
              SizedBox(width: 180, child: TextField(controller: _guardianPhone, decoration: const InputDecoration(labelText: 'Phone'))),
              SizedBox(width: 200, child: TextField(controller: _guardianRelation, decoration: const InputDecoration(labelText: 'Relation'))),

              const Divider(),
              const Text('Verification'),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(value: _isVerifiedCreate, onChanged: (v) => setState(() => _isVerifiedCreate = v ?? false)),
                const Text('isVerified'),
                const SizedBox(width: 16),
                const Text('NIC: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _nicVerifiedCreate,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('pending')),
                    DropdownMenuItem(value: 'verified', child: Text('verified')),
                    DropdownMenuItem(value: 'rejected', child: Text('rejected')),
                  ],
                  onChanged: (v) => setState(() => _nicVerifiedCreate = v ?? 'pending'),
                ),
              ]),
              SizedBox(width: 320, child: TextField(controller: _verifierNote, decoration: const InputDecoration(labelText: 'Verifier note'))),

              Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(value: _profileCompleteCreate, onChanged: (v) => setState(() => _profileCompleteCreate = v ?? false)),
                const Text('profileComplete'),
                const SizedBox(width: 16),
                Checkbox(value: _isActiveCreate, onChanged: (v) => setState(() => _isActiveCreate = v ?? true)),
                const Text('isActive'),
              ]),

              SizedBox(width: 320, child: TextField(controller: _profileImageUrl, decoration: const InputDecoration(labelText: 'Profile image URL (optional)'))),
              SizedBox(width: 320, child: TextField(controller: _nicImageUrl, decoration: const InputDecoration(labelText: 'NIC image URL (optional)'))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submitting ? null : _submit, child: const Text('Create')),
      ],
    );
  }
}
