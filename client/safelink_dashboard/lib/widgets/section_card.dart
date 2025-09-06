import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionCard({
    super.key,
    this.title,
    this.actions,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final titleRow = (title != null || (actions?.isNotEmpty ?? false))
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (title != null)
                  Text(title!, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          )
        : const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleRow, child],
        ),
      ),
    );
  }
}
