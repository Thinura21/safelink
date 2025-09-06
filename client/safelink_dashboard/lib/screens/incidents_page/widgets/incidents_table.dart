import 'package:flutter/material.dart';
import '../../../widgets/badges.dart';

class IncidentsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onMap;
  final void Function(Map<String, dynamic>) onImages;
  final void Function(Map<String, dynamic>) onAssign;

  const IncidentsTable({
    super.key,
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
    required this.onImages,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Incident')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('ReporterId')),
          DataColumn(label: Text('Officer/ETA')),
          DataColumn(label: Text('When')),
          DataColumn(label: Text('Actions')),
        ],
        rows: items.map((e) {
          final id = (e['incidentId'] ?? '').toString();
          final type = (e['type'] ?? '').toString();
          final pr = (e['priority'] ?? '').toString();
          final st = (e['status'] ?? '').toString();
          final reporter = (e['reporterId'] ?? '').toString();
          final eta = (e['etaMinutes'] == null) ? '-' : '${e['etaMinutes']}m';
          final createdAt = (e['createdAt'] ?? '').toString();
          final hasImages = (e['imagesCount'] ?? 0) > 0;

          return DataRow(cells: [
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text((e['description'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            DataCell(Text(type)),
            DataCell(Text(pr)),
            DataCell(StatusChip(st)),
            DataCell(Text(reporter.length > 8 ? reporter.substring(0, 8) : reporter)),
            DataCell(Text('${e['assignedOfficerId'] ?? '-'} / $eta')),
            DataCell(Text(createdAt.replaceFirst('T', ' ').split('.').first)),
            DataCell(Wrap(
              spacing: 4,
              children: [
                IconButton(tooltip: 'View', icon: const Icon(Icons.visibility), onPressed: () => onView(e)),
                IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit), onPressed: () => onEdit(e)),
                IconButton(tooltip: 'Assign officer', icon: const Icon(Icons.badge), onPressed: () => onAssign(e)),
                IconButton(tooltip: 'Map', icon: const Icon(Icons.place), onPressed: () => onMap(e)),
                IconButton(
                  tooltip: 'Images',
                  icon: Icon(hasImages ? Icons.image : Icons.image_not_supported),
                  onPressed: () => onImages(e),
                ),
                IconButton(
                  tooltip: 'Delete',
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => onDelete(e),
                  icon: const Icon(Icons.delete_forever),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
