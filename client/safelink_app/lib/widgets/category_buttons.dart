import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryButtons extends StatelessWidget {
  final void Function(String type) onSend;

  const CategoryButtons({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    // card-like chip
    Widget chip(String label, IconData icon, String type) {
      return InkWell(
        onTap: () => onSend(type),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip('medical', Icons.local_hospital, 'medical'),
        chip('fire', Icons.local_fire_department, 'fire'),
        chip('crime', Icons.security, 'crime'),
        chip('accident', Icons.car_crash, 'accident'),
      ],
    );
  }
}
