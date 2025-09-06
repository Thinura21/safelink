import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class UsersPage extends StatefulWidget {
  final ApiClient api;
  final String lang;
  const UsersPage({super.key, required this.api, required this.lang});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _items = [];
  int _page = 1;
  int _limit = 20;
  int _total = 0;
  bool _loading = false;
  String? _error;

  final _q = TextEditingController();
  String? _role; // user|officer|authority|admin
  bool? _isVerified;
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.adminListUsers(
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        role: _role,
        isVerified: _isVerified,
        isActive: _isActive,
        page: _page,
        limit: _limit,
      );
      setState(() {
        _items = (data['items'] as List?) ?? [];
        _total = (data['total'] ?? 0) as int;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.code; });
    } catch (_) {
      setState(() { _error = 'NETWORK'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _openCreateUser() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateUserDialog(api: widget.api),
    );
    if (created == true) _refresh();
  }

  void _openEditDialog(Map<String, dynamic> u) {
    final id = (u['_id'] ?? '').toString();
    final emailCtl = TextEditingController(text: (u['email'] ?? '').toString());
    final fullNameCtl = TextEditingController(text: (u['fullName'] ?? '').toString());
    final contactCtl = TextEditingController(text: (u['contact'] ?? '').toString());
    final addressCtl = TextEditingController(text: (u['address'] ?? '').toString());
    final nicCtl = TextEditingController(text: (u['nic'] ?? '').toString());
    final guardianNameCtl = TextEditingController(text: (u['guardian']?['name'] ?? '').toString());
    final guardianPhoneCtl = TextEditingController(text: (u['guardian']?['phone'] ?? '').toString());
    final guardianRelCtl = TextEditingController(text: (u['guardian']?['relation'] ?? '').toString());
    final deptCtl = TextEditingController(text: (u['department'] ?? '').toString());
    final badgeCtl = TextEditingController(text: (u['badgeNumber'] ?? '').toString());
    final specCtl = TextEditingController(text: ((u['specializations'] as List?)?.join(', ') ?? ''));
    final profileUrlCtl = TextEditingController(text: (u['profileImage'] ?? '').toString());
    final nicUrlCtl = TextEditingController(text: (u['nicImage'] ?? '').toString());
    final verifierNoteCtl = TextEditingController(text: (u['verifierNote'] ?? '').toString());
    String role = (u['role'] ?? 'user').toString();
    bool isVerified = (u['isVerified'] == true);
    String nicVerified = (u['nicVerified'] ?? 'pending').toString();
    bool profileComplete = (u['profileComplete'] == true);
    bool isActive = (u['isActive'] != false);
    String password = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email *')),
                TextField(controller: fullNameCtl, decoration: const InputDecoration(labelText: 'Full name *')),
                TextField(controller: contactCtl, decoration: const InputDecoration(labelText: 'Contact')),
                TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address')),
                TextField(controller: nicCtl, decoration: const InputDecoration(labelText: 'NIC')),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Role: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('user')),
                      DropdownMenuItem(value: 'officer', child: Text('officer')),
                      DropdownMenuItem(value: 'authority', child: Text('authority')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                    ],
                    onChanged: (v) => setState(() => role = v ?? role),
                  ),
                ]),
                if (role == 'officer') ...[
                  TextField(controller: deptCtl, decoration: const InputDecoration(labelText: 'Department')),
                  TextField(controller: badgeCtl, decoration: const InputDecoration(labelText: 'Badge number')),
                  TextField(controller: specCtl, decoration: const InputDecoration(labelText: 'Specializations (comma-separated)')),
                ],
                const Divider(),
                const Text('Guardian'),
                TextField(controller: guardianNameCtl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: guardianPhoneCtl, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: guardianRelCtl, decoration: const InputDecoration(labelText: 'Relation')),
                const Divider(),
                const Text('Verification'),
                Row(children: [
                  Checkbox(value: isVerified, onChanged: (v) => setState(() => isVerified = v ?? isVerified)),
                  const Text('isVerified'),
                  const SizedBox(width: 16),
                  const Text('NIC: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: nicVerified,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('pending')),
                      DropdownMenuItem(value: 'verified', child: Text('verified')),
                      DropdownMenuItem(value: 'rejected', child: Text('rejected')),
                    ],
                    onChanged: (v) => setState(() => nicVerified = v ?? nicVerified),
                  ),
                ]),
                TextField(controller: verifierNoteCtl, decoration: const InputDecoration(labelText: 'Verifier note')),
                const Divider(),
                Row(children: [
                  Checkbox(value: profileComplete, onChanged: (v) => setState(() => profileComplete = v ?? profileComplete)),
                  const Text('profileComplete'),
                  const SizedBox(width: 16),
                  Checkbox(value: isActive, onChanged: (v) => setState(() => isActive = v ?? isActive)),
                  const Text('isActive'),
                ]),
                const Divider(),
                TextField(controller: profileUrlCtl, decoration: const InputDecoration(labelText: 'Profile image URL')),
                TextField(controller: nicUrlCtl, decoration: const InputDecoration(labelText: 'NIC image URL')),
                const Divider(),
                TextField(
                  onChanged: (v) => password = v,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final guardian = (guardianNameCtl.text.isNotEmpty || guardianPhoneCtl.text.isNotEmpty || guardianRelCtl.text.isNotEmpty)
                    ? {'name': guardianNameCtl.text.trim(), 'phone': guardianPhoneCtl.text.trim(), 'relation': guardianRelCtl.text.trim()}
                    : null;

                final payload = {
                  'email': emailCtl.text.trim(),
                  'fullName': fullNameCtl.text.trim(),
                  'contact': contactCtl.text.trim(),
                  'address': addressCtl.text.trim(),
                  'nic': nicCtl.text.trim(),
                  'role': role,
                  'department': role == 'officer' ? deptCtl.text.trim() : null,
                  'badgeNumber': role == 'officer' ? badgeCtl.text.trim() : null,
                  'specializations': role == 'officer' ? specCtl.text.trim() : null,
                  'guardian': guardian,
                  'isVerified': isVerified,
                  'nicVerified': nicVerified,
                  'verifierNote': verifierNoteCtl.text.trim(),
                  'profileComplete': profileComplete,
                  'isActive': isActive,
                  'profileImage': profileUrlCtl.text.trim().isEmpty ? null : profileUrlCtl.text.trim(),
                  'nicImage': nicUrlCtl.text.trim().isEmpty ? null : nicUrlCtl.text.trim(),
                  if (password.trim().isNotEmpty) 'password': password.trim(),
                };
                await widget.api.adminUpdateUser(id, payload);
                if (!mounted) return;
                Navigator.pop(context);
                await _refresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
              } on ApiException catch (e) {
                Navigator.pop(context);
                setState(() { _error = e.code; });
              } catch (_) {
                Navigator.pop(context);
                setState(() { _error = 'NETWORK'; });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This will soft-delete the user.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.adminDeleteUser(id);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    } on ApiException catch (e) {
      setState(() { _error = e.code; });
    } catch (_) {
      setState(() { _error = 'NETWORK'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Centered content and consistent paddings to avoid overlap
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FiltersBar(
                    q: _q,
                    role: _role,
                    isVerified: _isVerified,
                    isActive: _isActive,
                    onRoleChanged: (v) => setState(() => _role = v),
                    onVerifiedChanged: (v) => setState(() => _isVerified = v),
                    onActiveChanged: (v) => setState(() => _isActive = v),
                    onApply: () { _page = 1; _refresh(); },
                    loading: _loading,
                    onNew: _openCreateUser,
                    onRefresh: _refresh,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : (_items.isEmpty
                              ? const Center(child: Text('No users'))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemBuilder: (_, i) {
                                    final u = _items[i] as Map<String, dynamic>;
                                    final id = (u['_id'] ?? '').toString();
                                    final role = (u['role'] ?? '').toString();
                                    final name = (u['fullName'] ?? '').toString();
                                    final email = (u['email'] ?? '').toString();
                                    final verified = (u['isVerified'] == true);
                                    final nicV = (u['nicVerified'] ?? 'pending').toString();
                                    final active = (u['isActive'] != false);

                                    return ListTile(
                                      title: Text('$name  <$email>'),
                                      subtitle: Wrap(
                                        spacing: 12,
                                        children: [
                                          Text('role: $role'),
                                          Text('verified: $verified ($nicV)'),
                                          Text(active ? 'active' : 'inactive'),
                                        ],
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _openEditDialog(u),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                                            onPressed: () => _deleteUser(id),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemCount: _items.length,
                                )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Total: $_total   Page: $_page'),
                      IconButton(
                        onPressed: _page > 1
                            ? () { setState(() => _page -= 1); _refresh(); }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: (_page * _limit) < _total
                            ? () { setState(() => _page += 1); _refresh(); }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Top filters + actions row (kept compact and centered)
class _FiltersBar extends StatelessWidget {
  final TextEditingController q;
  final String? role;
  final bool? isVerified;
  final bool? isActive;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<bool?> onVerifiedChanged;
  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onApply;
  final VoidCallback onNew;
  final VoidCallback onRefresh;
  final bool loading;

  const _FiltersBar({
    required this.q,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.onRoleChanged,
    required this.onVerifiedChanged,
    required this.onActiveChanged,
    required this.onApply,
    required this.onNew,
    required this.onRefresh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: loading ? null : onNew,
          icon: const Icon(Icons.group_add),
          label: const Text('New user'),
        ),
        SizedBox(
          width: 360,
          child: TextField(
            controller: q,
            decoration: const InputDecoration(
              labelText: 'Search (email/name/phone/...)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        DropdownButton<String?>(
          value: role,
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
          value: isVerified,
          hint: const Text('Verified?'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Any')),
            DropdownMenuItem(value: true, child: Text('Verified')),
            DropdownMenuItem(value: false, child: Text('Not verified')),
          ],
          onChanged: onVerifiedChanged,
        ),
        DropdownButton<bool?>(
          value: isActive,
          hint: const Text('Active?'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Any')),
            DropdownMenuItem(value: true, child: Text('Active')),
            DropdownMenuItem(value: false, child: Text('Inactive')),
          ],
          onChanged: onActiveChanged,
        ),
        ElevatedButton(onPressed: loading ? null : onApply, child: const Text('Apply')),
        IconButton(
          tooltip: 'Refresh',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

/// Create User modal dialog (same payload as your working page)
class _CreateUserDialog extends StatefulWidget {
  final ApiClient api;
  const _CreateUserDialog({required this.api});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
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
  String _nicVerifiedCreate = 'pending'; // pending|verified|rejected
  bool _profileCompleteCreate = false;
  bool _isActiveCreate = true;
  bool _submitting = false;

  Future<void> _create() async {
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
      Navigator.pop(context, true);
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
        ElevatedButton(onPressed: _submitting ? null : _create, child: const Text('Create')),
      ],
    );
  }
}
