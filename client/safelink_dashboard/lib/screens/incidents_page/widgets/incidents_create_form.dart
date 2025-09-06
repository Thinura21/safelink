import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_client.dart';
import '../../../widgets/local_thumb.dart';
import '../../../widgets/osm_map_dialog.dart';

class IncidentsCreateForm extends StatelessWidget {
  final ApiClient api;
  final bool loading;

  // bindable state (owned by parent)
  final Map<String, dynamic>? reporter;
  final ValueChanged<Map<String, dynamic>?> onReporter;
  final String type;
  final ValueChanged<String> onType;
  final String priority;
  final ValueChanged<String> onPriority;
  final String status;
  final ValueChanged<String> onStatus;
  final TextEditingController descCtl;
  final TextEditingController locationCtl;
  final int? casualties;
  final ValueChanged<int?> onCasualties;
  final bool? bystander;
  final ValueChanged<bool?> onBystander;
  final LatLng? picked;
  final String pickedAddress;
  final VoidCallback onPickLocation;
  final List<XFile> images;
  final VoidCallback onPickImages;
  final void Function(XFile x) onRemoveImage;
  final Future<void> Function() onCreate;

  const IncidentsCreateForm({
    super.key,
    required this.api,
    required this.loading,
    required this.reporter,
    required this.onReporter,
    required this.type,
    required this.onType,
    required this.priority,
    required this.onPriority,
    required this.status,
    required this.onStatus,
    required this.descCtl,
    required this.locationCtl,
    required this.casualties,
    required this.onCasualties,
    required this.bystander,
    required this.onBystander,
    required this.picked,
    required this.pickedAddress,
    required this.onPickLocation,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onCreate,
  });

  Future<List<Map<String, dynamic>>> _searchUsers(String q) async {
    try {
      final resp = await api.adminListUsers(q: q.isEmpty ? null : q, role: null, isActive: true, page: 1, limit: 10);
      final items = (resp['items'] as List?) ?? [];
      return items.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
            onSelected: onReporter,
            emptyBuilder: (_) => const SizedBox(height: 48, child: Center(child: Text('No users'))),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'medical', child: Text('medical')),
              DropdownMenuItem(value: 'fire', child: Text('fire')),
              DropdownMenuItem(value: 'crime', child: Text('crime')),
              DropdownMenuItem(value: 'accident', child: Text('accident')),
              DropdownMenuItem(value: 'other', child: Text('other')),
            ],
            onChanged: (v) => onType(v ?? 'other'),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('low')),
              DropdownMenuItem(value: 'normal', child: Text('normal')),
              DropdownMenuItem(value: 'high', child: Text('high')),
              DropdownMenuItem(value: 'critical', child: Text('critical')),
            ],
            onChanged: (v) => onPriority(v ?? 'normal'),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('open')),
              DropdownMenuItem(value: 'assigned', child: Text('assigned')),
              DropdownMenuItem(value: 'en_route', child: Text('en_route')),
              DropdownMenuItem(value: 'arrived', child: Text('arrived')),
              DropdownMenuItem(value: 'resolved', child: Text('resolved')),
              DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
            ],
            onChanged: (v) => onStatus(v ?? 'open'),
          ),
        ),
        SizedBox(width: 420, child: TextField(controller: descCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description'))),
        SizedBox(width: 320, child: TextField(controller: locationCtl, decoration: const InputDecoration(labelText: 'Location text (optional)'))),
        SizedBox(
          width: 180,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Casualties (optional)'),
            onChanged: (v) => onCasualties(int.tryParse(v)),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: bystander == null ? 'null' : (bystander! ? 'true' : 'false'),
            items: const [
              DropdownMenuItem(value: 'null', child: Text('Bystander: unknown')),
              DropdownMenuItem(value: 'true', child: Text('Bystander: yes')),
              DropdownMenuItem(value: 'false', child: Text('Bystander: no')),
            ],
            onChanged: (v) {
              if (v == 'true') onBystander(true);
              else if (v == 'false') onBystander(false);
              else onBystander(null);
            },
          ),
        ),
        OutlinedButton.icon(icon: const Icon(Icons.map), label: const Text('Pick location on map'), onPressed: onPickLocation),
        if (picked != null) Text('Picked: ${picked!.latitude.toStringAsFixed(6)}, ${picked!.longitude.toStringAsFixed(6)}'),
        if (pickedAddress.isNotEmpty) Text(pickedAddress),
        OutlinedButton.icon(icon: const Icon(Icons.image), label: const Text('Add images'), onPressed: onPickImages),
        if (images.isNotEmpty)
          SizedBox(
            width: 600,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images
                  .map((x) => LocalThumb(
                        x: x,
                        onRemove: () => onRemoveImage(x),
                      ))
                  .toList(),
            ),
          ),
        ElevatedButton(onPressed: loading ? null : onCreate, child: const Text('Create')),
      ],
    );
  }
}
