import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../widgets/osm_map_dialog.dart';
import 'widgets/incidents_list.dart';
import 'widgets/create_incident_dialog.dart';

class IncidentsPage extends StatefulWidget {
  final ApiClient api;
  final String lang;
  const IncidentsPage({super.key, required this.api, required this.lang});

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  final _q = TextEditingController();
  String _statusFilter = 'open,assigned,en_route,arrived,resolved,cancelled';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  //helpers
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.adminListIncidents(
        q: _q.text.trim(),
        statuses: _statusFilter,
        limit: 300,
      );
      setState(() {
        _items = list.cast<Map<String, dynamic>>();
        _error = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _error = 'NETWORK: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateIncidentDialog(api: widget.api),
    );
    if (created == true) _refresh();
  }

  // -------- Actions (unchanged backend calls) --------

  Future<List<Map<String, dynamic>>> _searchUsers(String q) async {
    try {
      final resp = await widget.api.adminListUsers(
        q: q.isEmpty ? null : q,
        role: null,
        isActive: true,
        page: 1,
        limit: 10,
      );
      final items = (resp['items'] as List?) ?? [];
      return items.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchOfficers(String q) async {
    try {
      return await widget.api.adminGetOfficers(q: q);
    } catch (_) {
      return [];
    }
  }

  Future<void> _openAssign(Map<String, dynamic> row) async {
    final ref = (row['incidentId'] ?? row['_id']).toString();
    Map<String, dynamic>? selectedOfficer;
    int? eta;
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Assign officer — $ref'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (value) async => await _searchOfficers(value.text),
                displayStringForOption: (o) => '${o['fullName'] ?? ''} <${o['email'] ?? ''}>',
                onSelected: (o) => selectedOfficer = o,
                fieldViewBuilder: (context, ctl, focus, _) => TextField(
                  controller: ctl,
                  focusNode: focus,
                  decoration: const InputDecoration(labelText: 'Officer (type to search)'),
                ),
                optionsViewBuilder: (context, onSelected, options) => Material(
                  elevation: 4,
                  child: SizedBox(
                    height: 220,
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
              TextField(controller: noteCtl, decoration: const InputDecoration(labelText: 'Assignment note')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedOfficer == null) return;
              try {
                await widget.api.adminAssignOfficer(
                  ref: ref,
                  officerId: selectedOfficer!['_id'],
                  etaMinutes: eta,
                  note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                await _refresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned')));
              } on ApiException catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${e.code}')));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _openEdit(Map<String, dynamic> row) async {
    final ref = (row['incidentId'] ?? row['_id']).toString();
    Map<String, dynamic> full = row;
    try {
      full = await widget.api.adminGetIncident(ref);
    } catch (_) {}

    // hydrate
    final descCtl = TextEditingController(text: (full['description'] ?? '').toString());
    final locTextCtl = TextEditingController(text: (full['locationText'] ?? '').toString());
    String type = (full['type'] ?? 'other').toString();
    String prio = (full['priority'] ?? 'normal').toString();
    String status = (full['status'] ?? 'open').toString();
    int? eta = (full['etaMinutes'] is int) ? full['etaMinutes'] as int : null;
    final assignmentNoteCtl = TextEditingController(text: (full['assignmentNote'] ?? '').toString());
    int? casualties = (full['casualties'] is int) ? full['casualties'] as int : null;
    bool? bystander = full['bystander'] is bool ? full['bystander'] as bool : null;
    Map<String, dynamic>? reporter = full['reporterId'] is Map<String, dynamic> ? Map<String, dynamic>.from(full['reporterId']) : null;
    Map<String, dynamic>? officer = full['assignedOfficerId'] is Map<String, dynamic> ? Map<String, dynamic>.from(full['assignedOfficerId']) : null;

    final coords = ((full['location']?['coordinates'] ?? []) as List?)?.cast<num>() ?? [];
    LatLng? picked = (coords.length >= 2) ? LatLng(coords[1].toDouble(), coords[0].toDouble()) : null;

    List<XFile> newImages = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit ${full['incidentId'] ?? ''}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (v) async => await _searchUsers(v.text),
                    displayStringForOption: (u) => '${u['fullName'] ?? ''} <${u['email'] ?? ''}>',
                    onSelected: (u) => setLocal(() => reporter = u),
                    fieldViewBuilder: (c, ctl, focus, _) => TextField(
                      controller: ctl..text = reporter == null ? '' : '${reporter!['fullName']} <${reporter!['email']}>',
                      focusNode: focus,
                      decoration: const InputDecoration(labelText: 'Reporter (type to search)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (v) async => await _searchOfficers(v.text),
                    displayStringForOption: (o) => '${o['fullName'] ?? ''} <${o['email'] ?? ''}>',
                    onSelected: (o) => setLocal(() => officer = o),
                    fieldViewBuilder: (c, ctl, focus, _) => TextField(
                      controller: ctl..text = officer == null ? '' : '${officer!['fullName']} <${officer!['email']}>',
                      focusNode: focus,
                      decoration: const InputDecoration(labelText: 'Assigned officer (optional)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(value: 'medical', child: Text('medical')),
                          DropdownMenuItem(value: 'fire', child: Text('fire')),
                          DropdownMenuItem(value: 'crime', child: Text('crime')),
                          DropdownMenuItem(value: 'accident', child: Text('accident')),
                          DropdownMenuItem(value: 'other', child: Text('other')),
                        ],
                        onChanged: (v) => setLocal(() => type = v ?? type),
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: prio,
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('low')),
                          DropdownMenuItem(value: 'normal', child: Text('normal')),
                          DropdownMenuItem(value: 'high', child: Text('high')),
                          DropdownMenuItem(value: 'critical', child: Text('critical')),
                        ],
                        onChanged: (v) => setLocal(() => prio = v ?? prio),
                        decoration: const InputDecoration(labelText: 'Priority'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('open')),
                      DropdownMenuItem(value: 'assigned', child: Text('assigned')),
                      DropdownMenuItem(value: 'en_route', child: Text('en_route')),
                      DropdownMenuItem(value: 'arrived', child: Text('arrived')),
                      DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                      DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                    ],
                    onChanged: (v) => setLocal(() => status = v ?? status),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: locTextCtl, decoration: const InputDecoration(labelText: 'Location text')),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ETA minutes'),
                        onChanged: (v) => eta = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: assignmentNoteCtl, decoration: const InputDecoration(labelText: 'Assignment note'))),
                  ]),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Casualties (optional)'),
                        onChanged: (v) => casualties = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: bystander == null ? 'null' : (bystander! ? 'true' : 'false'),
                        items: const [
                          DropdownMenuItem(value: 'null', child: Text('Bystander: unknown')),
                          DropdownMenuItem(value: 'true', child: Text('Bystander: yes')),
                          DropdownMenuItem(value: 'false', child: Text('Bystander: no')),
                        ],
                        onChanged: (v) {
                          setLocal(() {
                            if (v == 'true') bystander = true;
                            else if (v == 'false') bystander = false;
                            else bystander = null;
                          });
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.place),
                    label: const Text('Change location on map'),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => OsmMapDialog(
                          initial: picked,
                          onConfirm: (pos, addr) {
                            setLocal(() {
                              picked = pos;
                              if (locTextCtl.text.trim().isEmpty && (addr ?? '').isNotEmpty) {
                                locTextCtl.text = addr!;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                  if (picked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Coords: ${picked!.latitude.toStringAsFixed(6)}, ${picked!.longitude.toStringAsFixed(6)}'),
                    ),
                  const Divider(),
                  const Text('Add more images'),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Pick files'),
                    onPressed: () async {
                      final imgs = await _picker.pickMultiImage(imageQuality: 85);
                      if (imgs.isNotEmpty) setLocal(() => newImages = imgs);
                    },
                  ),
                  if (newImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: newImages
                          .map((x) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(x.path), width: 120, height: 90, fit: BoxFit.cover),
                              ))
                          .toList(),
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
                  final payload = {
                    'type': type,
                    'priority': prio,
                    'status': status,
                    'description': descCtl.text.trim(),
                    'locationText': locTextCtl.text.trim(),
                    'assignmentNote': assignmentNoteCtl.text.trim(),
                    'etaMinutes': eta,
                    'casualties': casualties,
                    'bystander': bystander,
                    'reporterId': reporter?['_id'],
                    'assignedOfficerId': officer?['_id'],
                    if (picked != null) 'lat': picked!.latitude,
                    if (picked != null) 'lng': picked!.longitude,
                  };
                  final updated = await widget.api.adminPatchIncident(ref, payload);

                  if (newImages.isNotEmpty && !kIsWeb) {
                    final files = newImages.map((x) => File(x.path)).toList();
                    await widget.api.adminUploadIncidentImages(updated['incidentId'] ?? ref, files);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  await _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated ${updated['incidentId']}')));
                } on ApiException catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${e.code} ${e.message}')));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ref = (row['incidentId'] ?? row['_id']).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete incident?'),
        content: const Text('This will permanently delete the incident.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.adminDeleteIncident(ref);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${e.code} ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openView(Map<String, dynamic> row) async {
    final ref = (row['incidentId'] ?? row['_id']).toString();
    Map<String, dynamic> full = row;
    try {
      full = await widget.api.adminGetIncident(ref);
    } catch (_) {}
    final imgs = (full['images'] as List?)?.cast<String>() ?? [];
    final coords = ((full['location']?['coordinates'] ?? []) as List?)?.cast<num>() ?? [];
    final lat = coords.length >= 2 ? coords[1].toDouble() : null;
    final lng = coords.length >= 2 ? coords[0].toDouble() : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(full['incidentId'] ?? 'Incident'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${full['type']} | Priority: ${full['priority']} | Status: ${full['status']}'),
                const SizedBox(height: 4),
                Text('Reporter: ${full['reporterId']?['fullName'] ?? ''} <${full['reporterId']?['email'] ?? ''}>'),
                const SizedBox(height: 4),
                if (full['assignedOfficerId'] != null)
                  Text(
                      'Officer: ${full['assignedOfficerId']?['fullName'] ?? ''} '
                      '(${full['assignedOfficerId']?['department'] ?? ''})'
                      '${(full['assignmentNote'] ?? '').toString().isNotEmpty ? ' — ${full['assignmentNote']}' : ''}'),
                if (full['etaMinutes'] != null) Text('ETA: ${full['etaMinutes']} minutes'),
                const SizedBox(height: 8),
                if ((full['casualties'] ?? null) != null) Text('Casualties: ${full['casualties']}'),
                if (full['bystander'] != null) Text('Bystander: ${full['bystander'] == true ? 'yes' : 'no'}'),
                const SizedBox(height: 8),
                if ((full['description'] ?? '').toString().isNotEmpty) Text(full['description']),
                const SizedBox(height: 8),
                Text('Location: ${full['locationText'] ?? ''}'),
                if (lat != null && lng != null) Text('Coords: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
                const SizedBox(height: 8),
                if (imgs.isNotEmpty) const Text('Images:'),
                if (imgs.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: imgs
                        .map((u) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(widget.api.fileUrl(u), width: 140, height: 100, fit: BoxFit.cover),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _openMapInfo(Map<String, dynamic> row) {
    final coords = ((row['location']?['coordinates'] ?? []) as List?)?.cast<num>() ?? [];
    final lat = coords.length >= 2 ? coords[1].toDouble() : null;
    final lng = coords.length >= 2 ? coords[0].toDouble() : null;
    final addr = (row['locationText'] ?? '').toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(row['incidentId'] ?? 'Location'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address:\n$addr'),
              const SizedBox(height: 8),
              if (lat != null && lng != null) Text('Coords: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _openImages(Map<String, dynamic> row) async {
    final ref = (row['incidentId'] ?? row['_id']).toString();
    Map<String, dynamic> full = row;
    try {
      full = await widget.api.adminGetIncident(ref);
    } catch (_) {}
    final imgs = (full['images'] as List?)?.cast<String>() ?? [];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${full['incidentId'] ?? ''} — images'),
        content: SizedBox(
          width: 680,
          child: imgs.isEmpty
              ? const Text('No images')
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: imgs
                        .map((u) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(widget.api.fileUrl(u), width: 180, height: 130, fit: BoxFit.cover),
                            ))
                        .toList(),
                  ),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _IncidentsFiltersBar(
                q: _q,
                statusValue: _statusFilter,
                onStatusChanged: (v) => setState(() => _statusFilter = v ?? _statusFilter),
                onApply: _refresh,
                onNew: _openCreateDialog,
                onRefresh: _refresh,
                loading: _loading,
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
                          ? const Center(child: Text('No incidents'))
                          : IncidentsList(
                              items: _items,
                              onView: _openView,
                              onEdit: _openEdit,
                              onDelete: _delete,
                              onMap: _openMapInfo,
                              onImages: _openImages,
                              onAssign: _openAssign,
                            )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentsFiltersBar extends StatelessWidget {
  final TextEditingController q;
  final String statusValue;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onNew;
  final VoidCallback onRefresh;
  final bool loading;

  const _IncidentsFiltersBar({
    required this.q,
    required this.statusValue,
    required this.onStatusChanged,
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
          icon: const Icon(Icons.add),
          label: const Text('New incident'),
        ),
        SizedBox(
          width: 420,
          child: TextField(
            controller: q,
            decoration: const InputDecoration(
              labelText: 'Search (id/description/location/type/priority)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        DropdownButton<String>(
          value: statusValue,
          items: const [
            DropdownMenuItem(
              value: 'open,assigned,en_route',
              child: Text('Active only'),
            ),
            DropdownMenuItem(
              value: 'open,assigned,en_route,arrived,resolved,cancelled',
              child: Text('All statuses'),
            ),
          ],
          onChanged: onStatusChanged,
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
