import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        // No border
      ),
      child: Text(
        status,
        style: AppTheme.badge.copyWith(color: color),
      ),
    );
  }
} 