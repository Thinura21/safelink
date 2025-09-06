import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small reusable brand mark used on splash/auth screens.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.security, size: 40, color: AppTheme.primaryRed),
      ),
    );
  }
}
