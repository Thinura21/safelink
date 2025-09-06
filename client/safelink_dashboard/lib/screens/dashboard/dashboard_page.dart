import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  final ApiClient api;
  const DashboardPage({super.key, required this.api});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _recentIncidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final incidents = await widget.api.adminListIncidents(
        statuses: 'open,assigned,en_route', // active
        limit: 20,
      );
      setState(() => _recentIncidents = incidents);
    } on ApiException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Quick assign bottom sheet ----------
  Future<void> _quickAssign(Map<String, dynamic> incident) async {
    Map<String, dynamic>? selected;
    int? eta;
    final noteCtl = TextEditingController();

    Future<List<Map<String, dynamic>>> searchOfficers(String q) async {
      try {
        return await widget.api.adminGetOfficers(q: q);
      } catch (_) {
        return [];
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Assign officer — ${incident['incidentId'] ?? ''}',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (value) async => await searchOfficers(value.text),
              displayStringForOption: (o) => '${o['fullName'] ?? ''} <${o['email'] ?? ''}>',
              onSelected: (o) => selected = o,
              fieldViewBuilder: (c, ctl, focus, _) => TextField(
                controller: ctl,
                focusNode: focus,
                decoration: const InputDecoration(
                  labelText: 'Officer (type to search)',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              optionsViewBuilder: (context, onSelected, options) => Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final o = options.elementAt(i);
                      return ListTile(
                        title: Text('${o['fullName'] ?? ''}  <${o['email'] ?? ''}>'),
                        subtitle: Text('${o['department'] ?? ''} ${o['badgeNumber'] ?? ''}'),
                        onTap: () => onSelected(o),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ETA minutes'),
              onChanged: (v) => eta = int.tryParse(v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtl,
              decoration: const InputDecoration(labelText: 'Assignment note'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selected == null) return;
                      try {
                        await widget.api.adminAssignOfficer(
                          ref: (incident['incidentId'] ?? incident['_id']).toString(),
                          officerId: selected!['_id'],
                          etaMinutes: eta,
                          note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadData();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Officer assigned')));
                      } on ApiException catch (e) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('API error: ${e.code}')));
                      }
                    },
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: AppTheme.errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Solid, centered canvas like the Users page
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 16),
              _statsRow(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _mapCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _recentCard()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Real-time emergency response overview',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    final active = _recentIncidents.where((i) => i['status'] != 'resolved').length;
    final open = _recentIncidents.where((i) => i['status'] == 'open').length;
    final assigned = _recentIncidents.where((i) => i['status'] == 'assigned').length;

    return Row(
      children: [
        Expanded(child: _statCard('Active', '$active', Icons.warning, AppTheme.errorColor)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Open', '$open', Icons.radio_button_unchecked, AppTheme.warningColor)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Assigned', '$assigned', Icons.assignment_ind, AppTheme.successColor)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Response Time', '12m avg', Icons.timer, AppTheme.primaryRed)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Icon(icon, color: color, size: 20),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _mapCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Live Incident Map',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(6.9271, 79.8612),
                initialZoom: 10,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safelink_dashboard',
                ),
                MarkerLayer(markers: _markers()),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  List<Marker> _markers() {
    return _recentIncidents
        .where((i) => ((i['location']?['coordinates'] ?? []) as List).length >= 2)
        .map((i) {
      final coords = (i['location']['coordinates'] as List).cast<num>();
      final lat = coords[1].toDouble();
      final lng = coords[0].toDouble();
      final status = (i['status'] ?? '').toString();

      Color c = AppTheme.primaryRed;
      if (status == 'open') c = AppTheme.warningColor;
      if (status == 'assigned' || status == 'en_route') c = AppTheme.successColor;

      return Marker(
        point: LatLng(lat, lng),
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.warning, color: Colors.white, size: 16),
        ),
      );
    }).toList();
  }

  Widget _recentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recent Incidents',
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/incidents'), child: const Text('View all')),
          ]),
          const SizedBox(height: 8),
          if (_recentIncidents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No recent incidents')),
            )
          else
            ..._recentIncidents.take(8).map(_recentTile),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      side: BorderSide(color: color.withOpacity(0.3)),
      backgroundColor: color.withOpacity(0.08),
      labelStyle: TextStyle(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _recentTile(Map<String, dynamic> i) {
    final type = (i['type'] ?? '').toString();
    final status = (i['status'] ?? '').toString();
    final description = (i['description'] ?? '').toString();
    final id = (i['incidentId'] ?? '').toString();

    Color statusColor = AppTheme.textSecondary;
    if (status == 'open') statusColor = AppTheme.warningColor;
    if (status == 'assigned' || status == 'en_route') statusColor = AppTheme.successColor;

    IconData typeIcon = Icons.info;
    if (type == 'medical') typeIcon = Icons.local_hospital;
    if (type == 'fire') typeIcon = Icons.local_fire_department;
    if (type == 'crime') typeIcon = Icons.security;
    if (type == 'accident') typeIcon = Icons.car_crash;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(typeIcon, color: statusColor),
      ),
      title: Text(description.isEmpty ? 'Incident $id' : description,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        spacing: 8,
        children: [
          _chip(type, Colors.blueGrey),
          _chip(status, statusColor),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Quick assign',
        icon: const Icon(Icons.chevron_right),
        onPressed: () => _quickAssign(i),
      ),
      onTap: () => _quickAssign(i),
    );
  }
}
