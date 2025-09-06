import 'package:flutter/material.dart';
import 'package:safelink_dashboard/core/token_storage.dart';
import 'package:safelink_dashboard/screens/incidents_page/incidents_page.dart';
import 'package:safelink_dashboard/screens/user_page/users_page.dart';
import 'screens/login_page/login_page.dart';
import 'theme/app_theme.dart';
import 'core/api_client.dart';
import 'screens/dashboard/dashboard_shell.dart';
import 'screens/dashboard/dashboard_page.dart';

void main() {
  runApp(const SafelinkDashboardApp());
}

class SafelinkDashboardApp extends StatelessWidget {
  const SafelinkDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient('http://localhost:4000', () => TokenStorage.token);

    return MaterialApp(
      title: 'SafeLink Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (_) => LoginPage(api: api),
        '/dashboard': (_) => DashboardShell(child: DashboardPage(api: api)),
        '/incidents': (_) => DashboardShell(child: IncidentsPage(api: api, lang: 'en',)),
        '/users': (_) => DashboardShell(child: UsersPage(api: api, lang: 'en',)),
      },
      initialRoute: '/',
    );
  }
}
