import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isPositive;

  const StatusBadge({
    super.key,
    required this.label,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
