// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/auth_storage.dart';
import '../../widgets/panic_button.dart';
import '../../widgets/category_buttons.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _map = MapController();
  final ApiClient _api = ApiClient('http://10.0.2.2:4000');

  Position? _pos;
  String _address = 'Locating…';
  bool _busy = false;

  String? _activeIncidentId;
  String? _assignedOfficerName;
  int? _etaMinutes;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startPollingAssignment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _address = 'Location services disabled');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _address = 'Location permission denied');
        return;
      }

      final p = await Geolocator.getCurrentPosition();
      await _updateAddress(p);
      _map.move(LatLng(p.latitude, p.longitude), 15);
    } catch (e) {
      setState(() => _address = 'Location error: $e');
    }
  }

  Future<void> _updateAddress(Position p) async {
    String pretty =
        'Lat ${p.latitude.toStringAsFixed(5)}, Lng ${p.longitude.toStringAsFixed(5)}';
    try {
      final list = await geo.placemarkFromCoordinates(p.latitude, p.longitude);
      if (list.isNotEmpty) {
        final m = list.first;
        final parts = <String>[
          if ((m.subLocality ?? '').isNotEmpty) m.subLocality!,
          if ((m.locality ?? '').isNotEmpty) m.locality!,
          if ((m.administrativeArea ?? '').isNotEmpty) m.administrativeArea!,
          if ((m.country ?? '').isNotEmpty) m.country!,
        ];
        if (parts.isNotEmpty) pretty = parts.join(', ');
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _pos = p;
      _address = pretty;
    });
  }

  Future<void> _sendPanic() async {
    if (_pos == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location not ready')));
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _api.sendEmergencyAlert(
        type: 'crime',
        description: 'Panic button',
        lat: _pos!.latitude,
        lng: _pos!.longitude,
      );
      _activeIncidentId = (r['incidentId'] ?? r['_id'] ?? '').toString().isEmpty
          ? null
          : (r['incidentId'] ?? r['_id']).toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alert sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quick(String type) async {
    if (_pos == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location not ready')));
      return;
    }
    try {
      final r = await _api.sendEmergencyAlert(
        type: type,
        description: 'Quick $type report',
        lat: _pos!.latitude,
        lng: _pos!.longitude,
      );
      _activeIncidentId = (r['incidentId'] ?? r['_id'] ?? '').toString().isEmpty
          ? null
          : (r['incidentId'] ?? r['_id']).toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$type reported')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _startPollingAssignment() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        final a = await _api.getMyActiveIncident();
        if (a == null) {
          if (mounted) {
            setState(() {
              _activeIncidentId = null;
              _assignedOfficerName = null;
              _etaMinutes = null;
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _activeIncidentId =
                (a['incident']?['incidentId'] ?? a['incident']?['_id'] ?? '').toString();
            final off = (a['assignedOfficerName'] ??
                    a['incident']?['assignedOfficerName'] ??
                    a['incident']?['officerName'] ??
                    '')
                .toString();
            _assignedOfficerName = off.isEmpty ? null : off;
            _etaMinutes = (a['etaMinutes'] is num) ? (a['etaMinutes'] as num).toInt() : null;
          });
        }
      } catch (_) {}
    });
  }

  void _toggleLang() => AppState.toggleLang();

  Future<void> _logout() async {
    _pollTimer?.cancel();
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.lang,
      builder: (_, lang, __) {
        final t = (String k) => I18n.t(lang, k);

        final sriLanka = const LatLng(7.8731, 80.7718);
        final me = _pos == null ? sriLanka : LatLng(_pos!.latitude, _pos!.longitude);

        // Top app “card” with logo title + actions
        Widget _topBar() {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // small shield icon box
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security, color: AppTheme.primaryRed, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  t('app.title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _toggleLang,
                  child: Text(
                    t('lang.toggle'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'My Location',
                  onPressed: _initLocation,
                  icon: const Icon(Icons.my_location),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                IconButton(
                  tooltip: t('home.logout'),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          );
        }

        // Location pill + officer/eta banner
        Widget _infoBar() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 140,
                      ),
                      child: Text(
                        _address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if ((_assignedOfficerName ?? '').isNotEmpty || _etaMinutes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successColor.withOpacity(.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user, color: AppTheme.successColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        [
                          if ((_assignedOfficerName ?? '').isNotEmpty)
                            '${t('incident.officer')}: $_assignedOfficerName',
                          if (_etaMinutes != null) '${t('incident.eta')}: $_etaMinutes min',
                        ].join('   •   '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }

        // Bottom control card
        Widget _controlPanel() {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.07),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                PanicButton(onPressed: _busy ? null : _sendPanic),
                const SizedBox(height: 14),
                CategoryButtons(onSend: _quick),
                if (_activeIncidentId != null && _activeIncidentId!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Ref: $_activeIncidentId',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // MAP
              Positioned.fill(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: me,
                    initialZoom: _pos == null ? 6 : 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.safelink.app',
                    ),
                    if (_pos != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: me,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.my_location,
                              color: AppTheme.primaryRed,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // FOREGROUND UI
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _topBar(),
                      _infoBar(),
                      const Spacer(),
                      _controlPanel(),
                    ],
                  ),
                ),
              ),

              // My incidents shortcut
              Positioned(
                bottom: 22,
                right: 22,
                child: FloatingActionButton(
                  onPressed: () => Navigator.pushNamed(context, '/incidents'),
                  backgroundColor: AppTheme.primaryRed,
                  child: const Icon(Icons.receipt_long, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
