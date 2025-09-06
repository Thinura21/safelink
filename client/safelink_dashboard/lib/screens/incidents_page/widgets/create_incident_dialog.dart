import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_client.dart';
import '../../../widgets/osm_map_dialog.dart';
import '../../../widgets/local_thumb.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CreateIncidentDialog extends StatefulWidget {
  final ApiClient api;
  const CreateIncidentDialog({super.key, required this.api});

  @override
  State<CreateIncidentDialog> createState() => _CreateIncidentDialogState();
}

class _CreateIncidentDialogState extends State<CreateIncidentDialog> {
  // form fields
  final _desc = TextEditingController();
  final _locationText = TextEditingController();
  String _type = 'other';
  String _priority = 'normal';
  String _status = 'open';
  Map<String, dynamic>? _reporter;
  int? _casualties;
  bool? _bystander;

  // map + images
  LatLng? _picked;
  String _pickedAddress = '';
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];

  bool _submitting = false;

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

  Future<void> _pickLocation() async {
    await showDialog(
      context: context,
      builder: (_) => OsmMapDialog(
        initial: _picked,
        onConfirm: (pos, addr) {
          setState(() {
            _picked = pos;
            _pickedAddress = addr ?? '';
            if (_locationText.text.trim().isEmpty && _pickedAddress.isNotEmpty) {
              _locationText.text = _pickedAddress;
            }
          });
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 85);
    if (imgs.isNotEmpty) setState(() => _pickedImages.addAll(imgs));
  }

  Future<void> _submit() async {
    if (_reporter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a reporter')));
      return;
    }
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a location on map')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = {
        'reporterId': _reporter!['_id'],
        'type': _type,
        'priority': _priority,
        'status': _status,
        'description': _desc.text.trim(),
        'locationText': _locationText.text.trim().isEmpty ? _pickedAddress : _locationText.text.trim(),
        'lat': _picked!.latitude,
        'lng': _picked!.longitude,
        'casualties': _casualties,
        'bystander': _bystander,
      };
      final inc = await widget.api.adminCreateIncidentEmergency(body);

      if (_pickedImages.isNotEmpty && !kIsWeb) {
        final files = _pickedImages.map((x) => File(x.path)).toList();
        if (files.isNotEmpty) {
          await widget.api.adminUploadIncidentImages(inc['incidentId'] ?? inc['_id'], files);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true); // signal success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident created')));
    } on ApiException catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${e.code} ${e.message}')));
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create incident'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 820,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TypeAheadField<Map<String, dynamic>>(
                  suggestionsCallback: _searchUsers,
                  builder: (context, ctl, focus) => TextField(
                    controller: ctl,
                    focusNode: focus,
                    decoration: const InputDecoration(labelText: 'Reporter (type to search users)'),
                  ),
                  itemBuilder: (_, u) => ListTile(
                    title: Text('${u['fullName'] ?? ''}  <${u['email'] ?? ''}>'),
                    subtitle: Text(u['contact']?.toString() ?? ''),
                  ),
                  onSelected: (u) => setState(() => _reporter = u),
                  emptyBuilder: (_) => const SizedBox(height: 48, child: Center(child: Text('No users'))),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'medical', child: Text('medical')),
                    DropdownMenuItem(value: 'fire', child: Text('fire')),
                    DropdownMenuItem(value: 'crime', child: Text('crime')),
                    DropdownMenuItem(value: 'accident', child: Text('accident')),
                    DropdownMenuItem(value: 'other', child: Text('other')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'other'),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('low')),
                    DropdownMenuItem(value: 'normal', child: Text('normal')),
                    DropdownMenuItem(value: 'high', child: Text('high')),
                    DropdownMenuItem(value: 'critical', child: Text('critical')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('open')),
                    DropdownMenuItem(value: 'assigned', child: Text('assigned')),
                    DropdownMenuItem(value: 'en_route', child: Text('en_route')),
                    DropdownMenuItem(value: 'arrived', child: Text('arrived')),
                    DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                    DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'open'),
                ),
              ),
              SizedBox(width: 420, child: TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description'))),
              SizedBox(width: 320, child: TextField(controller: _locationText, decoration: const InputDecoration(labelText: 'Location text (optional)'))),

              SizedBox(
                width: 180,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Casualties (optional)'),
                  onChanged: (v) => setState(() => _casualties = int.tryParse(v)),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: _bystander == null ? 'null' : (_bystander! ? 'true' : 'false'),
                  items: const [
                    DropdownMenuItem(value: 'null', child: Text('Bystander: unknown')),
                    DropdownMenuItem(value: 'true', child: Text('Bystander: yes')),
                    DropdownMenuItem(value: 'false', child: Text('Bystander: no')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      if (v == 'true') _bystander = true;
                      else if (v == 'false') _bystander = false;
                      else _bystander = null;
                    });
                  },
                ),
              ),

              OutlinedButton.icon(icon: const Icon(Icons.map), label: const Text('Pick location on map'), onPressed: _pickLocation),
              if (_picked != null) Text('Picked: ${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}'),
              if (_pickedAddress.isNotEmpty) Text(_pickedAddress),

              OutlinedButton.icon(icon: const Icon(Icons.image), label: const Text('Add images'), onPressed: _pickImages),
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  width: 600,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pickedImages
                        .map((x) => LocalThumb(
                              x: x,
                              onRemove: () => setState(() => _pickedImages.remove(x)),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submitting ? null : _submit, child: const Text('Create')),
      ],
    );
  }
}
