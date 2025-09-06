import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PanicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const PanicButton({
    super.key,
    this.onPressed,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = [
      BoxShadow(
        color: AppTheme.primaryRed.withOpacity(0.35),
        blurRadius: 28,
        spreadRadius: 4,
        offset: const Offset(0, 10),
      ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
        child: Material(
          color: AppTheme.primaryRed,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_rounded, size: 42, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    'EMERGENCY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                  ),
                  Text(
                    'PRESS HERE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(.9),
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
