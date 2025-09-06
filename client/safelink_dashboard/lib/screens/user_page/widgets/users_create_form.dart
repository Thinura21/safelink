import 'package:flutter/material.dart';

class UsersCreateForm extends StatelessWidget {
  final TextEditingController emailCtl;
  final TextEditingController fullNameCtl;
  final TextEditingController passwordCtl;
  final TextEditingController contactCtl;
  final TextEditingController addressCtl;
  final TextEditingController nicCtl;

  final String roleValue;
  final ValueChanged<String> onRoleChanged;

  final TextEditingController deptCtl;
  final TextEditingController badgeCtl;
  final TextEditingController specCtl;

  final TextEditingController guardianNameCtl;
  final TextEditingController guardianPhoneCtl;
  final TextEditingController guardianRelCtl;

  final bool verifiedValue;
  final ValueChanged<bool> onVerifiedChanged;

  final String nicVerifiedValue;
  final ValueChanged<String> onNicVerifiedChanged;

  final TextEditingController verifierNoteCtl;

  final bool profileCompleteValue;
  final ValueChanged<bool> onProfileCompleteChanged;

  final bool activeValue;
  final ValueChanged<bool> onActiveChanged;

  final TextEditingController profileUrlCtl;
  final TextEditingController nicUrlCtl;

  final bool loading;
  final VoidCallback onCreate;

  const UsersCreateForm({
    super.key,
    required this.emailCtl,
    required this.fullNameCtl,
    required this.passwordCtl,
    required this.contactCtl,
    required this.addressCtl,
    required this.nicCtl,
    required this.roleValue,
    required this.onRoleChanged,
    required this.deptCtl,
    required this.badgeCtl,
    required this.specCtl,
    required this.guardianNameCtl,
    required this.guardianPhoneCtl,
    required this.guardianRelCtl,
    required this.verifiedValue,
    required this.onVerifiedChanged,
    required this.nicVerifiedValue,
    required this.onNicVerifiedChanged,
    required this.verifierNoteCtl,
    required this.profileCompleteValue,
    required this.onProfileCompleteChanged,
    required this.activeValue,
    required this.onActiveChanged,
    required this.profileUrlCtl,
    required this.nicUrlCtl,
    required this.loading,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(width: 240, child: TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email *'))),
        SizedBox(width: 240, child: TextField(controller: fullNameCtl, decoration: const InputDecoration(labelText: 'Full name *'))),
        SizedBox(width: 180, child: TextField(controller: passwordCtl, obscureText: true, decoration: const InputDecoration(labelText: 'Password (optional)'))),
        SizedBox(width: 160, child: TextField(controller: contactCtl, decoration: const InputDecoration(labelText: 'Contact'))),
        SizedBox(width: 240, child: TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address'))),
        SizedBox(width: 160, child: TextField(controller: nicCtl, decoration: const InputDecoration(labelText: 'NIC'))),

        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Role: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: roleValue,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('user')),
              DropdownMenuItem(value: 'officer', child: Text('officer')),
              DropdownMenuItem(value: 'authority', child: Text('authority')),
              DropdownMenuItem(value: 'admin', child: Text('admin')),
            ],
            onChanged: (v) => onRoleChanged(v ?? 'user'),
          ),
        ]),
        if (roleValue == 'officer') ...[
          SizedBox(width: 200, child: TextField(controller: deptCtl, decoration: const InputDecoration(labelText: 'Department'))),
          SizedBox(width: 200, child: TextField(controller: badgeCtl, decoration: const InputDecoration(labelText: 'Badge number'))),
          SizedBox(width: 320, child: TextField(controller: specCtl, decoration: const InputDecoration(labelText: 'Specializations (comma-separated)'))),
        ],

        const Divider(),
        const Text('Guardian'),
        SizedBox(width: 220, child: TextField(controller: guardianNameCtl, decoration: const InputDecoration(labelText: 'Name'))),
        SizedBox(width: 180, child: TextField(controller: guardianPhoneCtl, decoration: const InputDecoration(labelText: 'Phone'))),
        SizedBox(width: 200, child: TextField(controller: guardianRelCtl, decoration: const InputDecoration(labelText: 'Relation'))),

        const Divider(),
        const Text('Verification'),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(value: verifiedValue, onChanged: (v) => onVerifiedChanged(v ?? verifiedValue)),
          const Text('isVerified'),
          const SizedBox(width: 16),
          const Text('NIC: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: nicVerifiedValue,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('pending')),
              DropdownMenuItem(value: 'verified', child: Text('verified')),
              DropdownMenuItem(value: 'rejected', child: Text('rejected')),
            ],
            onChanged: (v) => onNicVerifiedChanged(v ?? 'pending'),
          ),
        ]),
        SizedBox(width: 320, child: TextField(controller: verifierNoteCtl, decoration: const InputDecoration(labelText: 'Verifier note'))),

        Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(value: profileCompleteValue, onChanged: (v) => onProfileCompleteChanged(v ?? profileCompleteValue)),
          const Text('profileComplete'),
          const SizedBox(width: 16),
          Checkbox(value: activeValue, onChanged: (v) => onActiveChanged(v ?? activeValue)),
          const Text('isActive'),
        ]),

        SizedBox(width: 320, child: TextField(controller: profileUrlCtl, decoration: const InputDecoration(labelText: 'Profile image URL (optional)'))),
        SizedBox(width: 320, child: TextField(controller: nicUrlCtl, decoration: const InputDecoration(labelText: 'NIC image URL (optional)'))),

        ElevatedButton(onPressed: loading ? null : onCreate, child: const Text('Create')),
      ],
    );
  }
}
