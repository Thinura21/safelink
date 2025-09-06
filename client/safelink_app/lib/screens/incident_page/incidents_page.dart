import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../assistant_page/assistant_page.dart';
import 'incident_detail_page.dart';

class IncidentsPage extends StatefulWidget {
  final ApiClient api;
  const IncidentsPage({super.key, required this.api});

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final list = await widget.api.listMyIncidents();
      setState(() => _items = list);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'open': return Colors.orange;
      case 'assigned':
      case 'en_route': return Colors.blue;
      case 'arrived': return Colors.indigo;
      case 'resolved': return Colors.green;
      case 'cancelled': return theme.colorScheme.error;
      default: return theme.colorScheme.outline;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medical': return Icons.local_hospital;
      case 'fire': return Icons.local_fire_department;
      case 'crime': return Icons.security;
      case 'accident': return Icons.car_crash;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState.lang.value;
    final t = (String k) => I18n.t(lang, k);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t('incidents.title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_err!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final it    = _items[i];
                      final id    = (it['incidentId'] ?? it['_id'] ?? '').toString();
                      final type  = (it['type'] ?? '').toString();
                      final status= (it['status'] ?? '').toString();
                      final when  = (it['createdAt'] ?? '').toString();

                      final color = _statusColor(status, theme);
                      final icon  = _typeIcon(type);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final ref = id.isEmpty ? (it['_id']?.toString() ?? '') : id;
                          if (ref.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncidentDetailPage(api: widget.api, ref: ref),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1.5,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              id.isEmpty ? t('incidents.unknownId') : id,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: color.withOpacity(0.25)),
                                            ),
                                            child: Text(
                                              status,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: color, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        type.isEmpty ? '-' : type,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        when,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    IconButton(
                                      tooltip: 'Chat',
                                      icon: const Icon(Icons.chat_bubble_outline),
                                     // inside IncidentsPage where the chat IconButton is built
                                      onPressed: () {
                                        final ref = id.isEmpty ? (it['_id']?.toString() ?? '') : id;
                                        if (ref.isEmpty) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AssistantPage(
                                              incidentRef: ref,
                                              patchIncident: (patch) => widget.api.updateIncident(ref, patch),
                                              uploadImages: (files) => widget.api.uploadIncidentImages(ref, files),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
