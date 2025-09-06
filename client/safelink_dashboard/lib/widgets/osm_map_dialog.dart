import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_geocoder.dart';

class OsmMapDialog extends StatefulWidget {
  final LatLng? initial;
  final void Function(LatLng pos, String? address) onConfirm;
  const OsmMapDialog({super.key, required this.initial, required this.onConfirm});

  @override
  State<OsmMapDialog> createState() => _OsmMapDialogState();
}

class _OsmMapDialogState extends State<OsmMapDialog> {
  final _searchCtl = TextEditingController();
  final _mapCtrl = MapController();
  List<OsmSuggestion> _results = [];
  late LatLng _center;
  LatLng? _marker;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? const LatLng(6.9271, 79.8612);
    _marker = widget.initial;
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = p;
        _marker = p;
      });
      _mapCtrl.move(p, 16);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _search(String q) async {
    final res = await OsmGeocoder.query(q);
    if (!mounted) return;
    setState(() => _results = res);
  }

  Future<void> _choose(OsmSuggestion s) async {
    final p = LatLng(s.lat, s.lon);
    setState(() {
      _center = p;
      _marker = p;
      _searchCtl.text = s.display;
      _results = [];
    });
    _mapCtrl.move(p, 16);
  }

  Future<void> _confirm() async {
    if (_marker == null) return;
    var addr = _searchCtl.text.trim();
    addr = addr.isEmpty ? await OsmGeocoder.reverse(_marker!.latitude, _marker!.longitude) : addr;
    widget.onConfirm(_marker!, addr.isEmpty ? null : addr);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick location'),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtl,
                    onChanged: _search,
                    decoration: const InputDecoration(hintText: 'Search a place', prefixIcon: Icon(Icons.search)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('My location'),
                ),
              ],
            ),
            if (_results.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(_results[i].display),
                    onTap: () => _choose(_results[i]),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14,
                  onTap: (_, latLng) => setState(() => _marker = latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safelink_dashboard',
                  ),
                  if (_marker != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _marker!,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.location_on, size: 36, color: Colors.red),
                      )
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(_marker == null
                ? 'Tap on map to drop a pin'
                : 'Selected: ${_marker!.latitude.toStringAsFixed(6)}, ${_marker!.longitude.toStringAsFixed(6)}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _marker == null
              ? null
              : () {
                  _confirm();
                  Navigator.pop(context);
                },
          child: const Text('Use this location'),
        ),
      ],
    );
  }
}
