// lib/app_routes.dart
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_state.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/legal/terms_screen.dart';
import 'screens/home_page/home_screen.dart';
import 'screens/profile_page/profile_screen.dart';
import 'screens/incident_page/incidents_page.dart';
import 'screens/incident_page/incident_detail_page.dart';

/// route
abstract class AppRoutes {
  static const splash    = '/splash';
  static const login     = '/login';
  static const register  = '/register';
  static const terms     = '/terms';
  static const home      = '/home';
  static const profile   = '/profile';
  static const incidents = '/incidents';
  static const incident  = '/incident'; 
}

void main() => runApp(const SafelinkUserApp());

class SafelinkUserApp extends StatelessWidget {
  const SafelinkUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient('http://10.0.2.2:4000');

    return ValueListenableBuilder<String>(
      valueListenable: AppState.lang,
      builder: (_, __, ___) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash,

          /// Static routes 
          routes: {
            AppRoutes.splash:    (_) => SplashScreen(),
            AppRoutes.login:     (_) => LoginScreen(api: api),
            AppRoutes.register:  (_) => RegisterScreen(api: api),
            AppRoutes.terms:     (_) => const TermsScreen(),
            AppRoutes.home:      (_) => const HomeScreen(),
            AppRoutes.profile:   (_) => ProfileScreen(api: api),
            AppRoutes.incidents: (_) => IncidentsPage(api: api),
          },

          /// Routes
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.incident) {
              final args = (settings.arguments ?? const {}) as Map;
              final ref = (args['ref'] ?? '').toString();
              final focusChat = (args['focusChat'] == true);

              return MaterialPageRoute(
                builder: (_) => IncidentDetailPage(
                  api: api,
                  ref: ref,
                  focusChat: focusChat,
                ),
                settings: settings,
              );
            }
            return null; // fall through to onUnknownRoute
          },

          /// Final safety net for unknown routes.
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Not found')),
              body: Center(
                child: Text(
                  'Route "${settings.name}" was not found.',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
