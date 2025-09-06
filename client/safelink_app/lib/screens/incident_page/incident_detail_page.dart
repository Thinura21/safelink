import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../../core/api_client.dart';
import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../widgets/simple_guided_bot.dart'; 

class IncidentDetailPage extends StatefulWidget {
  final ApiClient api;
  final String ref;         
  final bool focusChat;     
  const IncidentDetailPage({
    super.key,
    required this.api,
    required this.ref,
    this.focusChat = false,
  });

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _inc;
  String? _err;

  bool _busyUpload = false;
  final _scrollC = ScrollController();

  String? _autoAddress; // derived address when locationText is blank

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _safeRef([Map<String, dynamic>? m]) {
    final id  = (m?['incidentId'] ?? '').toString();
    if (id.isNotEmpty) return id;
    final oid = (m?['_id'] ?? '').toString();
    if (oid.isNotEmpty) return oid;
    return (widget.ref).toString();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final refToFetch = _safeRef();
      if (refToFetch.isEmpty) {
        setState(() { _err = 'Missing incident reference'; _loading = false; });
        return;
      }

      final d = await widget.api.getIncident(refToFetch);

      // reverse-geocode if needed
      _autoAddress = null;
      final coords = (d['location'] as Map?)?['coordinates'] as List?;
      if ((d['locationText'] ?? '').toString().isEmpty &&
          coords != null && coords.length >= 2 &&
          coords[0] is num && coords[1] is num) {
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        try {
          final list = await geo.placemarkFromCoordinates(lat, lng);
          if (list.isNotEmpty) {
            final m = list.first;
            final parts = <String>[
              if ((m.subLocality ?? '').isNotEmpty) m.subLocality!,
              if ((m.locality ?? '').isNotEmpty) m.locality!,
              if ((m.administrativeArea ?? '').isNotEmpty) m.administrativeArea!,
              if ((m.country ?? '').isNotEmpty) m.country!,
            ];
            if (parts.isNotEmpty) _autoAddress = parts.join(', ');
          }
        } catch (_) {}
      }

      setState(() => _inc = d);

      if (widget.focusChat) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted && _scrollC.hasClients) {
          _scrollC.animateTo(
            _scrollC.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadImages() async {
    final picker = ImagePicker();
    final picks = await picker.pickMultiImage(imageQuality: 85);
    if (picks.isEmpty) return;
    setState(() => _busyUpload = true);
    try {
      final files = picks.map((x) => File(x.path)).toList();
      await widget.api.uploadIncidentImages(_safeRef(_inc), files);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busyUpload = false);
    }
  }

  Future<void> _changeType() async {
    final lang = AppState.lang.value;
    final t = (String k) => I18n.t(lang, k);
    const types = ['medical', 'fire', 'crime', 'accident', 'other'];

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(t('incident.type'))),
            const Divider(height: 1),
            for (final tp in types)
              ListTile(title: Text(tp), onTap: () => Navigator.pop(context, tp)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || selected.isEmpty) return;

    try {
      final updated = await widget.api.updateIncident(_safeRef(_inc), {'type': selected});
      setState(() => _inc = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState.lang.value;
    final t = (String k) => I18n.t(lang, k);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('incident.title')),
        actions: [
          IconButton(
            tooltip: t('incident.type'),
            onPressed: (_inc == null) ? null : _changeType,
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busyUpload ? null : _uploadImages,
        child: _busyUpload
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 36),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(_err!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _inc == null || _safeRef(_inc).isEmpty
                  ? Center(child: Text(t('incident.notFound')))
                  : SingleChildScrollView(
                      controller: _scrollC,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_inc!['incidentId'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          _row(t('incident.type'), (_inc!['type'] ?? '').toString()),
                          _row(t('incident.status'), (_inc!['status'] ?? '').toString()),
                          _row(t('incident.priority'), (_inc!['priority'] ?? '').toString()),
                          _row(t('incident.description'), (_inc!['description'] ?? '').toString()),
                          _row(
                            t('incident.locationText'),
                            (() {
                              final lt = (_inc!['locationText'] ?? '').toString();
                              if (lt.isNotEmpty) return lt;
                              return _autoAddress ?? '-';
                            })(),
                          ),
                          _row(
                            t('incident.casualties'),
                            _inc!['casualties'] == null ? '-' : _inc!['casualties'].toString(),
                          ),
                          _row(
                            t('incident.bystander'),
                            _inc!['bystander'] == null
                                ? '-'
                                : (_inc!['bystander'] == true ? t('common.yes') : t('common.no')),
                          ),
                          _row(
                            t('incident.eta'),
                            _inc!['etaMinutes'] == null ? '-' : '${_inc!['etaMinutes']} min',
                          ),
                          _row(
                            t('incident.officer'),
                            (_inc!['assignedOfficerName'] ?? _inc!['officerName'] ?? '').toString(),
                          ),
                          const SizedBox(height: 12),
                          Text(t('incident.images'),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (_) {
                              final imgs = (_inc!['images'] as List? ?? []).cast<dynamic>();
                              if (imgs.isEmpty) return const Text('-');
                              return Wrap(
                                spacing: 8, runSpacing: 8,
                                children: imgs.map<Widget>((e) {
                                  final url = e.toString();
                                  return Container(
                                    width: 100, height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(url, fit: BoxFit.cover),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          /// NEW: Simple guided bot (replaces old IncidentChatBot)
                          SimpleGuidedBot(
                            incidentRef: _safeRef(_inc),
                            patchIncident: (patch) async {
                              final updated =
                                  await widget.api.updateIncident(_safeRef(_inc), patch);
                              setState(() => _inc = updated);
                            },
                            uploadImages: (files) async {
                              await widget.api.uploadIncidentImages(_safeRef(_inc), files);
                              await _load();
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
