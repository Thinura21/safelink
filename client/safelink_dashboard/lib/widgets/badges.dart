import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String text;
  const StatusChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Color c = AppTheme.textSecondary;
    switch (text) {
      case 'open':
        c = AppTheme.warningColor;
        break;
      case 'assigned':
      case 'en_route':
      case 'arrived':
        c = AppTheme.successColor;
        break;
      case 'resolved':
        c = AppTheme.textSecondary;
        break;
      case 'cancelled':
        c = AppTheme.errorColor;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const Pill({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(text),
      ]),
    );
  }
}
