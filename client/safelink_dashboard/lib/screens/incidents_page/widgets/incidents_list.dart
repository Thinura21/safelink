import 'package:flutter/material.dart';

class IncidentsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onMap;
  final void Function(Map<String, dynamic>) onImages;
  final void Function(Map<String, dynamic>) onAssign;

  const IncidentsList({
    super.key,
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
    required this.onImages,
    required this.onAssign,
  });

  Color _statusColor(String s, BuildContext ctx) {
    final theme = Theme.of(ctx).colorScheme;
    switch (s) {
      case 'open':
        return theme.tertiary;
      case 'assigned':
      case 'en_route':
        return Colors.green.shade600;
      case 'arrived':
        return Colors.blueGrey;
      case 'resolved':
        return Colors.blueGrey.shade400;
      case 'cancelled':
        return Colors.red.shade400;
      default:
        return theme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = items[i];
        final id = (e['incidentId'] ?? '').toString();
        final desc = (e['description'] ?? '').toString();
        final type = (e['type'] ?? '').toString();
        final pr = (e['priority'] ?? '').toString();
        final st = (e['status'] ?? '').toString();
        final reporter = (e['reporterId'] ?? '').toString();
        final eta = (e['etaMinutes'] == null) ? '-' : '${e['etaMinutes']}m';
        final createdAt = (e['createdAt'] ?? '').toString();
        final hasImages = (e['imagesCount'] ?? 0) > 0;
        final officer = (e['assignedOfficerId'] ?? '-').toString();

        return ListTile(
          dense: false,
          title: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                id,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (desc.isNotEmpty)
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          subtitle: Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(context, type, Colors.blueGrey.shade600),
              _chip(context, pr, Colors.deepOrange),
              _chip(context, st, _statusColor(st, context)),
              Text('reporter: ${reporter.length > 8 ? reporter.substring(0, 8) : reporter}'),
              Text('officer/ETA: $officer / $eta'),
              Text(createdAt.replaceFirst('T', ' ').split('.').first),
            ],
          ),
          trailing: Wrap(
            spacing: 6,
            children: [
              IconButton(
                tooltip: 'View',
                icon: const Icon(Icons.visibility),
                onPressed: () => onView(e),
              ),
              IconButton(
                tooltip: 'Assign officer',
                icon: const Icon(Icons.badge),
                onPressed: () => onAssign(e),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit(e),
              ),
              IconButton(
                tooltip: 'Map',
                icon: const Icon(Icons.place),
                onPressed: () => onMap(e),
              ),
              IconButton(
                tooltip: 'Images',
                icon: Icon(hasImages ? Icons.image : Icons.image_not_supported),
                onPressed: () => onImages(e),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => onDelete(e),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withOpacity(0.08),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    }
}
