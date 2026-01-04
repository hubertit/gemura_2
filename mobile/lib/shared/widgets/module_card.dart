import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/module.dart';

class ModuleCard extends StatelessWidget {
  final AppModule module;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: module.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Icon(
              module.icon,
              color: module.color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

