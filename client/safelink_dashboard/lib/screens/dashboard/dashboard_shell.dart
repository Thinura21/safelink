import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/token_storage.dart';
import '../../theme/app_theme.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  Map<String, dynamic>? _jwtUser;

  @override
  void initState() {
    super.initState();
    _loadProfileFromJwt();
  }

  Future<String?> _readTokenCompat() async {
    try { return await (TokenStorage as dynamic).readToken(); } catch (_) {}
    try { return await (TokenStorage as dynamic).read(); } catch (_) {}
    try { return await (TokenStorage as dynamic).getToken(); } catch (_) {}
    return null;
  }

  Future<void> _loadProfileFromJwt() async {
    try {
      final token = await _readTokenCompat();
      if (token == null || token.isEmpty) return;
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final user = (map['user'] ?? map['userInfo'] ?? map['data'] ?? {}) as Map?;
      if (mounted) setState(() => _jwtUser = user?.cast<String, dynamic>());
    } catch (_) {}
  }

  void _openProfileDialog() {
    final name = (_jwtUser?['fullName'] ?? 'Signed in').toString();
    final email = (_jwtUser?['email'] ?? '').toString();
    final role = (_jwtUser?['role'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profile'),
        content: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppTheme.primaryRed),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text([email, if (role.isNotEmpty) 'role: $role'].join(' • ')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await TokenStorage.clear();
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            currentRoute: currentRoute,
            onGo: (route) => Navigator.pushReplacementNamed(context, route),
            onLogout: () async {
              await TokenStorage.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(onProfile: _openProfileDialog),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onProfile;
  const _TopBar({required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0.5,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.account_circle, color: AppTheme.textPrimary),
                onPressed: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onGo;
  final Future<void> Function() onLogout;

  const _Sidebar({
    required this.currentRoute,
    required this.onGo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // narrower
      color: AppTheme.primaryRed,
      child: Column(
        children: [
          // Logo only
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Icon(Icons.shield, color: Colors.white, size: 32),
          ),
          _NavTile(
            icon: Icons.dashboard, label: 'Dashboard',
            selected: currentRoute == '/dashboard',
            onTap: () => onGo('/dashboard'),
          ),
          _NavTile(
            icon: Icons.warning, label: 'Incidents',
            selected: currentRoute == '/incidents',
            onTap: () => onGo('/incidents'),
          ),
          _NavTile(
            icon: Icons.people, label: 'Users',
            selected: currentRoute == '/users',
            onTap: () => onGo('/users'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () => onLogout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryRed,
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.15),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
