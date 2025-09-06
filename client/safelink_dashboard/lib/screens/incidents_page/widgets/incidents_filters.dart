import 'package:flutter/material.dart';

class IncidentsFilters extends StatelessWidget {
  final TextEditingController qController;
  final String statusValue;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;
  final bool loading;

  const IncidentsFilters({
    super.key,
    required this.qController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.onApply,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: qController,
            decoration: const InputDecoration(
              labelText: 'Search (id/description/location/type/priority)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        DropdownButton<String>(
          value: statusValue,
          items: const [
            DropdownMenuItem(value: 'open,assigned,en_route', child: Text('Active only')),
            DropdownMenuItem(
              value: 'open,assigned,en_route,arrived,resolved,cancelled',
              child: Text('All statuses'),
            ),
          ],
          onChanged: onStatusChanged,
        ),
        ElevatedButton(onPressed: loading ? null : onApply, child: const Text('Apply')),
      ],
    );
  }
}
