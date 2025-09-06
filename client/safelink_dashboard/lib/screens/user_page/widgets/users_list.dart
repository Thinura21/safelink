import 'package:flutter/material.dart';
import '../../../widgets/badges.dart';

class UsersList extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String id) onDelete;

  const UsersList({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No users'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final u = items[i] as Map<String, dynamic>;
        final id = (u['_id'] ?? '').toString();
        final role = (u['role'] ?? '').toString();
        final name = (u['fullName'] ?? '').toString();
        final email = (u['email'] ?? '').toString();
        final verified = (u['isVerified'] == true);
        final nicV = (u['nicVerified'] ?? 'pending').toString();
        final active = (u['isActive'] != false);

        return Card(
          child: ListTile(
            title: Text('$name  <$email>'),
            subtitle: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Pill(icon: Icons.manage_accounts, text: 'role: $role'),
                Pill(icon: Icons.verified, text: 'verified: $verified ($nicV)'),
                Pill(icon: active ? Icons.check_circle : Icons.cancel, text: active ? 'active' : 'inactive'),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: () => onEdit(u), child: const Text('Edit')),
                OutlinedButton(
                  onPressed: () => onDelete(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
