import 'package:flutter/material.dart';

class UsersFilters extends StatelessWidget {
  final TextEditingController qController;
  final String? roleValue;
  final bool? verifiedValue;
  final bool? activeValue;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<bool?> onVerifiedChanged;
  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onApply;
  final bool loading;

  const UsersFilters({
    super.key,
    required this.qController,
    required this.roleValue,
    required this.verifiedValue,
    required this.activeValue,
    required this.onRoleChanged,
    required this.onVerifiedChanged,
    required this.onActiveChanged,
    required this.onApply,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: qController,
            decoration: const InputDecoration(
              labelText: 'Search (email/name/phone/...)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        DropdownButton<String?>(
          value: roleValue,
          hint: const Text('Any role'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Any role')),
            DropdownMenuItem(value: 'user', child: Text('user')),
            DropdownMenuItem(value: 'officer', child: Text('officer')),
            DropdownMenuItem(value: 'authority', child: Text('authority')),
            DropdownMenuItem(value: 'admin', child: Text('admin')),
          ],
          onChanged: onRoleChanged,
        ),
        DropdownButton<bool?>(
          value: verifiedValue,
          hint: const Text('Verified?'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Any')),
            DropdownMenuItem(value: true, child: Text('Verified')),
            DropdownMenuItem(value: false, child: Text('Not verified')),
          ],
          onChanged: onVerifiedChanged,
        ),
        DropdownButton<bool?>(
          value: activeValue,
          hint: const Text('Active?'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Any')),
            DropdownMenuItem(value: true, child: Text('Active')),
            DropdownMenuItem(value: false, child: Text('Inactive')),
          ],
          onChanged: onActiveChanged,
        ),
        ElevatedButton(onPressed: loading ? null : onApply, child: const Text('Apply')),
      ],
    );
  }
}
